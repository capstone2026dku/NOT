from datetime import datetime
import json
import os

# 시간대, 주문수 가중치
LUNCH_TIME_WEIGHT = 10
DINNER_TIME_WEIGHT = 5
ORDER_WEIGHT = 1

# 식당별, 메뉴별 가중치
MENU_WEIGHT_FILE = "menu_weight.json"
MENU_WEIGHT = {}

def load_weights():
    global MENU_WEIGHT
    if os.path.exists(MENU_WEIGHT_FILE):
        with open(MENU_WEIGHT_FILE, "r", encoding = "utf-8") as f:
            MENU_WEIGHT = json.load(f)
    else:
        MENU_WEIGHT = {}

def save_weights():
    with open(MENU_WEIGHT_FILE, "w", encoding = "utf-8") as f:
        json.dump(MENU_WEIGHT, f, ensure_ascii = False, indent = 4)

def get_cooking_time(menu, orderCount):
    # 시간대 가중치
    time_weight = 0
    hour = datetime.now().hour
    if 11 <= hour <= 13:
        time_weight += LUNCH_TIME_WEIGHT
    elif 17 <= hour <= 19:
        time_weight += DINNER_TIME_WEIGHT

    # 주문수 가중치
    order_weight = orderCount * ORDER_WEIGHT

    # 식당별, 메뉴별 가중치
    menu_weight = MENU_WEIGHT.get(menu, 10)

    # 요리 시간 예측
    cooking_time = round(max(time_weight + order_weight + menu_weight, 1))

    return cooking_time

def update_cooking_time(menu, orderCount, actualTime):
    # 요리 시간 예측
    predicted_time = get_cooking_time(menu, orderCount)

    # 예측 시간과 실제 시간 간의 오차 계산
    error = actualTime - predicted_time

    # 학습률 설정
    alpha = 0.3

    # 식당별, 메뉴별 가중치를 online learning / stochastic gradient descent 방식으로 업데이트
    current_weight = MENU_WEIGHT.get(menu, 10)
    MENU_WEIGHT[menu] = current_weight + error * alpha
    save_weights()

    return 0

# 서버 시작 시 1회 호출
load_weights()