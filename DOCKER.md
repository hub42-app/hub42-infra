# Docker Compose Configuration

## Development (docker-compose.dev.yml)

Для локальної розробки з гарячою перезавантаженням.

### Запуск:
```bash
export DB_USER=admin DB_PASSWORD=password JWT_SECRET=dev-secret
docker-compose -f docker-compose.dev.yml up -d
```

### Доступні адреси:
- **Landing Page**: http://localhost:5177
- **CRM Portal**: http://localhost:5173
- **Admin Portal**: http://localhost:5174
- **Customer Portal**: http://localhost:5175
- **Scanner**: http://localhost:5176
- **Backend API**: http://localhost:8081
- **Reverse Proxy**: http://localhost:3000

### Особливості:
- Всі фронтенд сервіси запускаються на Vite dev серверах з HMR
- Backend запускається з Maven для гарячої перезавантаження
- База даних з `SPRING_JPA_HIBERNATE_DDL_AUTO: update` (автоматичні міграції)
- Мінімальні healthcheck timeout для швидкого запуску

### Команди:
```bash
# Зупинення
docker-compose -f docker-compose.dev.yml down

# Перегляд логів
docker-compose -f docker-compose.dev.yml logs -f backend
docker-compose -f docker-compose.dev.yml logs -f landing

# Перебудова конкретного сервісу
docker-compose -f docker-compose.dev.yml build landing
docker-compose -f docker-compose.dev.yml up -d landing
```

---

## Production (docker-compose.prod.yml)

Для продакшену з оптимізованими образами.

### Запуск:
```bash
export DB_USER=YOUR_DB_USER \
       DB_PASSWORD=YOUR_STRONG_PASSWORD \
       JWT_SECRET=YOUR_JWT_SECRET \
       SENTRY_DSN=YOUR_SENTRY_DSN \
       MAIL_HOST=smtp.example.com \
       MAIL_PORT=587 \
       MAIL_FROM=noreply@hub42.app \
       APP_BASE_URL=https://crm.hub42.app \
       PORTAL_BASE_URL=https://portal.hub42.app

docker-compose -f docker-compose.prod.yml up -d
```

### Доступні адреси:
- **Всі сервіси доступні через Caddy** на портах 80/443:
  - https://hub42.app — Landing Page
  - https://crm.hub42.app — CRM Portal
  - https://admin.hub42.app — Admin Portal
  - https://portal.hub42.app — Customer Portal
  - https://scanner.hub42.app — Scanner
  - https://api.hub42.app — Backend API

### Особливості:
- Всі фронтенд сервіси запускаються як статичні сайти за nginx
- Backend запускається як готовий JAR файл
- База даних з `SPRING_JPA_HIBERNATE_DDL_AUTO: validate` (без автоматичних змін)
- CORS обмежено тільки на HTTPS з hub42.app
- Всі сервіси з `restart: unless-stopped` для надійності
- Більші healthcheck timeout для стабільності

### Команди:
```bash
# Перегляд логів
docker-compose -f docker-compose.prod.yml logs -f backend
docker-compose -f docker-compose.prod.yml logs -f caddy

# Перебудова образів (для нової версії)
docker-compose -f docker-compose.prod.yml build
docker-compose -f docker-compose.prod.yml up -d

# Зупинення
docker-compose -f docker-compose.prod.yml down
```

---

## Порівняння

| Параметр | Development | Production |
|----------|-------------|------------|
| **Backend** | Dockerfile.dev (Maven) | Dockerfile.local-prod (JAR) |
| **Frontend** | Dockerfile.dev (Vite) | Dockerfile.prod (nginx) |
| **Ports** | Всі експортовані | Тільки Caddy 80/443 |
| **HMR** | Так | Ні |
| **CORS** | Локальні адреси | Тільки HTTPS hub42.app |
| **DB Update** | update | validate |
| **Healthcheck** | Мінімальні | Максимальні |
| **Restart** | Ні | unless-stopped |

---

## Перехід з Dev на Prod

```bash
# 1. Зупинити dev
docker-compose -f docker-compose.dev.yml down

# 2. Встановити env vars
export DB_USER=... DB_PASSWORD=... JWT_SECRET=... ...

# 3. Запустити prod
docker-compose -f docker-compose.prod.yml up -d

# 4. Перевірити
docker ps
curl https://hub42.app
```
