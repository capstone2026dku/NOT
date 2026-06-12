from collections import Counter
from crawler.crawl_menu import crawl_menu

# 튀김, 밥, 사이드 음식, 국, 고기가 들어간 음식, 면 태그
fried = ["튀김"]
rice = ["라이스", "밥", "불백", "카레"]
side = ["고수", "만두", "빠스", "음료", "춘권", "치즈"]
soup = ["국", "순두부", "찌개"]
meat = ["갈비", "고기", "구이", "수육", "카츠", "편육", "포케"]
noodles = ["국수", "면", "모밀", "반꿔이", "볶이", "분짜", "우동", "짬뽕"]

# 중식, 일식, 한식, 베트남식 태그
cn = ["마파덮밥", "빠스", "짜장", "짬뽕", "춘권", "탕수육"]
jp = ["라이스", "마요덮밥", "모밀", "우동", "카레", "카츠"]
kr = ["갈비", "구이", "국밥", "김밥", "냉면", "밀면", "볶음밥", "볶이", "불고기", "불백", "비빔밥", "순두부", "제육", "찌개", "칼국수", "편육", "해장국"]
vn = ["반꿔이", "분짜", "쌀국수"]

# 차가운 음식, 뜨거운 음식, 매운 음식 태그
cold = ["냉", "밀면", "음료"]
hot = ["국", "뚝배기", "라면", "순두부", "우동", "짬뽕", "찌개"]
spicy = ["고추장", "마라", "라면", "얼큰", "제육", "짬뽕", "춘천"]

def append_tag(tag_list, tags, alias, tag):
    if any(tag_element in alias for tag_element in tag_list):
        tags.append(tag)

def get_preference(req_menu):
    # 메뉴 크롤링
    menu = crawl_menu()

    # 메뉴 특징 태그화
    for x in menu:
        x["tags"] = []
        append_tag(fried, x["tags"], x["alias"], "튀김")
        append_tag(rice, x["tags"], x["alias"], "밥")
        append_tag(side, x["tags"], x["alias"], "사이드 음식")
        append_tag(soup, x["tags"], x["alias"], "국")
        append_tag(meat, x["tags"], x["alias"], "고기가 들어간 음식")
        append_tag(noodles, x["tags"], x["alias"], "면")
        append_tag(cn, x["tags"], x["alias"], "중식")
        append_tag(jp, x["tags"], x["alias"], "일식")
        append_tag(kr, x["tags"], x["alias"], "한식")
        append_tag(vn, x["tags"], x["alias"], "베트남식")
        append_tag(cold, x["tags"], x["alias"], "차가운 음식")
        append_tag(hot, x["tags"], x["alias"], "뜨거운 음식")
        append_tag(spicy, x["tags"], x["alias"], "매운 음식")
    
    # 사용자가 선택한 메뉴
    selected_menu = []
    for x in menu:
        if x["alias"].strip() in req_menu:
            selected_menu.append(x)

    # 사용자가 선택한 메뉴에서 선호 태그 추출
    preference_tags = []
    for x in selected_menu:
        preference_tags.extend(x["tags"])

    # 사용자가 선택한 메뉴에서 선호 태그별 가중치 계산
    tag_counter = Counter(preference_tags)

    # 추천 메뉴
    recommendations = []
    for x in menu:
        # 품절된 메뉴 제외
        '''
        if x["isSoldOut"]:
            continue
        '''

        # 사용자가 이미 선택한 메뉴 제외
        if x["alias"].strip() in req_menu:
            continue

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