#!/bin/bash

# ============================================================================
# deploy.sh — Deploy Updated Services
# ============================================================================
# This script pulls the latest Docker images and restarts services.
#
# Usage (local):  ./scripts/deploy.sh [service]
# Usage (remote): ssh root@HETZNER_IP 'cd /opt/hub42 && bash deploy.sh [service]'
#
# Examples:
#   ./scripts/deploy.sh                    # Deploy all services
#   ./scripts/deploy.sh backend            # Deploy only backend
#   ./scripts/deploy.sh business-portal    # Deploy only business-portal
# ============================================================================

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log_info() {
  echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
  echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
  echo -e "${RED}[ERROR]${NC} $1"
}

log_step() {
  echo -e "${BLUE}==>${NC} $1"
}

# ============================================================================
# Configuration
# ============================================================================
PROJECT_DIR="${PROJECT_DIR:-.}"
SERVICE="${1:-all}"  # Service to deploy (all, backend, business-portal, etc.)
COMPOSE_FILE="${PROJECT_DIR}/docker-compose.prod.yml"

# ============================================================================
# Validation
# ============================================================================
if [ ! -f "$COMPOSE_FILE" ]; then
  log_error "docker-compose.prod.yml not found at $COMPOSE_FILE"
  exit 1
fi

log_info "Deployment Configuration:"
echo "  Project Dir:    $PROJECT_DIR"
echo "  Compose File:   $COMPOSE_FILE"
echo "  Service:        $SERVICE"
echo ""

# ============================================================================
# Pre-Deployment Checks
# ============================================================================
log_step "Checking Docker daemon..."
if ! docker ps > /dev/null 2>&1; then
  log_error "Docker daemon is not running"
  exit 1
fi

log_step "Checking docker-compose..."
docker-compose --version

# ============================================================================
# Pull Latest Images
# ============================================================================
log_step "Pulling latest Docker images..."

if [ "$SERVICE" = "all" ]; then
  log_info "Pulling all services..."
  docker-compose -f "$COMPOSE_FILE" pull --no-parallel 2>&1 | grep -v "is up to date" || true
else
  log_info "Pulling $SERVICE..."
  docker-compose -f "$COMPOSE_FILE" pull "$SERVICE" 2>&1 | grep -v "is up to date" || true
fi

# ============================================================================
# Deploy Services (Zero-Downtime)
# ============================================================================
log_step "Deploying services..."

if [ "$SERVICE" = "all" ]; then
  log_info "Starting all services..."
  docker-compose -f "$COMPOSE_FILE" up -d --no-deps
else
  log_info "Starting $SERVICE (zero-downtime)..."
  docker-compose -f "$COMPOSE_FILE" up -d --no-deps "$SERVICE"
fi

# ============================================================================
# Post-Deployment Verification
# ============================================================================
log_step "Verifying deployment..."

sleep 5

if [ "$SERVICE" = "all" ]; then
  docker-compose -f "$COMPOSE_FILE" ps
else
  docker-compose -f "$COMPOSE_FILE" ps "$SERVICE"
fi

# Check healthchecks
log_info "Waiting for services to be healthy..."
sleep 10

if docker-compose -f "$COMPOSE_FILE" ps | grep -q "unhealthy"; then
  log_warn "⚠️  Some services reported as unhealthy. Check logs:"
  docker-compose -f "$COMPOSE_FILE" logs --tail=50
else
  log_info "✅ All services appear healthy"
fi

# ============================================================================
# Final Output
# ============================================================================
echo ""
log_info "=================================================="
log_info "✅ Deployment Complete!"
log_info "=================================================="
echo ""
echo "Services Status:"
docker-compose -f "$COMPOSE_FILE" ps
echo ""
echo "View logs:"
echo "  docker-compose -f $COMPOSE_FILE logs -f [service]"
echo ""
echo "Rollback (if needed):"
echo "  docker-compose -f $COMPOSE_FILE down"
echo "  docker-compose -f $COMPOSE_FILE up -d"
echo ""
