const express = require('express');
const jwt = require('jsonwebtoken');
const { OAuth2Client } = require('google-auth-library');
const { PrismaClient } = require('@prisma/client');
const { authenticate: authMiddleware } = require('../middlewares/auth');
const { authenticate: portalAuthenticate } = require('../utils/portalAuth');
const { sendOtpEmail } = require('../utils/emailService');

const router = express.Router();
const prisma = new PrismaClient();
const googleClient = new OAuth2Client(process.env.GOOGLE_CLIENT_ID);

// In-memory OTP store: studentId → { otp, name, expiresAt }
const otpStore = new Map();

function signTokens(payload) {
  const accessToken = jwt.sign(payload, process.env.JWT_SECRET, {
    expiresIn: process.env.JWT_EXPIRES_IN || '2h',
  });
  const refreshToken = jwt.sign(payload, process.env.JWT_REFRESH_SECRET, {
    expiresIn: process.env.JWT_REFRESH_EXPIRES_IN || '30d',
  });
  return { accessToken, refreshToken };
}

// POST /auth/google
router.post('/google', async (req, res, next) => {
  try {
    const { idToken } = req.body;
    if (!idToken) {
      return res.status(400).json({ code: 'MISSING_TOKEN', message: 'idToken이 필요합니다.' });
    }

    const ticket = await googleClient.verifyIdToken({
      idToken,
      audience: process.env.GOOGLE_CLIENT_ID,
    });
    const payload = ticket.getPayload();

    if (payload.hd !== 'dankook.ac.kr') {
      return res.status(403).json({
        code: 'NOT_DANKOOK_ACCOUNT',
        message: '단국대학교(@dankook.ac.kr) 계정으로만 로그인할 수 있습니다.',
      });
    }

    const googleSub = payload.sub;
    const email = payload.email;
    const name = payload.name;
    const studentId = email.split('@')[0];

    const user = await prisma.user.upsert({
      where: { googleSub },
      update: { name },
      create: { studentId, name, email, googleSub },
    });

    const tokenPayload = {
      userId: user.id,
      studentId: user.studentId,
      name: user.name,
      isAdmin: user.isAdmin,
    };
    const tokens = signTokens(tokenPayload);

    res.json({ ...tokens, user: { id: user.id, studentId: user.studentId, name: user.name } });
  } catch (err) {
    if (err.message?.includes('Token used too late') || err.message?.includes('Invalid token')) {
      return res.status(401).json({ code: 'INVALID_TOKEN', message: '유효하지 않은 Google 토큰입니다.' });
    }
    next(err);
  }
});

// POST /auth/login — 단국 포털 학번/비밀번호 로그인
router.post('/login', async (req, res, next) => {
  try {
    const { studentId, password } = req.body;
    if (!studentId || !password) {
      return res.status(400).json({ code: 'MISSING_FIELDS', message: '학번과 비밀번호를 입력해주세요.' });
    }

    const portalUser = await portalAuthenticate(studentId, password);

    const email = `${studentId}@dankook.ac.kr`;
    const user = await prisma.user.upsert({
      where: { studentId },
      update: { name: portalUser.name },
      create: { studentId, name: portalUser.name, email },
    });

    const tokenPayload = {
      userId: user.id,
      studentId: user.studentId,
      name: user.name,
      isAdmin: user.isAdmin,
    };
    const tokens = signTokens(tokenPayload);

    res.json({ ...tokens, user: { id: user.id, studentId: user.studentId, name: user.name } });
  } catch (err) {
    if (err.code === 'INVALID_CREDENTIALS') {
      return res.status(401).json(err);
    }
    if (err.code === 'NOT_ENROLLED') {
      return res.status(403).json(err);
    }
    if (err.code === 'INVALID_FORMAT') {
      return res.status(400).json(err);
    }
    next(err);
  }
});

