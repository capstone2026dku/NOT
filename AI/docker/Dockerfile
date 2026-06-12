# 경량 파이썬 3.11 이미지 설치
FROM python:3.11-slim

# 디렉토리 설정
WORKDIR /home
ENV PYTHONPATH=/home/src

# C 컴파일러 설치
RUN apt-get update && apt-get install -y build-essential && rm -rf /var/lib/apt/lists/*

# 의존성 설치
COPY docker/requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# 모든 소스 코드 복사
COPY src/ .

# FastAPI 실행
EXPOSE 8000
CMD ["uvicorn", "main:server", "--host", "0.0.0.0", "--port", "8000"]