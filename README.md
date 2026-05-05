# site42-infra — Deployment & Infrastructure

Central repository for coordinating deployment of site42 SaaS across all services on Hetzner VPS.

## Quick Start

### Prerequisites
- Hetzner VPS (CX32 or larger recommended)
- GitHub organization with 6 service repositories
- SSH access to VPS as root
- GitHub CLI (for secrets setup)

### 1. Initial Hetzner Setup (One-Time)

```bash
# Copy setup script and run on VPS
ssh root@HETZNER_IP 'bash -s' < scripts/setup-server.sh
```

This will:
- Install Docker + Docker Compose
- Create `/opt/site42/` directory structure
- Configure firewall (UFW): allows ports 22, 80, 443
- Initialize SSL certificate storage (acme.json)
- Create systemd service for auto-start

### 2. Configure Environment Variables

Edit `.env` on the VPS:

```bash
ssh root@HETZNER_IP
cd /opt/site42
nano .env
```

**Required variables:**
- `DOMAIN=hub42.app` (or your domain)
- `DB_PASSWORD=strong-password-at-least-16-chars`
- `JWT_SECRET=very-long-random-string-at-least-32-chars`
- `GITHUB_ORG=your-org-name` (for ghcr.io access)
- `SENTRY_DSN` (optional, for error tracking)
- `MAIL_*` variables for SMTP

### 3. Start Services

```bash
ssh root@HETZNER_IP
cd /opt/site42
docker-compose -f docker-compose.prod.yml pull
docker-compose -f docker-compose.prod.yml up -d
```

Verify services are running:
```bash
docker-compose -f docker-compose.prod.yml ps
```

### 4. Configure GitHub Secrets

In GitHub organization settings → Secrets and variables → Actions:

| Secret | Value |
|--------|-------|
| `HETZNER_SSH_KEY` | Content of your `~/.ssh/id_rsa` private key |
| `HETZNER_HOST` | VPS IP address or domain name |
| `PROD_DB_PASSWORD` | PostgreSQL password (must match .env on VPS) |
| `PROD_JWT_SECRET` | JWT signing secret (must match .env on VPS) |
| `PROD_SENTRY_DSN` | Sentry DSN (optional) |

**Note:** `GITHUB_TOKEN` for pushing to ghcr.io is automatic — no setup needed.

### 5. Deploy Services

#### Manual Deployment

SSH directly to VPS and run:

```bash
cd /opt/site42
bash deploy.sh [service]    # Deploy specific service
bash deploy.sh              # Deploy all services
```

#### GitHub Actions Deployment

1. Go to GitHub → Actions → "Deploy to Production" workflow
2. Click "Run workflow"
3. Select service to deploy (or "all")
4. Monitor logs in GitHub Actions

## Production Architecture

```
Hetzner VPS (1 instance)
├── Traefik 3.0 (reverse proxy + SSL)
│   ├── http://api.DOMAIN → backend:8081
│   ├── http://crm.DOMAIN → business-portal:80
│   ├── http://portal.DOMAIN → customer-portal:80
│   ├── http://admin.DOMAIN → admin-portal:80
│   ├── http://scan.DOMAIN → scanner:80
│   └── http://DOMAIN → landing:80
├── PostgreSQL 16 (persistent volume)
├── Redis 7 (cache)
└── 6 Services (from ghcr.io):
    ├── backend
    ├── business-portal
    ├── admin-portal
    ├── customer-portal
    ├── scanner
    └── landing
```

## CI/CD Pipeline

### Per-Service CI (Runs on push to main/develop)

Each of the 6 services has `.github/workflows/ci.yml` that:
1. Tests (Maven for backend, npm build for frontends)
2. Builds Docker image (multi-stage, optimized)
3. Pushes to GitHub Container Registry: `ghcr.io/ORG/SERVICE:latest`

### Infrastructure CD (Manual trigger)

`.github/workflows/deploy.yml` in this repo:
1. Manual trigger via GitHub Actions UI
2. SSHes into Hetzner VPS
3. Runs `docker-compose pull [service]`
4. Runs `docker-compose up -d --no-deps [service]`
5. Verifies service health

**Zero-downtime strategy:** `--no-deps` flag updates one service without restarting others.

## Directory Structure

```
site42-infra/
├── docker-compose.prod.yml    # Production orchestration
├── traefik/
│   ├── traefik.yml            # Reverse proxy static config
│   └── .gitignore             # Excludes acme.json (SSL certs)
├── scripts/
│   ├── setup-server.sh        # One-time VPS setup
│   └── deploy.sh              # Service deployment script
├── .github/workflows/
│   └── deploy.yml             # CD workflow (manual trigger)
├── .env.example               # Environment variables template
├── .gitignore                 # Git configuration
└── README.md                  # This file
```

## Troubleshooting

### Check VPS Status

```bash
ssh root@HETZNER_IP 'cd /opt/site42 && docker-compose ps'
```

### View Logs

```bash
# Traefik logs (reverse proxy)
ssh root@HETZNER_IP 'cd /opt/site42 && docker-compose logs -f traefik'

# Specific service logs
ssh root@HETZNER_IP 'cd /opt/site42 && docker-compose logs -f backend'
```

### Check Domain Resolution

```bash
# Verify domains resolve to VPS IP
nslookup api.hub42.app
nslookup crm.hub42.app
```

### Restart a Service

```bash
ssh root@HETZNER_IP 'cd /opt/site42 && docker-compose restart backend'
```

### Check SSL Certificates

```bash
ssh root@HETZNER_IP 'ls -la /opt/site42/traefik/acme.json'
```

## GitHub Secrets Setup (Script)

```bash
#!/bin/bash

ORG="your-org-name"
SSH_KEY=$(cat ~/.ssh/id_rsa)
HETZNER_IP="your.vps.ip"

# Set secrets (requires GitHub CLI)
gh secret set HETZNER_SSH_KEY --org=$ORG --body="$SSH_KEY"
gh secret set HETZNER_HOST --org=$ORG --body="$HETZNER_IP"
gh secret set PROD_DB_PASSWORD --org=$ORG --body="your-db-password"
gh secret set PROD_JWT_SECRET --org=$ORG --body="your-jwt-secret"
```

## Service URLs (Example with hub42.app)

| Service | URL |
|---------|-----|
| Backend API | https://api.hub42.app |
| Business Portal (Staff) | https://crm.hub42.app |
| Customer Portal | https://portal.hub42.app |
| Admin Portal | https://admin.hub42.app |
| Scanner | https://scan.hub42.app |
| Landing Page | https://hub42.app |

## Monitoring

### Prometheus Metrics

If Prometheus is enabled, metrics are available at:
```
https://api.hub42.app/actuator/prometheus
```

### Traefik Dashboard

Optionally enable Traefik dashboard (caution: no auth by default):
```
https://traefik.hub42.app
```

## Related Repositories

- **site42 (main)** — Root documentation and monorepo with all services
- **backend** — Spring Boot 3.4 / Java 21 multi-tenant CRM
- **business-portal** — React 19 + Vite staff portal
- **admin-portal** — React 19 + Vite admin panel
- **customer-portal** — React 19 + Vite customer portal
- **scanner** — React 19 + Vite QR code scanner
- **landing** — React 19 + Vite + GSAP landing page

## Support

See [SETUP_INFRA_REPO.md](./SETUP_INFRA_REPO.md) for detailed setup instructions.

For issues:
1. Check GitHub Actions workflow logs
2. SSH to VPS and review docker-compose logs
3. Verify all GitHub secrets are set correctly
4. Ensure domains are properly resolved and pointing to VPS IP
