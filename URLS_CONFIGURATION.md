# URLs Configuration Guide

## Critical URL Settings

This document explains the two different base URLs used in hub42 configuration and why they must be different.

### `APP_BASE_URL` - CRM Application URL
- **Used for**: Staff/user invitations
- **Default**: `https://crm.hub42.app`
- **Email Template**: `staff-invite.html`
- **Endpoint Pattern**: `/invite/{token}`
- **Purpose**: Users access the CRM application to manage the business

### `PORTAL_BASE_URL` - Customer Portal URL
- **Used for**: Client/customer invitations
- **Default**: `https://portal.hub42.app`
- **Email Template**: `client-invite.html`
- **Endpoint Pattern**: `/client/activate?token={token}`
- **Purpose**: Customers access the portal to view orders and manage their profile

## Environment Files Reference

### Development (local)
```bash
# .env (default localhost)
APP_BASE_URL=http://localhost:5173
PORTAL_BASE_URL=http://localhost:5174

# .env.dev (docker-compose network)
APP_BASE_URL=http://hub42.local:5173
PORTAL_BASE_URL=http://hub42.local:5174
```

### Production
```bash
# .env or .env.prod
APP_BASE_URL=https://crm.hub42.app
PORTAL_BASE_URL=https://portal.hub42.app
```

## Common Mistakes

❌ **Wrong**: Setting both to the same URL
```bash
PORTAL_BASE_URL=https://crm.hub42.app  # INCORRECT!
```

✅ **Correct**: Using different subdomains
```bash
APP_BASE_URL=https://crm.hub42.app
PORTAL_BASE_URL=https://portal.hub42.app
```

## How It's Used

### Backend Email Notification (Java)
Located in: `api/src/main/java/com/saas/shared/infrastructure/email/EmailNotificationListener.java`

```java
// Staff invites → CRM URL
vars.put("baseUrl", baseUrl);  // APP_BASE_URL
emailService.sendHtml(..., "staff-invite.html", vars);

// Client invites → Portal URL
vars.put("portalBaseUrl", portalBaseUrl);  // PORTAL_BASE_URL
emailService.sendHtml(..., "client-invite.html", vars);
```

### Email Templates
- `staff-invite.html`: Uses `${baseUrl}/invite/${token}`
- `client-invite.html`: Uses `${portalBaseUrl}/client/activate?token=${token}`

## Deployment Checklist

Before deploying to production, verify:
- [ ] `APP_BASE_URL` points to CRM domain (e.g., `https://crm.hub42.app`)
- [ ] `PORTAL_BASE_URL` points to Portal domain (e.g., `https://portal.hub42.app`)
- [ ] Both URLs use HTTPS in production
- [ ] Both URLs are properly configured in your reverse proxy (Caddy/Nginx)
- [ ] DNS records point to correct servers if using different hosts
