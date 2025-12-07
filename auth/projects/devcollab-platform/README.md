# DevCollab Platform - Authentication Learning Project

A hands-on, sprint-based project to master authentication and authorization protocols by building a developer collaboration platform (GitHub-style) from scratch.

## Overview

This project teaches auth through **feature-driven development**, not theory-first learning. You'll build:
- User authentication (sessions + JWT)
- OAuth 2.1 Authorization Server with PKCE
- OpenID Connect provider
- Multi-factor authentication (TOTP + WebAuthn)
- SAML 2.0 SSO for enterprise
- Production-grade security and observability

## Architecture

```
┌──────────────┐    ┌──────────────┐    ┌──────────────┐
│  Client App  │───>│ OAuth Server │───>│   Resource   │
│ (TypeScript) │<───│ (TypeScript) │    │ Server (TS)  │
└──────────────┘    └──────────────┘    └──────────────┘
                            │
                            v
                    ┌──────────────┐    ┌──────────────┐
                    │ Auth Service │───>│  PostgreSQL  │
                    │   (Python)   │    │    Redis     │
                    └──────────────┘    └──────────────┘
```

## Tech Stack

- **Backend**: Python 3.12 (FastAPI), TypeScript (Node.js/Express)
- **Frontend**: TypeScript (React/Vue/Vanilla)
- **Databases**: PostgreSQL (persistent), Redis (sessions/tokens)
- **Deployment**: Docker Compose (local), AWS SAM (cloud - optional)
- **Protocols**: OAuth 2.1, OIDC, SAML 2.0, WebAuthn/FIDO2

## Project Structure

```
devcollab-platform/
├── plan.md                  # Sprint-based teaching plan (start here!)
├── docker-compose.yml       # Local development orchestration
├── .env.example             # Environment variables template
│
├── auth-service/            # Sprint 1: Python + FastAPI
│   ├── app/                 #   - Session-based auth
│   ├── Dockerfile           #   - JWT authentication
│   └── requirements.txt     #   - Password hashing, CSRF
│
├── oauth-server/            # Sprint 2: TypeScript + Express
│   ├── src/                 #   - OAuth 2.1 Authorization Server
│   ├── Dockerfile           #   - PKCE implementation
│   ├── package.json         #   - ID tokens (OIDC)
│   └── tsconfig.json        #   - Token rotation
│
├── resource-server/         # Sprint 2: TypeScript + Express
│   └── src/                 #   - Protected API
│                            #   - Bearer token validation
│
├── client-app/              # Sprint 2: TypeScript SPA
│   └── src/                 #   - OAuth PKCE flow
│                            #   - Token management
│
├── mfa-service/             # Sprint 3: Python + FastAPI
│   └── app/                 #   - TOTP (Google Authenticator)
│                            #   - WebAuthn/FIDO2
│                            #   - Backup codes
│
├── observability/           # Sprint 4: TypeScript
│   ├── prometheus.yml       #   - Metrics collection
│   └── grafana/             #   - Dashboards
│
├── foundations/             # Sprint 0: Drills
│   ├── python-drills/       #   - Password hashing
│   └── typescript-drills/   #   - JWT, cookies, CSRF
│
└── aws/                     # Sprint 4: Optional AWS deployment
    └── template.yaml        #   - SAM/CloudFormation
```

## Getting Started

### Prerequisites

- Docker Desktop
- Python 3.12+
- Node.js 20+
- Git

### Quick Start

1. **Start databases**:
   ```bash
   docker-compose up -d postgres redis
   ```

2. **Verify databases are running**:
   ```bash
   docker ps  # Should see postgres and redis containers
   ```

3. **Follow the teaching plan**:
   - Open `plan.md` and read the "Session State" section
   - Start with Sprint 0 (foundations and environment setup)
   - Use `/learn` command with Claude AI to resume teaching

### Development Workflow

Each sprint follows this pattern:

