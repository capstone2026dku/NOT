from collections import Counter
from crawler.crawl_menu import crawl_menu
from crawler.crawl_weather import crawl_weather

# 국, 고기가 들어간 음식, 면 태그
soup = ["국", "순두부", "찌개"]
meat = ["갈비", "고기", "구이", "수육", "카츠", "편육", "포케"]
noodles = ["국수", "면", "모밀", "반꿔이", "볶이", "분짜", "우동", "짬뽕"]

# 차가운 음식, 뜨거운 음식, 매운 음식 태그
cold = ["냉", "밀면", "음료"]
hot = ["국", "뚝배기", "라면", "순두부", "우동", "짬뽕", "찌개"]
spicy = ["김치", "고추장", "마라", "라면", "얼큰", "제육", "짬뽕", "춘천"]

# 추운 날, 더운 날 선호 태그
cold_day = ["국", "뜨거운 음식", "매운 음식"]
hot_day = ["면", "차가운 음식"]

# 구름 많은 날, 흐린 날, 비 오는 날, 눈 오는 날, 맑은 날 선호 태그
cloudy = ["면"]
gloomy = ["뜨거운 음식"]
rainy = ["국", "뜨거운 음식", "매운 음식"]
snowy = ["국", "뜨거운 음식", "고기가 들어간 음식"]
sunny = ["차가운 음식"]

def append_tag(tag_list, tags, alias, tag):
    if any(tag_element in alias for tag_element in tag_list):
        tags.append(tag)

def get_weather():
    # 메뉴 크롤링
    menu = crawl_menu()

    # 메뉴 특징 태그화
    for x in menu:
        x["tags"] = []
        append_tag(soup, x["tags"], x["alias"], "국")
        append_tag(meat, x["tags"], x["alias"], "고기가 들어간 음식")
        append_tag(noodles, x["tags"], x["alias"], "면")
        append_tag(cold, x["tags"], x["alias"], "차가운 음식")
        append_tag(hot, x["tags"], x["alias"], "뜨거운 음식")
        append_tag(spicy, x["tags"], x["alias"], "매운 음식")
    
    # 날씨 크롤링
    temp, weather = crawl_weather()
    temp = float(temp)

    # 날씨에서 선호 태그 추출
    preference_tags = []
    if temp <= 10:
        preference_tags.extend(cold_day)
    elif temp >= 20:
        preference_tags.extend(hot_day)
    if "구름" in weather:
        preference_tags.extend(cloudy)
    if "흐" in weather:
        preference_tags.extend(gloomy)
    if "비" in weather:
        preference_tags.extend(rainy)
    if "눈" in weather:
        preference_tags.extend(snowy)
    if "맑" in weather:
        preference_tags.extend(sunny)

    # 날씨에서 선호 태그별 가중치 계산
    tag_counter = Counter(preference_tags)

    # 추천 메뉴
    recommendations = []
    for x in menu:
        # 품절된 메뉴 제외
        '''
        if x["isSoldOut"]:
            continue
        '''

        # 메뉴별 선호도 계산
        score = 0
        for tag in x["tags"]:
            score += tag_counter[tag]

        recommendations.append({
            "menuId": x["menuId"],
            "corner": x["corner"],
            "alias": x["alias"],
            "price": x["price"],
            "score": score
        })
    
    # 추천 메뉴를 점수순으로 정렬
    recommendations.sort(
        key = lambda x: x["score"],
        reverse = True
    )

    # 추천 메뉴에서 상위 3개 추천 메뉴를 반환
    return [
        {
            "menuId": x["menuId"],
            "corner": x["corner"],
            "alias": x["alias"],
            "price": x["price"],
        }
        for x in recommendations
    ]