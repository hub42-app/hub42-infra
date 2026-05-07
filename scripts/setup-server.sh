#!/bin/bash

# ============================================================================
# setup-server.sh — Hetzner VPS Initial Setup
# ============================================================================
# Run this script once on a fresh Hetzner VPS to set up Docker, Traefik,
# and project structure.
#
# Usage: ssh root@HETZNER_IP 'bash -s' < setup-server.sh
# ============================================================================

set -e

echo "=================================================="
echo "hub42 — Hetzner VPS Setup"
echo "=================================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
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

# ============================================================================
# 1. System Updates
# ============================================================================
log_info "Updating system packages..."
apt-get update -qq
apt-get upgrade -y -qq

# ============================================================================
# 2. Install Docker
# ============================================================================
log_info "Installing Docker..."
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh
rm get-docker.sh

# Add docker group (optional: for rootless Docker)
usermod -aG docker root || true

log_info "Docker version:"
docker --version

# ============================================================================
# 3. Install Docker Compose
# ============================================================================
log_info "Installing Docker Compose..."
curl -fsSL https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m) -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

log_info "Docker Compose version:"
docker-compose --version

# ============================================================================
# 4. Install Required Tools
# ============================================================================
log_info "Installing required tools (curl, wget, git)..."
apt-get install -y -qq curl wget git

# ============================================================================
# 5. Setup Firewall (UFW)
# ============================================================================
log_info "Setting up firewall (UFW)..."
apt-get install -y -qq ufw
ufw default deny incoming
ufw default allow outgoing
ufw allow 22/tcp  # SSH
ufw allow 80/tcp  # HTTP
ufw allow 443/tcp # HTTPS
ufw --force enable

log_info "Firewall status:"
ufw status

# ============================================================================
# 6. Create Project Directory Structure
# ============================================================================
log_info "Creating project directory structure at /opt/hub42..."
mkdir -p /opt/hub42/traefik

log_info "Creating ACME certificate file (Let's Encrypt)..."
touch /opt/hub42/traefik/acme.json
chmod 600 /opt/hub42/traefik/acme.json

# ============================================================================
# 7. Create Environment Variables
# ============================================================================
log_info "Creating .env file..."
cat > /opt/hub42/.env <<'EOF'
# ============================================================================
# hub42 Production Environment Variables
# ============================================================================

# Domain
DOMAIN=hub42.app

# GitHub Organization (for Docker images from ghcr.io)
GITHUB_ORG=your-github-org

# Database
DB_USER=hub42_user
DB_PASSWORD=change-this-to-a-strong-password

# JWT Secret
JWT_SECRET=change-this-to-a-very-long-random-string-at-least-32-chars

# Sentry (Error Tracking)
SENTRY_DSN=https://your-sentry-key@sentry.io/your-project-id
SENTRY_TRACES_RATE=0.1

# Mail (SMTP)
MAIL_HOST=smtp.gmail.com
MAIL_PORT=587
MAIL_USERNAME=your-email@gmail.com
MAIL_PASSWORD=your-app-password
MAIL_FROM=noreply@hub42.app

# Application URLs
APP_BASE_URL=https://crm.hub42.app
PORTAL_BASE_URL=https://portal.hub42.app

# Let's Encrypt (Traefik)
ACME_EMAIL=admin@hub42.app

# Timezone (optional)
TZ=UTC
EOF

log_warn "⚠️  IMPORTANT: Edit /opt/hub42/.env and set production values!"
log_info "Edit .env file: nano /opt/hub42/.env"

# ============================================================================
# 8. Create Docker Network
# ============================================================================
log_info "Creating Docker network (hub42-network)..."
docker network create hub42-network || log_warn "Network already exists"

# ============================================================================
# 9. Enable Docker Service Auto-Start
# ============================================================================
log_info "Enabling Docker service auto-start..."
systemctl enable docker
systemctl start docker

# ============================================================================
# 10. Setup Log Rotation
# ============================================================================
log_info "Setting up log rotation for Docker containers..."
cat > /etc/docker/daemon.json <<'EOF'
{
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  }
}
EOF

systemctl restart docker

# ============================================================================
# Final Steps
# ============================================================================
log_info "=================================================="
log_info "✅ Setup Complete!"
log_info "=================================================="
echo ""
echo "Next steps:"
echo ""
echo "1. Copy docker-compose.prod.yml to /opt/hub42/"
echo "   scp docker-compose.prod.yml root@HETZNER_IP:/opt/hub42/"
echo ""
echo "2. Copy traefik config to /opt/hub42/traefik/"
echo "   scp traefik/traefik.yml root@HETZNER_IP:/opt/hub42/traefik/"
echo ""
echo "3. Edit environment variables:"
echo "   nano /opt/hub42/.env"
echo ""
echo "4. Start services:"
echo "   cd /opt/hub42"
echo "   docker-compose pull"
echo "   docker-compose up -d"
echo ""
echo "5. Verify services are running:"
echo "   docker-compose ps"
echo "   docker-compose logs -f"
echo ""
