from fastapi import FastAPI
from api.recommend import router as recommend_router

server = FastAPI()

server.include_router(recommend_router)