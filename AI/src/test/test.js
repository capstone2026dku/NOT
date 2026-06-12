// 경로를 수정해서 사용
import { get_preference, get_weather, get_cooking_time, update_cooking_time } from "./recommend.js";

// 사용자 선호도 기반 메뉴 추천 사용 예시
const res0 = await get_preference(["광뚝사골칼국수", "물냉면", "냉모밀"]);
const res1 = await get_preference(["오므라이스", "스팸마요덮밥(라지)", "새우튀김 우동"]);
const res2 = await get_preference(["마라쌀국수(고기없음)", "얼큰순대국밥", "제육덮밥"]);
console.log(`면을 선호하는 사용자에게 추천하는 메뉴: ${res0.menu[0].alias}, ${res0.menu[1].alias}, ${res0.menu[2].alias}`);
console.log(`일식을 선호하는 사용자에게 추천하는 메뉴: ${res1.menu[0].alias}, ${res1.menu[1].alias}, ${res1.menu[2].alias}`);
console.log(`매운 음식을 선호하는 사용자에게 추천하는 메뉴: ${res2.menu[0].alias}, ${res2.menu[1].alias}, ${res2.menu[2].alias}`)

// 날씨 기반 메뉴 추천 사용 예시
const res3 = await get_weather();
console.log(`날씨 기반 추천 메뉴: ${res3.menu[0].alias}, ${res3.menu[1].alias}, ${res3.menu[2].alias}`)

// 시간대, 주문수 기반 요리 시간 예측
const res4 = await get_cooking_time("떡갈비", 10);
console.log(`주문수가 10인 경우, 떡갈비의 예측 요리 시간: ${res4.cookingTime}분`)

// 식당별, 메뉴별 요리 시간을 반영하기 위한 실제 요리 시간 학습
await update_cooking_time("떡갈비", 10, 20);
console.log("주문수가 10인 경우, 떡갈비의 예측 요리 시간이 20분임을 학습")

// 식당별, 메뉴별 요리 시간이 반영된 시간대, 주문수 기반 요리 시간 예측
const res5 = await get_cooking_time("떡갈비", 10);
console.log(`주문수가 10인 경우, 떡갈비의 예측 요리 시간: ${res5.cookingTime}분`)

// 실제 요리 시간 학습, 요리 시간 예측을 반복
await update_cooking_time("떡갈비", 20, 30);
const res6 = await get_cooking_time("떡갈비", 20);
await update_cooking_time("떡갈비", 30, 40);
const res7 = await get_cooking_time("떡갈비", 30);
await update_cooking_time("떡갈비", 40, 50);
const res8 = await get_cooking_time("떡갈비", 40);
await update_cooking_time("순대국밥", 10, 30);
const res9 = await get_cooking_time("순대국밥", 10);
await update_cooking_time("순대국밥", 20, 40);
const res10 = await get_cooking_time("순대국밥", 20);
await update_cooking_time("순대국밥", 30, 50);
const res11 = await get_cooking_time("순대국밥", 30);
await update_cooking_time("등심돈카츠", 10, 5);
const res12 = await get_cooking_time("등심돈카츠", 10);
await update_cooking_time("등심돈카츠", 20, 15);
const res13 = await get_cooking_time("등심돈카츠", 20);
await update_cooking_time("등심돈카츠", 30, 25);
const res14 = await get_cooking_time("등심돈카츠", 30);
console.log(`예측 요리 시간: ${res6.cookingTime}, 실제 요리 시간: 30분`)
console.log(`예측 요리 시간: ${res7.cookingTime}, 실제 요리 시간: 40분`)
console.log(`예측 요리 시간: ${res8.cookingTime}, 실제 요리 시간: 50분`)
console.log(`예측 요리 시간: ${res9.cookingTime}, 실제 요리 시간: 30분`)
console.log(`예측 요리 시간: ${res10.cookingTime}, 실제 요리 시간: 40분`)
console.log(`예측 요리 시간: ${res11.cookingTime}, 실제 요리 시간: 50분`)
console.log(`예측 요리 시간: ${res12.cookingTime}, 실제 요리 시간: 5분`)
console.log(`예측 요리 시간: ${res13.cookingTime}, 실제 요리 시간: 15분`)
console.log(`예측 요리 시간: ${res14.cookingTime}, 실제 요리 시간: 25분`)