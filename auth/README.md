# Authentication Protocols - Learning Journey

This directory contains my hands-on learning journey for mastering authentication and authorization protocols.

## Project: DevCollab Platform

Building a developer collaboration platform (GitHub-style) with enterprise-grade authentication from scratch. Incorporates high-security patterns from password managers and finance apps.

**Theme**: DevCollab Platform - repos, teams, API tokens, OAuth apps, secrets management

**Approach**: Feature-driven sprints based on [Plan 8](./plans/8.md), using the same structure that worked for [AWS learning](../aws/).

## Architecture

- **Sprint 1**: Session + JWT Authentication (Python + FastAPI)
- **Sprint 2**: OAuth 2.1 + OpenID Connect (TypeScript + Node.js)
- **Sprint 3**: MFA + WebAuthn + RBAC (Python + TypeScript)
- **Sprint 4**: Observability + SSO + Production Hardening (TypeScript)

## Tech Stack

- **Languages**: Python 3.12 (FastAPI), TypeScript (Node.js/Express)
- **Databases**: PostgreSQL (users, clients), Redis (sessions, tokens)
- **Deployment**: Docker Compose (local), AWS SAM (cloud - optional)
- **Auth Protocols**: OAuth 2.1, OpenID Connect, SAML 2.0, WebAuthn/FIDO2

## Project Structure

```
auth/
├── projects/
│   └── devcollab-platform/      # Main learning project
│       ├── plan.md               # Sprint-based teaching plan (Claude's script)
│       ├── auth-service/         # Sprint 1: Python FastAPI
│       ├── oauth-server/         # Sprint 2: TypeScript OAuth server
│       ├── resource-server/      # Sprint 2: Protected API
│       ├── client-app/           # Sprint 2: SPA with PKCE
│       ├── mfa-service/          # Sprint 3: Python TOTP/WebAuthn
│       ├── observability/        # Sprint 4: Metrics, logs, traces
│       ├── foundations/          # Sprint 0: Drills and exercises
│       └── docker-compose.yml    # Local development
├── reference/                    # Auth specs, RFCs, OWASP cheat sheets
├── learnings.md                  # TIL entries (knowledge capture)
├── to-learn.md                   # Queue of future topics
└── CLAUDE.md                     # Teaching instructions for Claude AI

```

## Learning Philosophy

- **Feature-driven, not concept-driven**: Build "login feature" not "learn JWT" then "learn sessions" then build something
- **Just-in-time learning**: Concepts taught when you encounter the problem, not upfront
- **Self-paced**: No week-based deadlines, work at your own speed
- **Both sides of protocols**: Build OAuth provider AND client, SAML IdP AND SP
- **Security-first**: Understanding attacks teaches you why defenses exist
- **Production-ready**: Real-world patterns, not tutorials

## Progress Tracking

Current sprint tracked in `projects/devcollab-platform/plan.md` → Session State section.

Use Claude AI commands:
- `/learn` - Resume teaching from last checkpoint
- `/til <learning>` - Capture a specific learning
- `/later <topic>` - Queue a topic for future exploration

## What I'll Learn

By the end:
- ✅ Build session and JWT auth from scratch
- ✅ Implement OAuth 2.1 Authorization Server with PKCE
- ✅ Add OpenID Connect layer (ID tokens, Discovery, UserInfo)
- ✅ Integrate MFA (TOTP + WebAuthn/FIDO2)
- ✅ Build SAML 2.0 SSO for enterprise
- ✅ Design RBAC permission systems
- ✅ Add production observability (logs, metrics, traces)
- ✅ Understand security trade-offs (sessions vs JWT, TOTP vs WebAuthn, etc.)
- ✅ Discuss auth architecture confidently with colleagues

## Getting Started

1. Navigate to `projects/devcollab-platform/`
2. Read `plan.md` to see current sprint
3. Follow checkboxes sequentially
4. Use `/learn` command with Claude AI to resume teaching

---

**Note**: This is a learning project. Security implementations are educational and may not be production-hardened without additional review.
