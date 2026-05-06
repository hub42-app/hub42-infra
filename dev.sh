#!/bin/bash
# Local development helper script
# Usage: ./dev.sh [command]

set -e

COMPOSE_FILE="docker-compose.dev.yml"
ENV_FILE=".env.dev"

case "${1:-help}" in
  up)
    echo "🚀 Запуск локального середовища..."
    docker-compose -f $COMPOSE_FILE up -d
    echo ""
    echo "✓ Середовище запущено!"
    echo ""
    echo "📍 Додай в /etc/hosts (якщо ще не додав):"
    echo "   127.0.0.1 hub42.local api.hub42.local crm.hub42.local admin.hub42.local portal.hub42.local scanner.hub42.local"
    echo ""
    echo "🌐 Портали доступні за адресами:"
    echo "   Landing:  http://hub42.local:3000"
    echo "   CRM:      http://crm.hub42.local:3000"
    echo "   Admin:    http://admin.hub42.local:3000"
    echo "   Customer: http://portal.hub42.local:3000"
    echo "   Scanner:  http://scanner.hub42.local:3000"
    echo "   API:      http://api.hub42.local:3000"
    echo ""
    echo "📊 Або прямо на dev портах:"
    echo "   Landing:  http://localhost:5177"
    echo "   CRM:      http://localhost:5173"
    echo "   Admin:    http://localhost:5175"
    echo "   Customer: http://localhost:5174"
    echo "   API:      http://localhost:8081"
    ;;
  down)
    echo "🛑 Зупинка середовища..."
    docker-compose -f $COMPOSE_FILE down
    echo "✓ Середовище зупинено"
    ;;
  restart)
    echo "🔄 Перезавантаження..."
    docker-compose -f $COMPOSE_FILE restart
    echo "✓ Перезавантажено"
    ;;
  logs)
    service=${2:-all}
    if [ "$service" = "all" ]; then
      docker-compose -f $COMPOSE_FILE logs -f
    else
      docker-compose -f $COMPOSE_FILE logs -f $service
    fi
    ;;
  status|ps)
    docker-compose -f $COMPOSE_FILE ps
    ;;
  clean)
    echo "🧹 Видалення контейнерів і томів..."
    docker-compose -f $COMPOSE_FILE down -v
    echo "✓ Очищено"
    ;;
  *)
    echo "site42 Local Development Helper"
    echo ""
    echo "Usage: ./dev.sh [command]"
    echo ""
    echo "Commands:"
    echo "  up              - Запустити локальне середовище"
    echo "  down            - Зупинити середовище"
    echo "  restart         - Перезавантажити контейнери"
    echo "  status, ps      - Показати статус контейнерів"
    echo "  logs [service]  - Переглянути логи (service: backend, landing, crm, admin, customer, scanner)"
    echo "  clean           - Видалити всі контейнери і томи"
    echo ""
    echo "Приклади:"
    echo "  ./dev.sh up              # Запустити всю систему"
    echo "  ./dev.sh logs backend    # Переглянути логи backend'у"
    echo "  ./dev.sh logs landing    # Переглянути логи landing'у"
    ;;
esac
