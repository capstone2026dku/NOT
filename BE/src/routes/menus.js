const express = require('express');
const { PrismaClient } = require('@prisma/client');
const { authenticate, requireAdmin } = require('../middlewares/auth');

const router = express.Router();
const prisma = new PrismaClient();

// GET /menus/me/reviews — 내가 쓴 리뷰 목록
router.get('/me/reviews', authenticate, async (req, res, next) => {
  try {
    const reviews = await prisma.review.findMany({
      where: { userId: req.user.userId },
      include: { menu: { include: { restaurant: true } } },
      orderBy: { createdAt: 'desc' },
    });
    res.json(reviews);
  } catch (err) {
    next(err);
  }
});

// GET /menus/:menuId/reviews — 특정 메뉴 리뷰 목록
router.get('/:menuId/reviews', authenticate, async (req, res, next) => {
  try {
    const reviews = await prisma.review.findMany({
      where: { menuId: req.params.menuId },
      include: { user: { select: { name: true, studentId: true } } },
      orderBy: { createdAt: 'desc' },
    });
    const avg =
      reviews.length > 0
        ? reviews.reduce((s, r) => s + r.rating, 0) / reviews.length
        : 0;
    res.json({ reviews, averageRating: Math.round(avg * 10) / 10, count: reviews.length });
  } catch (err) {
    next(err);
  }
});

// POST /menus/:menuId/reviews — 리뷰 작성
router.post('/:menuId/reviews', authenticate, async (req, res, next) => {
  try {
    const { rating, comment } = req.body;
    if (!rating || rating < 1 || rating > 5) {
      return res.status(400).json({ code: 'INVALID_RATING', message: '평점은 1~5 사이여야 합니다.' });
    }

    const menu = await prisma.menu.findUnique({ where: { id: req.params.menuId } });
    if (!menu) return res.status(404).json({ code: 'NOT_FOUND', message: '메뉴를 찾을 수 없습니다.' });

    const review = await prisma.review.upsert({
      where: { userId_menuId: { userId: req.user.userId, menuId: req.params.menuId } },
      update: { rating, comment: comment || null },
      create: {
        userId: req.user.userId,
        menuId: req.params.menuId,
        rating,
        comment: comment || null,
      },
    });

    res.status(201).json(review);
  } catch (err) {
    next(err);
  }
});

// PATCH /menus/:id/soldout
router.patch('/:id/soldout', requireAdmin, async (req, res, next) => {
  try {
    const menu = await prisma.menu.update({
      where: { id: req.params.id },
      data: { isSoldout: req.body.isSoldout },
    });
    res.json({ id: menu.id, isSoldout: menu.isSoldout });
  } catch (err) {
    next(err);
  }
});

module.exports = router;
