import requests
from bs4 import BeautifulSoup

url = "https://search.naver.com/search.naver?sm=tab_hty.top&where=nexearch&ssc=tab.nx.all&query=수지구+죽전동+날씨"

headers = {"User-Agent": "Mozilla/5.0"}

def crawl_weather():
    res = requests.get(url, headers = headers)
    bs = BeautifulSoup(res.text, "html.parser")
    temp = bs.select_one(".temperature_text").get_text(strip = True).replace("현재 온도", '').replace('°', '')
    weather = bs.select_one(".weather_main").get_text(strip = True)

    print("[INFO] 날씨 크롤링을 성공하였습니다")

    return [temp, weather]