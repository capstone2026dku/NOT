const express = require('express');
const { PrismaClient } = require('@prisma/client');
const { authenticate } = require('../middlewares/auth');

const router = express.Router();
const prisma = new PrismaClient();

// POST /inquiry — 문의 접수
router.post('/', authenticate, async (req, res, next) => {
  try {
    const { content } = req.body;
    if (!content || content.trim().length === 0) {
      return res.status(400).json({ code: 'EMPTY_CONTENT', message: '문의 내용을 입력해주세요.' });
    }

    const inquiry = await prisma.inquiry.create({
      data: {
        userId: req.user.userId,
        content: content.trim(),
      },
    });

    res.status(201).json({ id: inquiry.id, message: '문의가 접수되었습니다.' });
  } catch (err) {
    next(err);
  }
});

module.exports = router;
