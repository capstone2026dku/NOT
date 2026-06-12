# AI
본 프로젝트는 단국대학교 학식 선주문 서비스의 AI 서버를 구현한 프로젝트입니다.  
본 프로젝트는 사용자 취향에 따른 메뉴 추천, 날씨에 따른 메뉴 추천 API를 제공합니다.

## 프로젝트 구조
본 프로젝트의 구조는 아래와 같습니다.
```
AI/
├─ docker/
│ ├─ docker-compose.yml  # 실행 버튼
│ ├─ Dockerfile          # 빌드 방법
│ └─ requirements.txt    # 의존성 설정
│
├─ src/
│ ├─ ai/
│ │ ├─ cooking_time.py   # 요리가 나오는 시간을 예측하는 AI
│ │ ├─ preference.py     # 취향에 따른 추천 메뉴를 반환하는 AI
│ │ └─ weather.py        # 날씨에 따른 추천 메뉴를 반환하는 AI
│ │
│ ├─ api/
│ │ └─ recommend.py      # 엔드포인트
│ │
│ ├─ crawler/
│ │ ├─ crawl_menu.py     # 메뉴를 크롤링
│ │ └─ crawl_weather.py  # 날씨를 크롤링
│ │
│ ├─ test/
│ │ ├─ recommend.js      # 테스트 코드 라이브러리
│ │ └─ test.js           # 테스트 코드
│ │
│ └─ main.py             # FastAPI 실행
│
└─ README.md
```

## 기능
본 프로젝트는 아래와 같은 기능을 제공합니다.
| 디렉토리 | 기능 |
|-|-|
| `docker/` | 가상 환경을 구현하기 위한 디렉토리입니다. |
| `src/ai/` | 메뉴 추천 기능을 구현한 소스 코드 디렉토리입니다. |
| `src/api/` | 엔드포인트를 구현한 소스 코드 디렉토리입니다. |
| `src/crawler/` | 크롤링 기능을 구현한 소스 코드 디렉토리입니다. |
| `src/test/` | API 사용 예시를 구현한 디렉토리입니다. |

## 설치 방법
본 프로젝트는 아래와 같은 방법으로 설치할 수 있습니다.
1. Clone합니다.
   ```
   gh repo clone capstone2026dku/AI/
   ```

2. `capstone2026dku/AI/` 디렉토리로 이동합니다.
   ```
   cd capstone2026dku/AI/
   ```

3. Docker Desktop을 설치합니다.
   | 운영 체제 | 링크 |
   |-|-|
   | Mac | [Install Docker Desktop on Mac](https://docs.docker.com/desktop/setup/install/mac-install/) |
   | Windows | [Install Docker Desktop on Windows](https://docs.docker.com/desktop/setup/install/windows-install/) |

## 실행 방법
본 프로젝트는 아래와 같은 방법으로 실행할 수 있습니다.
1. Docker Desktop을 실행합니다.  
   컨테이너가 가상 환경에 의존성을 자동으로 설치하도록 구현하였기 때문에 의존성을 설치할 필요는 없습니다.

2. `docker/` 디렉토리로 이동합니다.
   ```
   cd docker/
   ```

3. `docker-compose.yml`을 실행합니다.
   ```
   docker-compose up --build
   ```

## 테스트 방법
본 프로젝트는 아래와 같은 방법으로 테스트하였습니다.
1. 위 실행 방법을 따라 진행한 후 아래 방법을 진행합니다.

2. `src/test/` 디렉토리로 이동합니다.
   ```
   cd src/test/
   ```

3. `test.js`를 실행합니다.
   ```
   node test.js
   ```

## 기여 방법
본 프로젝트에 아래와 같은 방법으로 기여할 수 있습니다.
1. Branch를 생성합니다.
   ```
   git checkout -b <fix/#1-OOO>
   ```

2. Add로 수정한 내용을 추가합니다.
   ```
   git add .
   ```

3. Commit합니다.
   ```
   git commit -m "<[fix/#1] OOO 수정>"
   ```

4. Push합니다.
   ```
   git push origin <fix/#1-OOO>
   ```

5. PR을 보냅니다.

## 기술 스택
본 프로젝트의 기술 스택은 아래와 같습니다.
| 항목 | 내용 |
|-|-|
| 환경 | `Docker Desktop` |
| 컨테이너화 | `Docker` `Docker Compose` |
| 언어 | `JavaScript` `Python` |
| 서버 | `Uvicorn` |
| 프레임워크 | `FastAPI` |
| API 검증 | `Pydantic` |
| 크롤링 | `Beautiful Soup` `Requests` |
| AI | 자체 제작 |
| 테스트 | `Node.js` |
| 버전 관리 | `Git` `GitHub` |

## API 명세서
본 프로젝트는 아래와 같은 API를 제공합니다.
| 메서드 | 경로 | 설명 |
|-|-|-|
| `POST` | `/preference` | 사용자 선호도 기반 메뉴 추천 API |
| `GET` | `/weather` | 날씨 기반 메뉴 추천 API |
| `POST` | `/cooking_time` | 요리가 나오는 시간을 예측하는 API |
| `POST` | `/cooking_time_update` | 실제 요리가 나오는 시간을 업데이트하는 API |

- 위 실행 방법을 따라 진행한 후 `http://localhost:8000/docs`에서 `Swagger`를 사용할 수 있습니다.
- Node.js 환경에서 API를 사용하기 위한 라이브러리와 예시 코드는 `src/test/` 디렉토리에 있습니다.

## 작성자
- Yoo, J. H. ([Yoo, J. H.](https://github.com/YooJunHyuk123))