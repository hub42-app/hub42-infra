#!/bin/bash
# Development environment launcher
# Usage: ./dev.sh [up|down|logs|restart]

set -e

COMMAND="${1:-up}"

case "$COMMAND" in
  up)
    echo "🚀 Starting development environment..."
    docker-compose -f docker-compose.dev.yml up -d
    echo ""
    echo "✅ Development environment is running!"
    echo ""
    echo "📍 Services:"
    echo "  - Backend API: http://localhost:8081"
    echo "  - Landing: http://localhost:5177"
    echo "  - CRM Portal: http://localhost:5173"
    echo "  - Admin Portal: http://localhost:5174"
    echo "  - Customer Portal: http://localhost:5175"
    echo "  - Reverse Proxy: http://localhost:3000"
    echo ""
    echo "💻 View logs: ./dev.sh logs [service]"
    echo "🛑 Stop: ./dev.sh down"
    ;;

  down)
    echo "🛑 Stopping development environment..."
    docker-compose -f docker-compose.dev.yml down
    echo "✅ Development environment stopped"
    ;;

  logs)
    SERVICE="${2:-}"
    if [ -z "$SERVICE" ]; then
      docker-compose -f docker-compose.dev.yml logs -f
    else
      docker-compose -f docker-compose.dev.yml logs -f "$SERVICE"
    fi
    ;;

  restart)
    SERVICE="${2:-}"
    if [ -z "$SERVICE" ]; then
      echo "Usage: ./dev.sh restart [service]"
      echo "Example: ./dev.sh restart backend"
      exit 1
    fi
    echo "🔄 Restarting $SERVICE..."
    docker-compose -f docker-compose.dev.yml restart "$SERVICE"
    echo "✅ $SERVICE restarted"
    ;;

  status)
    docker ps --filter "name=site42" --format "table {{.Names}}\t{{.Ports}}\t{{.Status}}"
    ;;

  *)
    echo "Usage: ./dev.sh [command]"
    echo ""
    echo "Commands:"
    echo "  up         - Start development environment"
    echo "  down       - Stop development environment"
    echo "  logs       - View logs (use: ./dev.sh logs [service])"
    echo "  restart    - Restart service (use: ./dev.sh restart [service])"
    echo "  status     - Show service status"
    exit 1
    ;;
esac