1. **Read the sprint in plan.md** - Understand goals and MUST-KNOWs
2. **Build the feature** - Follow implementation steps (checkboxes)
3. **Test it** - Happy path + security testing (try to break it!)
4. **Update docker-compose.yml** - Uncomment the service for this sprint
5. **Deploy locally** - `docker-compose up <service>`
6. **Verify** - Test endpoints, check logs, review security

## Sprint Overview

### Sprint 0: Foundations (~2-4 hours)
- Environment setup (Docker, Python, Node.js)
- Core drills: password hashing, JWT, cookies, CSRF
- Database setup (PostgreSQL, Redis)

### Sprint 1: Session + JWT Auth (~4-8 hours)
- Build FastAPI auth service
- Implement session-based auth (cookies + Redis)
- Implement JWT-based auth (stateless tokens)
- Compare trade-offs between approaches
- Add security headers and CORS

### Sprint 2: OAuth 2.1 + OIDC (~8-12 hours)
- Build OAuth 2.1 Authorization Server (TypeScript)
- Implement Authorization Code Grant with PKCE
- Add OpenID Connect layer (ID tokens, UserInfo, Discovery)
- Build Resource Server (protected API)
- Build Client App (SPA with PKCE flow)

### Sprint 3: Security Hardening (~6-10 hours)
- Implement TOTP MFA (Google Authenticator)
- Add WebAuthn/FIDO2 (security keys, biometrics)
- Build RBAC system (roles and permissions)
- Add session management and audit logs
- Implement account security features

### Sprint 4: Production & SSO (~6-8 hours)
- Add observability (Prometheus, Grafana, OpenTelemetry)
- Integrate SAML 2.0 for enterprise SSO
- Connect to external IdP (Keycloak)
- Security hardening (CSP, headers, secrets management)
- Optional: Deploy to AWS

## Learning Approach

This project uses **just-in-time learning**:
- Concepts taught when you encounter them (not upfront)
- Build both sides of protocols (provider AND client)
- Security-first mindset (understand attacks, then defenses)
- Testing by breaking (try expired tokens, CSRF attacks, etc.)
- Self-paced (no deadlines, work at your own speed)

## Key Learning Outcomes

By the end, you'll be able to:
- ✅ Implement session and JWT authentication from scratch
- ✅ Build a complete OAuth 2.1 Authorization Server
- ✅ Add OpenID Connect identity layer
- ✅ Integrate MFA (TOTP + WebAuthn)
- ✅ Implement SAML 2.0 SSO for enterprises
- ✅ Design RBAC permission systems
- ✅ Add production observability (logs, metrics, traces)
- ✅ Discuss auth architecture confidently with colleagues
- ✅ Understand security trade-offs (sessions vs JWT, TOTP vs WebAuthn, etc.)

## Resources

- **Teaching Plan**: `plan.md` (your roadmap)
- **Reference Links**: `../../reference/links.md` (RFCs, OWASP, articles)
- **Learning Capture**: `../../learnings.md` (TIL entries via `/til` command)
- **Future Topics**: `../../to-learn.md` (queue via `/later` command)

## Commands (with Claude AI)

- `/learn` - Resume teaching from last checkpoint in plan.md
- `/til <learning>` - Capture a specific learning to learnings.md
- `/later <topic>` - Queue a topic for future exploration

## Troubleshooting

### Database connection issues
```bash
# Check if databases are running
docker ps | grep devcollab

# View logs
docker-compose logs postgres
docker-compose logs redis

# Restart databases
docker-compose restart postgres redis
```

### Port conflicts
If ports 3000, 4000, 5000, 5432, 6379, 8000 are already in use, modify `docker-compose.yml` to use different ports.

### TypeScript compilation errors
```bash
# Reinstall dependencies
cd <service-directory>
rm -rf node_modules package-lock.json
npm install
```

## Security Note

This is a **learning project**. While it teaches production-quality patterns, additional hardening and security review would be needed before deploying to real production environments.

## License

Educational project - feel free to learn from and modify.
