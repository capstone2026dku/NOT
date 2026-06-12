from fastapi import APIRouter
from pydantic import BaseModel
from typing import List
from ai.preference import get_preference
from ai.weather import get_weather
from ai.cooking_time import get_cooking_time, update_cooking_time

router = APIRouter()

class Menu(BaseModel):
    menuId: int
    corner: str
    alias: str
    price: int

class Request(BaseModel):
    menu: List[str]

class CookingTimeRequest(BaseModel):
    menu: str
    orderCount: int

class CookingTimeUpdateRequest(BaseModel):
    menu: str
    orderCount: int
    actualTime: int

class Response(BaseModel):
    menu: List[Menu]

class CookingTimeResponse(BaseModel):
    cookingTime: int

@router.post("/preference", response_model = Response)
def preference_res(req: Request):
    recommendations = get_preference(req.menu)

    return {"menu": recommendations[:3]}

@router.get("/weather", response_model = Response)
def weather_res():
    recommendations = get_weather()

    return {"menu": recommendations[:3]}

@router.post("/cooking_time", response_model = CookingTimeResponse)
def cooking_time_res(req: CookingTimeRequest):
    res = get_cooking_time(req.menu, req.orderCount)

    return {"cookingTime": res}

@router.post("/cooking_time_update")
def cooking_time_update_res(req: CookingTimeUpdateRequest):
    update_cooking_time(req.menu, req.orderCount, req.actualTime)

    return {"message": "Cooking time is updated"}