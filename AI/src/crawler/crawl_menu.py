import requests
import re
import json

url = "https://www.dankook.ac.kr/web/kor/1947_commons"

def crawl_menu():
    # 메뉴를 크롤링
    res = requests.get(url)
    res = re.search(r'type="application/json">([\s\S]*?)</script>', res.text)
    data = json.loads(res.group(1))

    # 크롤링한 메뉴를 파싱
    menu = []
    for x in data:
        corner_name = x.get("corner", "")
        for item in x.get("menus", []):
            menu.append({
                "menuId": item.get("menuId", 0),
                "corner": corner_name,
                "alias": item.get("alias", ""),
                "price": item.get("price", 0),
                "isSoldOut": item.get("isSoldOut", False)
            })

    menu.sort(key = lambda x: x["menuId"])

    return menu