// POST /auth/register/send-otp — 회원가입 인증번호 전송
router.post('/register/send-otp', async (req, res, next) => {
  try {
    const { name, studentId, password } = req.body;
    if (!name || !studentId || !password) {
      return res.status(400).json({ code: 'MISSING_FIELDS', message: '이름, 학번, 비밀번호를 모두 입력해주세요.' });
    }

    // 포털 인증으로 재학생 여부 및 비밀번호 확인
    await portalAuthenticate(studentId, password);

    // 이미 가입된 계정 확인
    const existing = await prisma.user.findUnique({ where: { studentId } });
    if (existing) {
      return res.status(409).json({ code: 'ALREADY_EXISTS', message: '이미 가입된 계정입니다. 로그인해 주세요.' });
    }

    // 6자리 OTP 생성 (10분 유효)
    const otp = Math.floor(100000 + Math.random() * 900000).toString();
    const expiresAt = Date.now() + 10 * 60 * 1000;
    otpStore.set(studentId, { otp, name, expiresAt });

    const email = `${studentId}@dankook.ac.kr`;
    console.log(`[OTP] ${email} → ${otp}`);
    await sendOtpEmail(email, otp);

    res.json({ message: '인증번호가 전송되었습니다.', email });
  } catch (err) {
    if (err.code === 'INVALID_CREDENTIALS') {
      return res.status(401).json(err);
    }
    if (err.code === 'NOT_ENROLLED') {
      return res.status(403).json(err);
    }
    if (err.code === 'INVALID_FORMAT') {
      return res.status(400).json(err);
    }
    next(err);
  }
});

// POST /auth/register/verify-otp — OTP 검증 및 계정 생성
router.post('/register/verify-otp', async (req, res, next) => {
  try {
    const { studentId, otp } = req.body;
    if (!studentId || !otp) {
      return res.status(400).json({ code: 'MISSING_FIELDS', message: '학번과 인증번호를 입력해주세요.' });
    }

    const stored = otpStore.get(studentId);
    if (!stored) {
      return res.status(400).json({ code: 'OTP_NOT_FOUND', message: '인증번호를 먼저 요청해주세요.' });
    }

    if (Date.now() > stored.expiresAt) {
      otpStore.delete(studentId);
      return res.status(400).json({ code: 'OTP_EXPIRED', message: '인증번호가 만료되었습니다. 다시 요청해주세요.' });
    }

    if (stored.otp !== otp) {
      return res.status(400).json({ code: 'INVALID_OTP', message: '인증번호가 올바르지 않습니다.' });
    }

    const email = `${studentId}@dankook.ac.kr`;
    const user = await prisma.user.create({
      data: { studentId, name: stored.name, email },
    });

    otpStore.delete(studentId);

    const tokenPayload = {
      userId: user.id,
      studentId: user.studentId,
      name: user.name,
      isAdmin: user.isAdmin,
    };
    const tokens = signTokens(tokenPayload);

    res.status(201).json({ ...tokens, user: { id: user.id, studentId: user.studentId, name: user.name } });
  } catch (err) {
    next(err);
  }
});

// POST /auth/refresh
router.post('/refresh', async (req, res) => {
  const { refreshToken } = req.body;
  if (!refreshToken) return res.status(400).json({ code: 'MISSING_TOKEN', message: 'refreshToken 필요' });

  try {
    const payload = jwt.verify(refreshToken, process.env.JWT_REFRESH_SECRET);
    const { userId, studentId, name, isAdmin } = payload;
    const tokens = signTokens({ userId, studentId, name, isAdmin });
    res.json(tokens);
  } catch {
    res.status(401).json({ code: 'INVALID_TOKEN', message: '유효하지 않은 리프레시 토큰입니다.' });
  }
});

// POST /auth/logout
router.post('/logout', authMiddleware, async (req, res, next) => {
  try {
    await prisma.user.update({
      where: { id: req.user.userId },
      data: { fcmToken: null },
    });
    res.json({ message: '로그아웃 완료' });
  } catch (err) {
    next(err);
  }
});

// DELETE /auth/me — 회원 탈퇴
router.delete('/me', authMiddleware, async (req, res, next) => {
  try {
    await prisma.user.delete({ where: { id: req.user.userId } });
    res.json({ message: '회원 탈퇴가 완료되었습니다.' });
  } catch (err) {
    next(err);
  }
});

// PATCH /auth/fcm-token
router.patch('/fcm-token', authMiddleware, async (req, res, next) => {
  try {
    const { fcmToken } = req.body;
    await prisma.user.update({
      where: { id: req.user.userId },
      data: { fcmToken },
    });
    res.json({ message: 'FCM 토큰 업데이트 완료' });
  } catch (err) {
    next(err);
  }
});

module.exports = router;
