const express = require('express');
const axios = require('axios');
const { PrismaClient } = require('@prisma/client');
const { authenticate } = require('../middlewares/auth');

const router = express.Router();
const prisma = new PrismaClient();

function aiClient() {
  const baseURL = process.env.AI_URL || 'http://localhost:8000';
  return axios.create({ baseURL, timeout: 10000 });
}

async function resolveMenus(aiMenus) {
  const names = aiMenus.map((m) => m.alias);
  const dbMenus = await prisma.menu.findMany({
    where: { name: { in: names }, isActive: true },
  });
  const dbMap = new Map(dbMenus.map((m) => [m.name, m]));
  return aiMenus
    .map((m) => dbMap.get(m.alias))
    .filter(Boolean);
}

// GET /recommendations/preference — 사용자 주문 이력 기반 추천
router.get('/preference', authenticate, async (req, res, next) => {
  try {
    const orders = await prisma.order.findMany({
      where: { userId: req.user.userId, status: { in: ['PAID', 'PARTIALLY_COMPLETED', 'COMPLETED'] } },
      include: { orderItems: { include: { menu: true } } },
      orderBy: { createdAt: 'desc' },
      take: 20,
    });

    const menuNames = orders.flatMap((o) => o.orderItems.map((i) => i.menu.name));

    const { data } = await aiClient().post('/preference', { menu: menuNames });
    res.json(await resolveMenus(data.menu));
  } catch (err) {
    next(err);
  }
});

// GET /recommendations/weather — 날씨 기반 추천
router.get('/weather', authenticate, async (req, res, next) => {
  try {
    const { data } = await aiClient().get('/weather');
    res.json(await resolveMenus(data.menu));
  } catch (err) {
    next(err);
  }
});

module.exports = router;
