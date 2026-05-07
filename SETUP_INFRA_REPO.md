# Setup hub42-infra Repository

This document explains how to create and setup the central infrastructure repository for coordinating deployments across all 6 service repos.

## Overview

`hub42-infra` is a separate GitHub repository that contains:
- `docker-compose.prod.yml` — Production orchestration with Traefik
- `traefik/` — Reverse proxy + SSL configuration
- `scripts/` — Deployment automation
- `.github/workflows/` — GitHub Actions CI/CD pipelines
- Documentation

This repo is used to deploy and manage the entire hub42 SaaS platform on Hetzner.

---

## Step 1: Create Repository on GitHub

### Option A: Via GitHub CLI (Recommended)

```bash
# Install GitHub CLI if you haven't already
# https://cli.github.com

# Authenticate with GitHub
gh auth login

# Create the repository in your GitHub organization
gh repo create hub42-infra \
  --public \
  --source=. \
  --remote=origin \
  --push \
  --org=YOUR_ORG_NAME

# Or if using personal account:
gh repo create hub42-infra --public --source=. --remote=origin --push
```

### Option B: Via GitHub Web UI

1. Go to https://github.com/new
2. Enter repository name: `hub42-infra`
3. Select "Public" (for GitHub Actions to work with free tier)
4. Click "Create repository"
5. Copy the repository URL

---

## Step 2: Prepare Local Repository Structure

```bash
# Create local repo directory
mkdir hub42-infra
cd hub42-infra

# Initialize git
git init
git config user.name "Your Name"
git config user.email "your.email@example.com"

# Create required directories and files
mkdir -p traefik scripts .github/workflows

# Copy files from this root directory
cp ../docker-compose.prod.yml ./
cp ../traefik/traefik.yml ./traefik/
cp ../traefik/.gitignore ./traefik/
cp ../.github-workflows-templates/deploy-cd.yml ./.github/workflows/deploy.yml

# Create scripts
cp ../scripts/setup-server.sh ./scripts/
cp ../scripts/deploy.sh ./scripts/
```

---

## Step 3: Create Documentation

Create these files in the hub42-infra repo:

### .gitignore
```
# Environment variables
.env
.env.local
.env.*.local

# Secrets
*.key
*.pem

# Traefik
traefik/acme.json
traefik/*.log

# IDE
.vscode/
.idea/
*.swp
*.swo
*~

# OS
.DS_Store
Thumbs.db

# Logs
*.log
logs/
```

### README.md
```markdown
# hub42-infra — Deployment & Infrastructure

Central repository for coordinating deployment of hub42 SaaS across all services.

## Quick Start

### 1. Initial Hetzner Setup (One-Time)
\`\`\`bash
ssh root@HETZNER_IP 'bash -s' < scripts/setup-server.sh
\`\`\`

### 2. Copy Configuration to VPS
\`\`\`bash
scp docker-compose.prod.yml root@HETZNER_IP:/opt/hub42/
scp -r traefik/ root@HETZNER_IP:/opt/hub42/
\`\`\`

### 3. Edit Environment Variables
\`\`\`bash
ssh root@HETZNER_IP
nano /opt/hub42/.env
\`\`\`

Set:
- \`DOMAIN=hub42.app\`
- \`GITHUB_ORG=your-github-org\`
- \`DB_PASSWORD=strong-password\`
- \`JWT_SECRET=very-long-random-key-32-chars-minimum\`
- And other secrets from .env.example

### 4. Start Services
\`\`\`bash
cd /opt/hub42
docker-compose pull
docker-compose up -d
\`\`\`

## Directory Structure

\`\`\`
hub42-infra/
├── docker-compose.prod.yml    # Production orchestration
├── traefik/
│   ├── traefik.yml            # Reverse proxy config
│   └── acme.json              # SSL certificates (generated, git-ignored)
├── scripts/
│   ├── setup-server.sh        # Initial VPS setup
│   └── deploy.sh              # Service deployment
├── .github/workflows/
│   └── deploy.yml             # GitHub Actions CD workflow
├── .env.example               # Environment variables template
├── .gitignore
├── README.md                  # This file
└── SETUP_INFRA_REPO.md        # Setup instructions (optional)
\`\`\`

## CI/CD Pipeline

### Per-Service Repos (CI)
Each service repo (backend + 5 frontends) has:
- \`.github/workflows/ci.yml\` → Test, Build Docker image, Push to ghcr.io

### hub42-infra Repo (CD)
- \`.github/workflows/deploy.yml\` → Manual trigger → SSH deploy to Hetzner

## Deployment

### Manual Deployment
\`\`\`bash
# SSH to Hetzner VPS
ssh root@HETZNER_IP

# Update and restart services
cd /opt/hub42
bash deploy.sh [service]    # or just deploy.sh for all
\`\`\`

### GitHub Actions Deployment
1. Go to GitHub → Actions → "Deploy to Production"
2. Click "Run workflow"
3. Select service to deploy (or "all")
4. Click "Run workflow"

## GitHub Secrets (Org-Level)

Configure these in GitHub org settings:

| Secret | Value |
|--------|-------|
| HETZNER_SSH_KEY | Content of ~/.ssh/id_rsa |
| HETZNER_HOST | VPS IP or domain |
| PROD_DB_PASSWORD | PostgreSQL password |
| PROD_JWT_SECRET | JWT signing secret (32+ chars) |
| PROD_SENTRY_DSN | Sentry error tracking DSN |

## Troubleshooting

See [scripts/deploy.sh](./scripts/deploy.sh) for deployment details.

### Check VPS Status
\`\`\`bash
ssh root@HETZNER_IP 'cd /opt/hub42 && docker-compose ps'
\`\`\`

### View Logs
\`\`\`bash
ssh root@HETZNER_IP 'cd /opt/hub42 && docker-compose logs -f traefik'
\`\`\`

## References

- [Root Documentation](https://github.com/ORG/hub42)
- [Backend Repo](https://github.com/ORG/backend)
- [Business Portal Repo](https://github.com/ORG/business-portal)
```

