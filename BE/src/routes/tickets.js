const express = require('express');
const { PrismaClient } = require('@prisma/client');
const { authenticate } = require('../middlewares/auth');

const router = express.Router();
const prisma = new PrismaClient();

// GET /tickets — 내 식권 목록
router.get('/', authenticate, async (req, res, next) => {
  try {
    const tickets = await prisma.ticket.findMany({
      where: { userId: req.user.userId },
      orderBy: { createdAt: 'desc' },
    });
    res.json(tickets);
  } catch (err) {
    next(err);
  }
});

// POST /tickets — 식권 번호로 등록
router.post('/', authenticate, async (req, res, next) => {
  try {
    const { ticketNumber } = req.body;
    if (!ticketNumber || ticketNumber.trim().length < 6) {
      return res.status(400).json({ code: 'INVALID_NUMBER', message: '올바른 식권 번호를 입력해주세요.' });
    }

    const normalized = ticketNumber.trim().toUpperCase();

    const existing = await prisma.ticket.findUnique({ where: { ticketNumber: normalized } });
    if (existing) {
      if (existing.userId === req.user.userId) {
        return res.status(409).json({ code: 'ALREADY_REGISTERED', message: '이미 등록된 식권입니다.' });
      }
      return res.status(409).json({ code: 'TICKET_TAKEN', message: '이미 사용 중인 식권 번호입니다.' });
    }

    const now = new Date();
    const validUntil = new Date(now);
    validUntil.setMonth(validUntil.getMonth() + 1);

    const ticket = await prisma.ticket.create({
      data: {
        userId: req.user.userId,
        ticketNumber: normalized,
        amount: 5000,
        location: '단국대 학생식당',
        validFrom: now,
        validUntil,
        status: 'AVAILABLE',
      },
    });

    res.status(201).json(ticket);
  } catch (err) {
    next(err);
  }
});

module.exports = router;
