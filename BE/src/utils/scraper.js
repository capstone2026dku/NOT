const axios = require('axios');
const { PrismaClient } = require('@prisma/client');

async function fetchCookTimeSec(menuName) {
  const aiUrl = process.env.AI_URL || 'http://localhost:8000';
  try {
    const { data } = await axios.post(`${aiUrl}/cooking_time`, { menu: menuName, orderCount: 0 }, { timeout: 5000 });
    return data.cookingTime * 60;
  } catch {
    return 300;
  }
}

const prisma = new PrismaClient();

const MENU_URL = process.env.DANKOOK_MENU_URL || 'https://www.dankook.ac.kr/web/kor/1947_commons';

let lastScrapeAt = null;
let lastScrapeSuccess = false;

/**
 * 단국대 푸드코트 페이지에서 메뉴 JSON을 파싱합니다.
 * 페이지 HTML에 <script type="application/json"> 태그로 직접 embed되어 있습니다.
 */
async function fetchMenuData() {
  const res = await axios.get(MENU_URL, {
    headers: { 'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36' },
    timeout: 15000,
  });

  const html = res.data;
  // 푸드코트 portlet 내부의 JSON 데이터 추출
  const match = html.match(/id="_dku_food_FoodCourtPortlet[^"]*_menusData"[^>]*type="application\/json">([\s\S]*?)<\/script>/);
  if (!match) {
    // fallback: 첫 번째 application/json script 태그
    const fallback = html.match(/type="application\/json">([\s\S]*?)<\/script>/);
    if (!fallback) throw new Error('메뉴 JSON을 찾을 수 없습니다');
    return JSON.parse(fallback[1]);
  }
  return JSON.parse(match[1]);
}

/**
 * 메뉴 전체 동기화.
 * - 웹사이트 기준으로 메뉴 추가/비활성화/가격수정/품절상태를 모두 반영합니다.
 */
async function scrapeMenus() {
  try {
    const corners = await fetchMenuData();

    let added = 0, deactivated = 0, updated = 0, notFound = 0;

    for (const corner of corners) {
      let restaurant = await prisma.restaurant.findFirst({
        where: {
          OR: [
            { name: corner.corner },
            { name: { contains: corner.corner } },
          ],
        },
      });

      if (!restaurant) {
        // 웹사이트에서 처음 보는 식당이면 자동 생성
        const code = corner.corner
          .replace(/[^a-zA-Z0-9가-힣]/g, '')
          .slice(0, 6)
          .toUpperCase()
          .replace(/[^A-Z0-9]/g, '') || `R${Date.now()}`.slice(-6);
        const newRestaurant = await prisma.restaurant.create({
          data: {
            name: corner.corner,
            code: code || `R${Date.now()}`.slice(-6),
            openTime: '10:30',
            closeTime: '19:00',
          },
        }).catch(async () => {
          // code 중복 시 유니크 코드로 재시도
          return prisma.restaurant.create({
            data: {
              name: corner.corner,
              code: `R${Date.now()}`.slice(-6),
              openTime: '10:30',
              closeTime: '19:00',
            },
          });
        });
        console.log(`🆕 새 식당 등록: "${corner.corner}"`);
        restaurant = newRestaurant;
      }

      const webMenuMap = {};
      for (const m of corner.menus) webMenuMap[m.alias] = m;

      const dbMenus = await prisma.menu.findMany({ where: { restaurantId: restaurant.id } });
      const dbMenuMap = {};
      for (const m of dbMenus) dbMenuMap[m.name] = m;

      // 웹에 없는 DB 메뉴 → 비활성화
      for (const dbMenu of dbMenus) {
        if (!webMenuMap[dbMenu.name] && dbMenu.isActive) {
          await prisma.menu.update({ where: { id: dbMenu.id }, data: { isActive: false } });
          deactivated++;
        }
      }

      // 웹 메뉴 기준으로 추가 또는 업데이트
      for (const webMenu of corner.menus) {
        const dbMenu = dbMenuMap[webMenu.alias];
        if (!dbMenu) {
          const cookTimeSec = await fetchCookTimeSec(webMenu.alias);
          await prisma.menu.create({
            data: {
              restaurantId: restaurant.id,
              name: webMenu.alias,
              price: webMenu.price,
              isActive: true,
              isSoldout: webMenu.isSoldOut,
              cookTimeSec,
            },
          });
          added++;
        } else if (
          dbMenu.price !== webMenu.price ||
          !dbMenu.isActive ||
          dbMenu.isSoldout !== webMenu.isSoldOut
        ) {
          await prisma.menu.update({
            where: { id: dbMenu.id },
            data: { price: webMenu.price, isActive: true, isSoldout: webMenu.isSoldOut },
          });
          updated++;
        }
      }
    }

    lastScrapeAt = new Date();
    lastScrapeSuccess = true;
    console.log(`✅ 메뉴 동기화 완료: 추가 ${added} | 비활성화 ${deactivated} | 수정 ${updated} | 미매핑 ${notFound}`);
    return { success: true, added, deactivated, updated, notFound };
  } catch (err) {
    console.error('스크래핑 오류:', err.message);
    lastScrapeSuccess = false;
    return { success: false, reason: err.message };
  }
}

function getScrapeStatus() {
  return { lastScrapeAt, lastScrapeSuccess };
}

module.exports = { scrapeMenus, getScrapeStatus };