### .env.example
```
# Domain
DOMAIN=hub42.app

# GitHub Organization (for ghcr.io image pulls)
GITHUB_ORG=your-github-org

# Database
DB_USER=hub42_user
DB_PASSWORD=change-this-to-a-strong-password-at-least-16-chars

# JWT
JWT_SECRET=change-this-to-a-very-long-random-string-at-least-32-chars

# Sentry (Error Tracking)
SENTRY_DSN=https://your-sentry-key@sentry.io/project-id
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

# Let's Encrypt / Traefik
ACME_EMAIL=admin@hub42.app

# Timezone
TZ=UTC
```

---

## Step 4: Initialize Git and Push

```bash
cd hub42-infra

# Create initial commit
git add .
git commit -m "Initial commit: hub42 infrastructure setup

- Docker Compose configuration for production
- Traefik reverse proxy with Let's Encrypt SSL
- GitHub Actions CI/CD workflows
- Deployment scripts for Hetzner VPS"

# Add remote origin (replace with your GitHub repo URL)
git remote add origin https://github.com/YOUR_ORG/hub42-infra.git
git branch -M main

# Push to GitHub
git push -u origin main
```

---

## Step 5: Configure GitHub Organization Secrets

1. Go to GitHub → Settings → Secrets and variables → Actions
2. Create org-level secrets:

```
HETZNER_SSH_KEY = (content of ~/.ssh/id_rsa on your machine)
HETZNER_HOST = (IP or domain of your Hetzner VPS)
PROD_DB_PASSWORD = (PostgreSQL password)
PROD_JWT_SECRET = (very long random string, 32+ chars)
PROD_SENTRY_DSN = (optional, from Sentry account)
```

---

## Step 6: Verify GitHub Actions Workflow

1. Go to GitHub → Actions
2. You should see "Deploy to Production" workflow
3. Click it → "Run workflow"
4. Select service and click "Run workflow"
5. Monitor the deployment in the logs

---

## Step 7: Update Root README

In the root `hub42` repository, add links to hub42-infra:

```markdown
# hub42

## Repositories

- [backend](https://github.com/ORG/backend)
- [business-portal](https://github.com/ORG/business-portal)
- [admin-portal](https://github.com/ORG/admin-portal)
- [customer-portal](https://github.com/ORG/customer-portal)
- [scanner](https://github.com/ORG/scanner)
- [landing](https://github.com/ORG/landing)
- **[hub42-infra](https://github.com/ORG/hub42-infra)** — Infrastructure & deployment

## Deployment

See [hub42-infra](https://github.com/ORG/hub42-infra) for production deployment instructions.
```

---

## Complete!

Your infrastructure repository is now ready. Next steps:

1. ✅ Create `hub42-infra` repo on GitHub
2. ✅ Add environment secrets to GitHub org
3. ✅ Test CI workflows in each service repo
4. ✅ Test CD workflow by manually triggering deployment
5. ✅ Monitor first deployment in GitHub Actions logs

For help with deployment, see [scripts/setup-server.sh](./scripts/setup-server.sh) and [scripts/deploy.sh](./scripts/deploy.sh).
