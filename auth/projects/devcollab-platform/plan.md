# DevCollab Platform - Authentication Learning Plan (for Claude)

**🎯 Primary Audience**: Claude (AI teaching assistant)
**📋 Purpose**: This is Claude's teaching script. It defines what to teach, when to teach it, and how to guide the user through building production-ready authentication systems.

**How Claude Uses This File**:
1. **Resume teaching** — Read "Session State" to see current sprint and next unchecked item
2. **Teach systematically** — Follow checkboxes sequentially, teaching concepts just-in-time
3. **Track progress** — Check boxes as user completes tasks
4. **Guide implementation** — Walk user through "Implementation Steps" (don't just list them)
5. **Verify work** — Test endpoints, review code, check Docker containers

**How User Uses This File** (secondary):
- See what's coming next
- Track overall progress
- Reference MUST-KNOWs and code examples
- Understand the sprint structure

**Teaching Approach**: Feature-driven sprints based on Plan 8. Each sprint builds working auth features, teaching concepts just-in-time when needed. Mix of Python and TypeScript. Docker from day 1, optional AWS deployment.

**Project Goal**: Build DevCollab Platform - a developer collaboration platform (GitHub-style) with enterprise-grade authentication incorporating patterns from secure vaults and finance apps.

## Architecture Overview

```
Sprint 1: Session + JWT Auth
┌─────────────┐
│ Auth Service│ (Python FastAPI)
│ - Sessions  │
│ - JWT       │
└─────────────┘

Sprint 2: OAuth 2.1 + OIDC
┌──────────────┐    ┌─────────────────┐    ┌──────────────┐
│ Client App   │───>│ OAuth Server    │───>│ Resource     │
│ (TypeScript) │<───│ (TypeScript)    │    │ Server (TS)  │
└──────────────┘    └─────────────────┘    └──────────────┘

Sprint 3: MFA + WebAuthn
┌─────────────┐    ┌──────────────┐
│ MFA Service │    │ WebAuthn     │
│ (Python)    │    │ Client (TS)  │
└─────────────┘    └──────────────┘

Sprint 4: Production
┌───────────────┐   ┌──────────────┐   ┌────────────┐
│ Observability │   │ External IdP │   │ AWS Deploy │
│ (TypeScript)  │   │ Integration  │   │ (Optional) │
└───────────────┘   └──────────────┘   └────────────┘

Sprint 5-7: Advanced (Optional)
┌──────────────┐   ┌──────────────┐   ┌──────────────┐
│ Key Mgmt     │   │ Device Auth  │   │ ABAC + OPA   │
│ JWE + DPoP   │   │ SCIM + PAR   │   │ AppSec       │
│ mTLS         │   │ Back-Channel │   │ Privacy/GDPR │
└──────────────┘   └──────────────┘   └──────────────┘
```

**Core Features (Sprint 0-4)**:
- Session-based and JWT authentication
- OAuth 2.1 Authorization Server (with PKCE)
- OpenID Connect provider
- Resource server with bearer token validation
- MFA (TOTP + WebAuthn/FIDO2)
- Social login integration
- Enterprise SSO (SAML + OIDC)
- Role-based access control (RBAC)
- Observability and security hardening

**Advanced Features (Sprint 5-7 - Optional)**:
- Production key management (JWK rotation, KMS/HSM)
- JWT encryption (JWE) and proof-of-possession (DPoP, mTLS)
- Advanced OAuth flows (PAR, JAR, JARM, Device Authorization)
- SCIM 2.0 provisioning and Back-Channel Logout
- ABAC with policy engines (OPA/Cedar)
- Comprehensive AppSec (SSRF, template injection, XSS hardening)
- Privacy compliance (GDPR, data minimization, right-to-erasure)
- Security testing pipeline (SAST/DAST/SCA)

**Tech Stack**:
- **Sprint 1**: Python 3.12 + FastAPI
- **Sprint 2-4**: TypeScript + Node.js/Express
- **Sprint 5-7**: Mixed (Python + TypeScript + OPA + Vault)
- **Databases**: PostgreSQL (users), Redis (sessions/tokens)
- **Local**: Docker Compose
- **Cloud**: AWS (Cognito, Lambda, API Gateway) - optional

---

## Sprint 0: Foundations & Environment Setup

### Goals
- Install development tools
- Understand Docker workflow
- Practice core auth primitives
- Set up local databases

### Prerequisites
- Docker Desktop installed
- Python 3.12+
- Node.js 20+ and npm
- Git
- Code editor (VS Code recommended)

### Tasks

- [ ] **Verify Docker installation**
  - Run: `docker --version`
  - Run: `docker-compose --version`
  - Start Docker Desktop

- [ ] **Verify Python setup**
  - Run: `python3 --version` (should be 3.12+)
  - Run: `pip3 --version`

- [ ] **Verify Node.js + TypeScript setup**
  - Run: `node --version` (should be 20+)
  - Run: `npm --version`
  - Install TypeScript globally: `npm install -g typescript ts-node`
  - Run: `tsc --version`

- [ ] **Start local databases with Docker**
  - Navigate to `projects/devcollab-platform/`
  - Run: `docker-compose up -d postgres redis`
  - Verify: `docker ps` shows postgres and redis running

### Drills (Python): Password Hashing & JWT

- [ ] **Drill 1: Password hashing with bcrypt**
  - Navigate to `foundations/python-drills/`
  - Create `password_hash.py`
  - Implement: hash password, verify password
  - Libraries: `bcrypt` or `passlib`
  - Test with multiple passwords

- [ ] **Drill 2: JWT creation and validation**
  - Create `jwt_drill.py`
  - Implement: create JWT with claims (sub, exp, iat), verify JWT
  - Libraries: `python-jose` or `PyJWT`
  - Test with expired tokens, wrong signatures

### Drills (TypeScript): Cookies & CSRF

- [ ] **Drill 3: Secure cookie handling**
  - Navigate to `foundations/typescript-drills/`
  - Create `cookies.ts`
  - Implement: set cookie with HttpOnly, Secure, SameSite
  - Library: `cookie` package
  - Test different cookie configurations

- [ ] **Drill 4: CSRF token generation**
  - Create `csrf.ts`
  - Implement: generate CSRF token, validate CSRF token
  - Use crypto.randomBytes for token generation
  - Test token validation flow

### 🚨 MUST-KNOW (Foundation Concepts)

- **Password Storage**: NEVER store plaintext passwords. Use bcrypt/argon2 with salt. Cost factor determines hash time (bcrypt default: 10-12 rounds).
- **JWT Structure**: Header (algorithm) + Payload (claims) + Signature. JWTs are NOT encrypted, just signed. Never put secrets in payload!
- **HttpOnly Cookies**: JavaScript cannot access them (prevents XSS attacks). Must be set server-side.
- **SameSite Cookie Attribute**:
  - `Strict`: Cookie only sent to same site
  - `Lax`: Cookie sent on top-level navigation (default, good for most cases)
  - `None`: Cookie sent everywhere (requires `Secure` flag, HTTPS only)
- **CSRF Attack**: Malicious site tricks browser into making authenticated request. Defense: CSRF tokens, SameSite cookies, origin validation.

### Outcome
✅ **Development environment ready, core auth primitives understood through hands-on practice**

---

## Sprint 1: Session-Based & JWT Authentication

### Goals
- Build authentication service with Python FastAPI
- Implement session-based auth (cookies + server-side storage)
- Implement JWT-based auth (stateless tokens)
- Compare trade-offs between both approaches
- Understand security headers and CORS

### New Technologies
- **FastAPI**: Modern Python web framework with automatic OpenAPI docs
- **PostgreSQL**: Relational database for user storage
- **Redis**: In-memory store for sessions
- **Docker**: Containerization for local development

### 🚨 MUST-KNOW (taught now)

- **Sessions vs JWT**:
  - **Sessions**: Server stores session ID → Redis/DB. Pros: Easy revocation, smaller cookies. Cons: Server state, Redis dependency.
  - **JWT**: Token contains all data, signed by server. Pros: Stateless, scales horizontally. Cons: Hard to revoke, larger payload, token theft risk.
  - **When to use**: Sessions for traditional web apps, JWT for APIs/microservices.

- **Token Expiration Strategy**:
  - **Access tokens**: Short-lived (5-15 min). Frequently used, higher theft risk.
  - **Refresh tokens**: Long-lived (days/weeks). Used rarely, stored securely.
  - **Rotation**: Issue new refresh token on each use, invalidate old one.

- **Security Headers**:
  - `Strict-Transport-Security` (HSTS): Force HTTPS
  - `X-Content-Type-Options: nosniff`: Prevent MIME-type sniffing
  - `X-Frame-Options: DENY`: Prevent clickjacking
  - `Content-Security-Policy` (CSP): Restrict resource loading

- **CORS Basics**:
  - Browsers block cross-origin requests by default
  - Server must send `Access-Control-Allow-Origin` header
  - Credentials require `Access-Control-Allow-Credentials: true`
  - Preflight requests (OPTIONS) for non-simple requests

### Essential FastAPI Patterns

```python
from fastapi import FastAPI, Depends, HTTPException, status
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from pydantic import BaseModel

app = FastAPI()

# Pydantic models for request/response
class UserSignup(BaseModel):
    email: str
    password: str

class UserLogin(BaseModel):
    email: str
    password: str

class TokenResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"

# Dependency for JWT auth
security = HTTPBearer()

async def get_current_user(credentials: HTTPAuthorizationCredentials = Depends(security)):
    token = credentials.credentials
    # Verify JWT here
    user_id = verify_jwt(token)
    if not user_id:
        raise HTTPException(status_code=401, detail="Invalid token")
    return user_id

# Protected route
@app.get("/api/me")
async def get_me(user_id: str = Depends(get_current_user)):
    return {"user_id": user_id}
```

### Implementation Steps

- [ ] **Create FastAPI project structure**
  - Navigate to `projects/devcollab-platform/auth-service/`
  - Create `app/main.py` (FastAPI app)
  - Create `app/models.py` (Pydantic models)
  - Create `app/database.py` (DB connection)
  - Create `app/auth.py` (auth utilities)
  - Create `requirements.txt` with dependencies

- [ ] **Set up database models (PostgreSQL)**
  - Create `users` table: id, email (unique), password_hash, created_at
  - Use SQLAlchemy or raw SQL
  - Connection string from environment variable

- [ ] **Implement user signup (`POST /auth/signup`)**
  - Input: `{ "email": "user@example.com", "password": "SecurePass123!" }`
  - Hash password with bcrypt (12 rounds)
  - Store in PostgreSQL
  - Return: `{ "user_id": "...", "email": "..." }`

- [ ] **Implement session-based login (`POST /auth/login/session`)**
  - Input: `{ "email": "...", "password": "..." }`
  - Verify password against hash in DB
  - Generate session ID (UUID)
  - Store session in Redis: `session:{session_id} → {user_id, created_at}`
  - Set cookie: `Set-Cookie: session_id=...; HttpOnly; Secure; SameSite=Lax; Max-Age=86400`
  - Return: `{ "message": "Logged in" }`

- [ ] **Implement session validation middleware**
  - Read `session_id` from cookie
  - Look up session in Redis
  - If valid: attach user_id to request context
  - If invalid/expired: return 401

- [ ] **Implement JWT-based login (`POST /auth/login/jwt`)**
  - Input: `{ "email": "...", "password": "..." }`
  - Verify password
  - Generate access token (JWT):
    - Claims: `{ "sub": user_id, "email": email, "exp": now + 15min, "iat": now }`
    - Sign with HS256 (or RS256 for production)
  - Generate refresh token (JWT or random string)
  - Store refresh token in Redis: `refresh:{token} → {user_id}`
  - Return: `{ "access_token": "...", "refresh_token": "...", "token_type": "bearer" }`

- [ ] **Implement JWT validation middleware**
  - Read `Authorization: Bearer <token>` header
  - Verify JWT signature
  - Check expiration (`exp` claim)
  - Extract user_id from `sub` claim
  - Attach to request context

- [ ] **Implement token refresh (`POST /auth/refresh`)**
  - Input: `{ "refresh_token": "..." }`
  - Validate refresh token in Redis
  - Issue new access token
  - Rotate refresh token (optional but recommended)
  - Return new tokens

- [ ] **Implement logout**
  - Session-based: Delete session from Redis, clear cookie
  - JWT-based: Add refresh token to blacklist in Redis (access tokens expire naturally)

- [ ] **Add security headers middleware**
  - HSTS, X-Content-Type-Options, X-Frame-Options, CSP
  - Use `fastapi.middleware.cors.CORSMiddleware` for CORS

- [ ] **Create Dockerfile for auth-service**
  ```dockerfile
  FROM python:3.12-slim
  WORKDIR /app
  COPY requirements.txt .
  RUN pip install --no-cache-dir -r requirements.txt
  COPY app/ ./app/
  CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]
  ```

- [ ] **Test with curl/Postman**
  - Signup: `POST /auth/signup`
  - Login (session): `POST /auth/login/session` → get cookie
  - Protected route with session: `GET /api/me` with cookie
  - Login (JWT): `POST /auth/login/jwt` → get tokens
  - Protected route with JWT: `GET /api/me` with `Authorization: Bearer <token>`
  - Refresh tokens: `POST /auth/refresh`
  - Logout

### Real-World Extras

- [ ] **Add email verification flow**
  - On signup, send verification email with signed token
  - User clicks link, token verified, account activated
  - Store `email_verified` boolean in DB

- [ ] **Add password reset flow**
  - User requests reset: `POST /auth/reset-password-request`
  - Generate signed reset token (expires in 1 hour)
  - Send email with link
  - User submits new password: `POST /auth/reset-password`
  - Verify token, update password hash

- [ ] **Add rate limiting**
  - Limit login attempts (5 per 15 min per IP)
  - Use Redis for rate limit counters
  - Return 429 Too Many Requests

- [ ] **Add account lockout**
  - After 5 failed login attempts, lock account for 30 min
  - Store failed attempt count in Redis

### Security Hardening (Critical - Should Do)

- [ ] **Prevent SQL Injection**
  - Use parameterized queries for all database operations
  - NEVER concatenate user input into SQL strings
  - Test: Try login with `admin' OR '1'='1` as password
  - Use SQLAlchemy ORM or prepared statements with psycopg2
  - Example vulnerable code: `f"SELECT * FROM users WHERE email = '{email}'"`
  - Example safe code: `session.query(User).filter_by(email=email).first()`

- [ ] **Session Fixation Defense Drill**
  - Regenerate session ID after successful login
  - Clear old session, create new one with same data
  - Test: Obtain session ID before login, try to use it after someone else logs in
  - Flask: `session.regenerate()`, Express: `req.session.regenerate()`
  - Why: Prevents attacker from hijacking session by setting victim's session ID

- [ ] **JWT Algorithm Validation**
  - Explicitly specify `algorithm=['HS256']` or `['RS256']` when verifying
  - NEVER allow `algorithm='none'` (attacker can forge unsigned tokens)
  - Reject tokens with `alg: none` header
  - Test: Create token with `{"alg": "none", "typ": "JWT"}` header, try to use it
  - Verify server rejects it with 401 Unauthorized

### Outcome
✅ **Working authentication service with both session and JWT approaches, understanding trade-offs, and critical security gaps addressed**

---

## Sprint 2: OAuth 2.1 + OpenID Connect

### Goals
- Build OAuth 2.1 Authorization Server (TypeScript)
- Build Resource Server (protected API)
- Build Client Application (SPA with PKCE)
- Implement Authorization Code Grant with PKCE
- Add OpenID Connect layer (ID tokens, UserInfo endpoint)
- Understand the complete OAuth flow

### New Technologies
- **TypeScript**: Type-safe JavaScript
- **Express.js**: Node.js web framework
- **jose**: JavaScript library for JWT/JWS/JWE
- **React/Vue**: SPA framework (optional, can use vanilla JS)

### 🚨 MUST-KNOW (taught now)

- **OAuth 2.1 vs OAuth 2.0**:
  - OAuth 2.1 = OAuth 2.0 + security best practices
  - Mandates PKCE for all clients (not just public clients)
  - Removes implicit grant (insecure)
  - Removes resource owner password grant (phishing risk)
  - Requires exact redirect URI matching

- **OAuth Roles**:
  - **Resource Owner**: User who owns the data
  - **Client**: App requesting access (DevCollab web app)
  - **Authorization Server**: Issues tokens (what we're building)
  - **Resource Server**: Hosts protected resources (our API)

- **Authorization Code Grant Flow**:
  1. Client redirects user to authorization server: `/authorize?client_id=...&redirect_uri=...&response_type=code&code_challenge=...`
  2. User authenticates and consents
  3. Authorization server redirects back with code: `redirect_uri?code=ABC123`
  4. Client exchanges code for tokens: `POST /token` with `code` and `code_verifier`
  5. Authorization server returns access token (+ refresh token, + ID token if OIDC)

- **PKCE (Proof Key for Code Exchange)**:
  - Prevents authorization code interception attacks
  - Client generates random `code_verifier` (43-128 chars)
  - Client computes `code_challenge = BASE64URL(SHA256(code_verifier))`
  - Authorization server stores `code_challenge` with auth code
  - On token exchange, client sends `code_verifier`
  - Server verifies: `SHA256(code_verifier) == code_challenge`

- **OAuth Scopes**:
  - Limit what client can access: `read:profile`, `write:repos`, `admin:org`
  - User consents to specific scopes
  - Access token includes granted scopes

- **OpenID Connect (OIDC)**:
  - Identity layer on top of OAuth 2.0
  - Adds `openid` scope and ID token (JWT with user claims)
  - ID token claims: `sub` (user ID), `email`, `email_verified`, `name`, `picture`
  - UserInfo endpoint: `GET /userinfo` with access token → user profile
  - Discovery: `GET /.well-known/openid-configuration` → metadata

- **Tokens Explained**:
  - **Authorization Code**: Short-lived (1-10 min), single-use, exchanged for tokens
  - **Access Token**: Bearer token for API access (15 min - 1 hour)
  - **Refresh Token**: Long-lived (days/weeks), used to get new access tokens
  - **ID Token**: JWT with user identity claims (OIDC only)

### Essential TypeScript/Express Patterns

```typescript
import express, { Request, Response } from 'express';
import { SignJWT, jwtVerify } from 'jose';

const app = express();
app.use(express.json());

// Type-safe request handler
interface AuthRequest extends Request {
  user?: { userId: string; email: string };
}

// JWT verification middleware
async function verifyToken(req: AuthRequest, res: Response, next: Function) {
  const authHeader = req.headers.authorization;
  if (!authHeader?.startsWith('Bearer ')) {
    return res.status(401).json({ error: 'Missing token' });
  }

  const token = authHeader.substring(7);
  try {
    const { payload } = await jwtVerify(token, secret);
    req.user = { userId: payload.sub!, email: payload.email as string };
    next();
  } catch (err) {
    res.status(401).json({ error: 'Invalid token' });
  }
}

// Protected route
app.get('/api/profile', verifyToken, (req: AuthRequest, res: Response) => {
  res.json({ user: req.user });
});
```

### Implementation Steps: OAuth Server (TypeScript)

- [ ] **Create TypeScript project structure**
  - Navigate to `projects/devcollab-platform/oauth-server/`
  - Run: `npm init -y`
  - Install dependencies: `npm install express jose cookie-parser cors dotenv uuid`
  - Install dev dependencies: `npm install -D typescript @types/node @types/express @types/cookie-parser ts-node nodemon`
  - Create `tsconfig.json` (target ES2022, strict mode)
  - Create `src/index.ts` (main server)
  - Create `src/db.ts` (database client - PostgreSQL)
  - Create `src/auth.ts` (authorization logic)
  - Create `src/crypto.ts` (PKCE verification, token generation)

- [ ] **Set up database tables**
  - `oauth_clients`: id, client_id, client_secret (nullable), redirect_uris (array), name
  - `authorization_codes`: code, client_id, user_id, redirect_uri, code_challenge, code_challenge_method, scopes, expires_at, used (boolean)
  - `access_tokens`: token (hash), user_id, client_id, scopes, expires_at
  - `refresh_tokens`: token (hash), user_id, client_id, scopes, expires_at

- [ ] **Implement client registration (simplified)**
  - For learning, manually insert a client into `oauth_clients`:
    - `client_id`: "devcollab-web"
    - `redirect_uris`: ["http://localhost:3000/callback"]
    - `name`: "DevCollab Web App"
  - In production, this would be a registration API

- [ ] **Implement `/authorize` endpoint (GET)**
  - Query params: `client_id`, `redirect_uri`, `response_type` (must be "code"), `scope`, `state`, `code_challenge`, `code_challenge_method` (must be "S256")
  - Validate client_id exists
  - Validate redirect_uri matches registered URI (exact match!)
  - Validate code_challenge is present (PKCE required)
  - Check if user is authenticated (cookie from Sprint 1 auth-service)
    - If not: redirect to login page
    - If yes: show consent screen (HTML page listing requested scopes)
  - User approves: generate authorization code
  - Store code in DB with: code_challenge, user_id, client_id, scopes, redirect_uri
  - Redirect to: `{redirect_uri}?code={code}&state={state}`

- [ ] **Implement `/token` endpoint (POST)**
  - Grant types: `authorization_code`, `refresh_token`

  **Authorization Code Grant**:
  - Body: `{ "grant_type": "authorization_code", "code": "...", "redirect_uri": "...", "code_verifier": "...", "client_id": "..." }`
  - Validate code exists and not used
  - Validate redirect_uri matches stored URI
  - Verify PKCE: `SHA256(code_verifier) == code_challenge`
  - Mark code as used
  - Generate access token (JWT):
    - Claims: `{ "sub": user_id, "client_id": client_id, "scope": scopes, "exp": now + 1h }`
    - Sign with RS256 (use private key)
  - Generate refresh token (random 32 bytes, hex encoded)
  - Store tokens in DB
  - If `openid` scope: generate ID token
  - Return: `{ "access_token": "...", "token_type": "bearer", "expires_in": 3600, "refresh_token": "...", "id_token": "..." }`

  **Refresh Token Grant**:
  - Body: `{ "grant_type": "refresh_token", "refresh_token": "..." }`
  - Validate refresh token in DB, not expired
  - Generate new access token (same scopes)
  - Rotate refresh token (optional)
  - Return new tokens

- [ ] **Implement `/userinfo` endpoint (GET)** (OIDC)
  - Requires access token with `openid` scope
  - Extract user_id from access token
  - Fetch user from DB
  - Return: `{ "sub": user_id, "email": "...", "email_verified": true, "name": "..." }`

- [ ] **Implement `/.well-known/openid-configuration` endpoint** (OIDC Discovery)
  - Return metadata:
    ```json
    {
      "issuer": "http://localhost:4000",
      "authorization_endpoint": "http://localhost:4000/authorize",
      "token_endpoint": "http://localhost:4000/token",
      "userinfo_endpoint": "http://localhost:4000/userinfo",
      "jwks_uri": "http://localhost:4000/.well-known/jwks.json",
      "scopes_supported": ["openid", "profile", "email"],
      "response_types_supported": ["code"],
      "grant_types_supported": ["authorization_code", "refresh_token"],
      "code_challenge_methods_supported": ["S256"]
    }
    ```

- [ ] **Implement `/.well-known/jwks.json` endpoint** (Public Keys)
  - Return public key in JWK format (for clients to verify ID tokens)

### Implementation Steps: Resource Server (TypeScript)

- [ ] **Create Resource Server project**
  - Navigate to `projects/devcollab-platform/resource-server/`
  - Set up TypeScript/Express (same as OAuth server)
  - Create `src/index.ts`
  - Create `src/middleware/auth.ts` (JWT verification)

- [ ] **Implement JWT verification middleware**
  - Read `Authorization: Bearer <token>`
  - Fetch public key from OAuth server's JWKS endpoint
  - Verify JWT signature with public key
  - Check `exp`, `iss`, `aud` claims
  - Extract `sub` (user_id) and `scope`
  - Attach to request context

- [ ] **Create protected API endpoints**
  - `GET /api/repos` - List user's repositories
  - `POST /api/repos` - Create repository (requires `write:repos` scope)
  - `GET /api/profile` - Get user profile (requires `read:profile` scope)

- [ ] **Implement scope checking**
  - Middleware to check if token has required scope
  - Example: `requireScope('write:repos')`

### Implementation Steps: Client Application (TypeScript)

- [ ] **Create client app (SPA)**
  - Navigate to `projects/devcollab-platform/client-app/`
  - Set up: Vanilla TypeScript or React/Vue (your choice)
  - Create login page

- [ ] **Implement OAuth PKCE flow**
  - Generate `code_verifier`: `crypto.randomBytes(32).toString('base64url')`
  - Compute `code_challenge`: `SHA256(code_verifier)` base64url-encoded
  - Store `code_verifier` in sessionStorage
  - Redirect user to authorization server:
    ```
    GET /authorize?
      response_type=code&
      client_id=devcollab-web&
      redirect_uri=http://localhost:3000/callback&
      scope=openid profile email read:repos write:repos&
      state={random_string}&
      code_challenge={code_challenge}&
      code_challenge_method=S256
    ```

- [ ] **Implement callback handler**
  - Extract `code` and `state` from URL query params
  - Verify `state` matches (CSRF protection)
  - Retrieve `code_verifier` from sessionStorage
  - Exchange code for tokens:
    ```typescript
    POST /token
    {
      "grant_type": "authorization_code",
      "code": code,
      "redirect_uri": "http://localhost:3000/callback",
      "client_id": "devcollab-web",
      "code_verifier": code_verifier
    }
    ```
  - Store `access_token` and `refresh_token` (in memory or sessionStorage)
  - Decode ID token, display user info
  - Redirect to dashboard

- [ ] **Implement API calls with access token**
  - Fetch user's repos: `GET /api/repos` with `Authorization: Bearer {access_token}`
  - Display results

- [ ] **Implement token refresh**
  - When access token expires (401 response), use refresh token
  - `POST /token` with `grant_type=refresh_token`
  - Retry original request with new access token

### Docker Setup

- [ ] **Create Dockerfile for each service**
  - oauth-server, resource-server, client-app
  - Use multi-stage builds for TypeScript compilation

- [ ] **Update docker-compose.yml**
  - Add oauth-server, resource-server, client-app services
  - Expose ports: oauth-server (4000), resource-server (5000), client-app (3000)
  - Add environment variables

- [ ] **Test complete OAuth flow**
  - `docker-compose up`
  - Navigate to http://localhost:3000
  - Click "Login with DevCollab"
  - Authorize scopes
  - Redirected back with user info
  - Access protected API

### Real-World Extras

- [ ] **Add consent screen customization**
  - Show client logo, description
  - Allow user to deselect specific scopes

- [ ] **Implement token introspection endpoint** (`POST /introspect`)
  - Resource server can validate opaque tokens
  - Returns token metadata: active, scope, user_id

- [ ] **Add token revocation endpoint** (`POST /revoke`)
  - User can revoke access/refresh tokens
  - Client can revoke its own tokens

- [ ] **Implement dynamic client registration** (OAuth 2.0 DCR)
  - `POST /register` - Register new OAuth client programmatically

### Advanced OAuth Patterns (Should Do for Production Knowledge)

- [ ] **Client Credentials Grant (Service-to-Service)**
  - Add `grant_type=client_credentials` support to token endpoint
  - Input: `{ "grant_type": "client_credentials", "client_id": "...", "client_secret": "...", "scope": "api:read" }`
  - No user context - token represents the client itself
  - Use case: Microservice A needs to call Microservice B's API
  - Issued token has shorter lifetime (1 hour typical)
  - Include client_id in token claims, no `sub` (subject) claim

- [ ] **DPoP (Demonstrating Proof-of-Possession) - Introduction**
  - Problem: Bearer tokens can be stolen and replayed
  - DPoP binds token to client's private key
  - Client generates key pair, sends public key hash with auth request
  - Each API request includes DPoP proof (JWT signed by client's private key)
  - Server verifies: token + DPoP proof match
  - Prevents token theft (attacker doesn't have private key)
  - Note: Full implementation in Sprint 5, this is conceptual intro

### Outcome
✅ **Complete OAuth 2.1 + OIDC implementation with authorization server, resource server, and client, understanding the full flow, plus service-to-service auth**

---

## Sprint 3: Real-World Security Hardening

### Goals
- Implement Multi-Factor Authentication (TOTP + WebAuthn)
- Add device/session management
- Implement RBAC (Role-Based Access Control)
- Add security monitoring and audit logs
- Handle password policies and account security

### New Technologies
- **TOTP**: Time-based One-Time Password (Google Authenticator)
- **WebAuthn**: Web Authentication API (FIDO2, security keys, biometrics)
- **Redis**: Session tracking and rate limiting

### 🚨 MUST-KNOW (taught now)

- **MFA (Multi-Factor Authentication)**:
  - **Something you know**: Password
  - **Something you have**: Phone (TOTP), Security key (WebAuthn)
  - **Something you are**: Biometric (fingerprint, face)
  - Always use 2+ factors for sensitive operations

- **TOTP Algorithm**:
  - Secret shared between server and client (QR code)
  - Code = HMAC-SHA1(secret, time_step)
  - Time step = floor(current_time / 30 seconds)
  - 6-digit code changes every 30 seconds
  - Server validates current window ± 1 (90 second window)

- **WebAuthn/FIDO2**:
  - Public key cryptography (no shared secrets!)
  - Enrollment: device generates key pair, sends public key to server
  - Authentication: server sends challenge, device signs with private key
  - Phishing-resistant (origin binding)
  - Supports platform authenticators (Touch ID, Face ID, Windows Hello) and roaming (YubiKey, Titan)

- **Backup Codes**:
  - One-time recovery codes (usually 10-12)
  - Used if MFA device is lost
  - Each code can be used once
  - Store hashed in database

- **Step-Up Authentication**:
  - Require re-authentication for sensitive actions (delete account, change password)
  - Short-lived "elevated" session (e.g., 15 min)
  - Even if user has valid session

- **RBAC vs ABAC**:
  - **RBAC**: User → Role → Permissions (e.g., Admin can delete_repo)
  - **ABAC**: Policy-based (e.g., user.id == resource.owner_id OR user.role == 'admin')
  - RBAC simpler, ABAC more flexible

### Implementation Steps: TOTP MFA (Python)

- [ ] **Create MFA service**
  - Navigate to `projects/devcollab-platform/mfa-service/`
  - Set up Python FastAPI project
  - Install: `pyotp`, `qrcode`, `pillow`

- [ ] **Implement TOTP enrollment**
  - `POST /mfa/enroll/totp`
  - Generate secret: `pyotp.random_base32()`
  - Create provisioning URI: `pyotp.totp.TOTP(secret).provisioning_uri(email, issuer_name='DevCollab')`
  - Generate QR code image
  - Store secret in DB (encrypted!): `user_mfa` table
  - Return QR code image + backup codes (10 random 8-char codes, hashed)

- [ ] **Implement TOTP verification**
  - `POST /mfa/verify/totp`
  - Input: `{ "user_id": "...", "code": "123456" }`
  - Retrieve secret from DB
  - Verify: `pyotp.TOTP(secret).verify(code, valid_window=1)`
  - If valid: mark MFA as verified, return success
  - Rate limit: 5 attempts per 15 min

- [ ] **Integrate MFA into login flow**
  - After password verification, check if user has MFA enabled
  - If yes: return `{ "mfa_required": true, "mfa_token": temporary_token }`
  - User submits code: `POST /auth/login/mfa` with `{ "mfa_token": "...", "code": "..." }`
  - Verify code, issue session/JWT

- [ ] **Implement backup code verification**
  - User can use backup code instead of TOTP
  - Mark backup code as used (prevent reuse)
  - Warn user: "X backup codes remaining"

### Implementation Steps: WebAuthn (TypeScript)

- [ ] **Create WebAuthn client integration**
  - Navigate to `projects/devcollab-platform/client-app/`
  - Install: `@simplewebauthn/browser` and `@simplewebauthn/server`
  - Server-side: Express routes in oauth-server or new service

- [ ] **Implement WebAuthn registration**
  - Client requests registration options: `GET /webauthn/register/options`
  - Server generates challenge, returns options:
    ```typescript
    {
      challenge: randomBytes(32),
      rp: { name: "DevCollab", id: "localhost" },
      user: { id: userId, name: email, displayName: name },
      pubKeyCredParams: [{ alg: -7, type: "public-key" }], // ES256
      authenticatorSelection: { userVerification: "preferred" }
    }
    ```
  - Store challenge in session/Redis
  - Client calls `navigator.credentials.create()` with options
  - User authenticates (Touch ID, security key, etc.)
  - Client sends credential to server: `POST /webauthn/register/verify`
  - Server verifies attestation, stores public key and credential ID in DB

- [ ] **Implement WebAuthn authentication**
  - Client requests auth options: `GET /webauthn/login/options`
  - Server generates challenge, retrieves user's credential IDs
  - Client calls `navigator.credentials.get()`
  - User authenticates with device
  - Client sends assertion to server: `POST /webauthn/login/verify`
  - Server verifies signature using stored public key
  - Issue session/JWT on success

### Implementation Steps: RBAC

- [ ] **Define roles and permissions**
  - Roles: `user`, `maintainer`, `admin`
  - Permissions: `read:repos`, `write:repos`, `delete:repos`, `manage:users`
  - DB tables: `roles`, `permissions`, `role_permissions`, `user_roles`

- [ ] **Assign roles to users**
  - Default: new users get `user` role
  - API endpoint: `POST /admin/users/{id}/roles` (admin only)

- [ ] **Implement permission checking middleware**
  - Decorator/middleware: `@require_permission('delete:repos')`
  - Query user roles → permissions
  - If user lacks permission: return 403 Forbidden

- [ ] **Add to JWT claims**
  - Include roles/permissions in access token
  - Resource server can check permissions without DB query
  - Keep payload size reasonable (don't embed all permissions)

### Implementation Steps: Security Features

- [ ] **Device/Session Management**
  - Track active sessions: browser, OS, location, IP, last accessed
  - API: `GET /account/sessions` - list active sessions
  - API: `DELETE /account/sessions/{id}` - revoke session
  - Store in Redis or DB

- [ ] **Suspicious Activity Detection**
  - Log login attempts: IP, user agent, timestamp, success/failure
  - Alert on: login from new location, multiple failed attempts, impossible travel
  - Rate limit login attempts per IP and per user

- [ ] **Password Policy Enforcement**
  - Minimum 12 characters (configurable)
  - Require: uppercase, lowercase, number, special char
  - Check against common password lists (pwned passwords API)
  - Enforce password expiration (optional, controversial)

- [ ] **Audit Logging**
  - Log sensitive actions: login, logout, password change, MFA enrollment, role change, data access
  - Store: user_id, action, timestamp, IP, user_agent, result
  - Immutable logs (append-only)
  - Retention policy (e.g., 90 days)

### Real-World Extras

- [ ] **Account Recovery Flow**
  - User lost MFA device: verify identity (email + security questions), reset MFA
  - Admin intervention for high-value accounts

- [ ] **Trusted Devices**
  - After MFA verification, mark device as trusted (30 days)
  - Skip MFA on trusted device (still require password)
  - Store device fingerprint (hashed) in DB

- [ ] **Anomaly Detection**
  - Machine learning model for detecting account takeover
  - Features: login time, location, device, behavior patterns

### Enhanced Session & Access Control (Should Do)

- [ ] **Multi-Session Management & Global Logout**
  - Track ALL user sessions across devices (web, mobile, desktop)
  - Store: session_id, user_id, device_fingerprint, ip, location, created_at, last_active
  - API: `GET /account/sessions` - returns all active sessions with details
  - API: `DELETE /account/sessions` - logout from ALL devices (global logout)
  - API: `DELETE /account/sessions/{session_id}` - logout specific device
  - Use case: "I lost my phone, logout everywhere except this browser"
  - Implementation: On global logout, blacklist all existing session/refresh tokens

- [ ] **Refresh Token Rotation with "Rogue RT" Detection**
  - On every refresh, issue new refresh token AND revoke old one
  - Store refresh token family tree: `{ token_id: parent_token_id, issued_at, used: false }`
  - If old (used) refresh token is reused → token theft detected
  - Response: Revoke ENTIRE token family, force user re-login, send security alert
  - Test: Use same refresh token twice, verify all tokens revoked

- [ ] **ABAC (Attribute-Based Access Control) - Introduction**
  - Beyond roles: make decisions based on attributes
  - Example policy: `user.department == 'engineering' AND resource.confidentiality_level <= user.clearance_level`
  - Use case: Dynamic permissions (not just "admin can delete")
  - Attributes: user attributes (role, department, clearance), resource attributes (owner, sensitivity), context (time, IP)
  - Note: Full ABAC with OPA/Cedar in Sprint 6

### Outcome
✅ **Production-grade security: MFA, WebAuthn, RBAC, audit logs, multi-session management, global logout, and refresh token theft detection**

---

## Sprint 4: Productionizing & Advanced Integration

### Goals
- Add comprehensive observability (logs, metrics, tracing)
- Integrate with external Identity Provider (SSO)
- Implement SAML 2.0 for enterprise SSO
- Add security headers and CSP
- Deploy to AWS (optional)
- Incident response playbooks

### New Technologies
- **Prometheus**: Metrics collection
- **Grafana**: Metrics visualization
- **OpenTelemetry**: Distributed tracing
- **Keycloak/Auth0**: External IdP
- **SAML**: Enterprise SSO protocol
- **AWS Cognito**: Managed auth service

### 🚨 MUST-KNOW (taught now)

- **Observability Pillars**:
  - **Logs**: Discrete events (login attempt, error). Structured JSON.
  - **Metrics**: Aggregated data (login rate, error rate). Time-series.
  - **Traces**: Request flow across services. Distributed tracing.

- **Auth-Specific Metrics**:
  - Login success/failure rate (by method: password, SSO, WebAuthn)
  - Token issuance rate (access, refresh, ID)
  - MFA enrollment rate
  - Session duration (p50, p95, p99)
  - OAuth authorization latency
  - Failed authentication attempts (potential attacks)

- **SAML 2.0**:
  - XML-based SSO protocol (older than OIDC, widely used in enterprises)
  - Roles:
    - **Identity Provider (IdP)**: Authenticates user (Okta, Azure AD)
    - **Service Provider (SP)**: Your app
  - Flow:
    1. User accesses SP → SP redirects to IdP
    2. User authenticates at IdP
    3. IdP sends SAML assertion (XML) to SP
    4. SP validates assertion, creates session
  - SAML vs OIDC: SAML more complex, XML-based, enterprise legacy. OIDC simpler, JSON/JWT, modern.

- **Federation**:
  - Trust relationship between IdP and SP
  - IdP signs assertions, SP verifies with IdP's public key
  - Metadata exchange: IdP publishes metadata XML, SP imports it

- **Key Rotation**:
  - JWT signing keys should rotate regularly (every 90 days)
  - Support multiple active keys (old key valid for 24h during rotation)
  - Publish new keys in JWKS endpoint before rotation
  - Clients cache JWKS, refresh on signature verification failure

- **Security Incident Response**:
  - **Token Leak**: Revoke all tokens for user, force re-login, rotate signing keys
  - **Database Breach**: Force password reset for all users, notify users, audit logs
  - **CSRF Attack**: Review CSRF protection, check logs for unauthorized actions
  - **Brute Force**: Rate limit more aggressively, temporary IP block, notify user

### Implementation Steps: Observability (TypeScript)

- [ ] **Set up structured logging**
  - Library: `winston` or `pino` (faster)
  - Format: JSON with timestamp, level, message, context (user_id, request_id, etc.)
  - Log to stdout (Docker captures logs)
  - Example:
    ```json
    {
      "timestamp": "2025-12-01T10:30:00Z",
      "level": "info",
      "message": "User logged in",
      "user_id": "123",
      "ip": "192.168.1.1",
      "auth_method": "password+totp"
    }
    ```

- [ ] **Add metrics with Prometheus**
  - Library: `prom-client`
  - Metrics to track:
    - `auth_login_total` (counter, labels: method, success/failure)
    - `auth_token_issued_total` (counter, labels: token_type)
    - `auth_session_duration_seconds` (histogram)
    - `auth_requests_total` (counter, labels: endpoint, status_code)
  - Expose `/metrics` endpoint for Prometheus scraping

- [ ] **Implement distributed tracing**
  - Library: `@opentelemetry/sdk-node`
  - Trace spans: incoming request, DB query, external API call, token generation
  - Propagate trace context across services (via headers)
  - Export traces to Jaeger or Zipkin

- [ ] **Create Grafana dashboard**
  - Add Prometheus data source
  - Panels:
    - Login success rate (last 24h)
    - Failed login attempts (alert if spike)
    - Token issuance rate
    - OAuth authorization latency (p95)
    - Active sessions count

- [ ] **Set up alerts**
  - Alert rules in Prometheus:
    - Failed login rate > 10/min for 5 min → potential brute force
    - Error rate > 5% → service degradation
    - Token issuance latency > 500ms → performance issue
  - Notification channels: email, Slack, PagerDuty

### Implementation Steps: SAML SSO Integration

- [ ] **Set up external IdP (Keycloak)**
  - Run Keycloak in Docker: `docker run -p 8080:8080 -e KEYCLOAK_ADMIN=admin -e KEYCLOAK_ADMIN_PASSWORD=admin quay.io/keycloak/keycloak:latest start-dev`
  - Create realm: "devcollab"
  - Create SAML client: "devcollab-sp"
  - Configure client: ACS URL, Entity ID

- [ ] **Implement SAML Service Provider (SP)**
  - Library: `saml2-js` or `passport-saml`
  - Configure SP metadata:
    - Entity ID: `http://localhost:3000/saml/metadata`
    - ACS URL: `http://localhost:3000/saml/acs` (Assertion Consumer Service)
    - Single Logout URL: `http://localhost:3000/saml/slo`
  - Import IdP metadata from Keycloak

- [ ] **Implement SAML login flow**
  - User clicks "Login with SSO"
  - SP generates SAML AuthnRequest (XML), signs it
  - Redirect user to IdP with AuthnRequest: `GET /auth?SAMLRequest=...`
  - User authenticates at IdP
  - IdP redirects to ACS URL with SAML Response: `POST /saml/acs` with `SAMLResponse=...`
  - SP validates assertion:
    - Verify signature (IdP's public key)
    - Check timestamps (not expired, not too old)
    - Validate audience (Entity ID)
    - Extract user attributes (email, name, groups)
  - Create local user (if first time) or update attributes
  - Issue session/JWT

- [ ] **Test SAML flow**
  - Login via Keycloak → redirected to DevCollab with session
  - Single Logout (SLO): logout from DevCollab → logout from Keycloak

### Implementation Steps: AWS Deployment (Optional)

- [ ] **Option 1: Deploy with AWS Cognito**
  - Replace custom auth-service with Cognito User Pool
  - Configure Cognito:
    - User pool with email/password
    - MFA (TOTP, SMS)
    - OAuth 2.0 endpoints
    - Custom domain
  - Integrate:
    - Client app → Cognito Hosted UI
    - Resource server → Cognito JWT verification
  - Benefits: Fully managed, scales automatically, compliance certifications
  - Trade-offs: Less control, vendor lock-in, costs

- [ ] **Option 2: Deploy custom services with SAM**
  - Convert Express apps to Lambda functions
  - Use API Gateway for HTTP endpoints
  - Store sessions/tokens in DynamoDB
  - Use RDS for PostgreSQL (or Aurora Serverless)
  - Create `aws/template.yaml` (SAM):
    - Lambda functions for auth, OAuth, resource server
    - API Gateway with Cognito authorizer or custom Lambda authorizer
    - DynamoDB tables
    - RDS instance
  - Deploy: `sam build && sam deploy --guided`

- [ ] **Configure custom domain**
  - Register domain in Route 53
  - Create ACM certificate
  - Add custom domain to API Gateway
  - Update OAuth redirect URIs

### Implementation Steps: Security Hardening

- [ ] **Content Security Policy (CSP)**
  - Header: `Content-Security-Policy: default-src 'self'; script-src 'self'; style-src 'self' 'unsafe-inline'; img-src 'self' data:; connect-src 'self' https://api.devcollab.com`
  - Prevents XSS by restricting resource loading
  - Test with browser console

- [ ] **Additional Security Headers**
  - `X-Content-Type-Options: nosniff`
  - `X-Frame-Options: DENY`
  - `X-XSS-Protection: 1; mode=block` (legacy, but doesn't hurt)
  - `Referrer-Policy: strict-origin-when-cross-origin`
  - `Permissions-Policy: geolocation=(), microphone=(), camera=()`

- [ ] **Secrets Management**
  - Never commit secrets to Git
  - Use environment variables
  - Production: AWS Secrets Manager, HashiCorp Vault
  - Rotate secrets regularly

- [ ] **Dependency Scanning**
  - Run `npm audit` / `pip-audit` regularly
  - Dependabot alerts on GitHub
  - Update dependencies

### Incident Response Playbooks

- [ ] **Document common incidents**
  - **Leaked Access Token**:
    1. Identify affected user
    2. Revoke token (add to blacklist)
    3. Force logout all sessions
    4. Notify user
    5. Review logs for unauthorized access
    6. Reset user password if suspicious activity

  - **Compromised OAuth Client**:
    1. Revoke client credentials
    2. Invalidate all tokens issued to client
    3. Notify users who authorized the client
    4. Regenerate client secret
    5. Review authorization logs

  - **Mass Brute Force Attack**:
    1. Identify attacking IPs (check logs)
    2. Rate limit aggressively or block IPs
    3. Force MFA for affected accounts
    4. Alert security team
    5. Review for successful logins from attacker IPs

### Real-World Extras

- [ ] **Compliance**
  - GDPR: data export, right to erasure, consent management
  - SOC 2: access controls, audit logs, encryption
  - PCI-DSS: if handling payment (probably not for auth service)

- [ ] **Load Testing**
  - Tool: k6, Apache JMeter
  - Test: 1000 req/s login attempts
  - Measure: latency, error rate, resource usage
  - Identify bottlenecks (DB, Redis, CPU)

- [ ] **Disaster Recovery**
  - Database backups (automated, tested)
  - Multi-region deployment (active-active or active-passive)
  - Runbook for service restoration

### Enhanced Observability & Security Testing (Should Do)

- [ ] **Concrete Anomaly Detection & IR Runbooks**
  - Set up specific alerts:
    - Token replay detection: Same token used from different IPs within 1 min
    - Consent spike: Same user grants consent to 10+ apps in 1 hour
    - Impossible travel: Login from US, then China 30 min later
    - Refresh token reuse: Old refresh token used (rogue RT detection from Sprint 3)
  - Create IR runbook with:
    - Detection criteria
    - Investigation steps (query audit logs, check user history)
    - Mitigation actions (revoke tokens, notify user, block IP)
    - Post-incident steps (key rotation if needed, user notification template)

- [ ] **Security Testing with ZAP/Burp Suite**
  - Install OWASP ZAP or Burp Suite Community Edition
  - Run automated scan against auth endpoints
  - Manual tests:
    - Try SQL injection in login form
    - Test CSRF protection (remove CSRF token, replay requests)
    - Test session fixation (set session ID before login)
    - Test JWT algorithm confusion (change `alg` to `none`)
    - Test authorization bypass (try to access other user's resources)
  - Document findings and fixes in learnings.md

- [ ] **GDPR Compliance Basics**
  - Data minimization: Only store necessary user data
  - Right to access: API endpoint to export user's data as JSON
  - Right to erasure: API endpoint to delete user and all associated data
  - Consent logging: Track when user consented to ToS, Privacy Policy
  - Data retention: Auto-delete old audit logs after 90 days
  - Breach notification: Template email for users if breach occurs

- [ ] **SAML Deep Dive (Beyond Basics)**
  - SP-initiated vs IdP-initiated flows
  - Assertion encryption (not just signing)
  - Clock skew handling (assertions valid ± 5 min)
  - Metadata rollover: Handle when IdP certificate changes
  - Test with real enterprise IdP (Okta, Azure AD free tier)

### Outcome
✅ **Production-ready auth platform with comprehensive observability, concrete security testing, GDPR compliance, SSO depth, and incident response capability**

---

## 🎯 Advanced Sprints (Sprint 5-7) - Optional but Recommended for Production Expertise

The following sprints cover advanced topics that take your auth knowledge from "solid fundamentals" to "production expert level". These are **optional** but highly recommended if you want to:
- Understand enterprise-grade security patterns
- Work on high-security applications (finance, healthcare, government)
- Lead auth architecture discussions
- Pass senior engineer interviews

**Time estimate**: ~12-20 hours total (4-7 hours per sprint, self-paced)

---

## Sprint 5: Advanced Key Management & Token Security

### Goals
- Implement production-grade key management (rotation, KMS/HSM)
- Add JWT encryption (JWE) not just signing (JWS)
- Implement DPoP (Demonstrating Proof-of-Possession)
- Add mTLS certificate-bound tokens
- Defend against algorithm downgrade attacks

### New Technologies
- **AWS KMS / HashiCorp Vault**: Key management services
- **JWE (JSON Web Encryption)**: Encrypt tokens, not just sign them
- **DPoP**: Proof-of-possession for bearer tokens
- **mTLS**: Mutual TLS for client certificate authentication

### 🚨 MUST-KNOW (taught now)

- **JWK (JSON Web Key) Rotation**:
  - Problem: If signing key is compromised, attacker can forge tokens
  - Solution: Rotate keys regularly (every 90 days)
  - Approach: Publish multiple keys in JWKS endpoint with `kid` (key ID)
  - New tokens signed with new key, old key remains valid for grace period (24h)
  - Clients cache JWKS, refresh when they see unknown `kid`

- **KMS vs HSM**:
  - **KMS (Key Management Service)**: Cloud service (AWS KMS, Google Cloud KMS, Azure Key Vault)
  - **HSM (Hardware Security Module)**: Physical device, FIPS 140-2 certified
  - Use case: Store master keys in KMS/HSM, derive signing keys
  - Benefit: Keys never leave secure boundary, audit trail

- **JWE vs JWS**:
  - **JWS (JSON Web Signature)**: Signs payload (anyone can read, can't modify)
  - **JWE (JSON Web Encryption)**: Encrypts payload (only recipient can read)
  - JWE structure: Protected Header + Encrypted Key + IV + Ciphertext + Tag
  - Use case: ID tokens with sensitive PII, refresh tokens stored client-side

- **DPoP (RFC 9449)**:
  - Problem: Bearer tokens can be stolen and replayed
  - Solution: Bind token to client's private key
  - Flow:
    1. Client generates key pair (RS256)
    2. Client sends DPoP proof (JWT with public key JWK) with each request
    3. Server binds access token to public key hash (`cnf` claim)
    4. On API request, server verifies: DPoP proof signature + token's `cnf` matches proof's JWK
  - Attacker who steals token can't use it (doesn't have private key)

- **mTLS Certificate-Bound Tokens**:
  - Similar to DPoP but uses TLS client certificates
  - Token bound to client certificate hash
  - Resource server validates: certificate in TLS handshake matches token's `cnf` claim
  - Use case: Service-to-service auth, high-security APIs

- **Algorithm Downgrade Defenses**:
  - **`none` algorithm attack**: Token with `alg: none` (no signature)
  - **Algorithm confusion**: RS256 token validated as HS256 (public key used as secret)
  - Defense:
    - Explicitly whitelist allowed algorithms
    - Reject `alg: none`
    - Never auto-detect algorithm from token header
    - Verify algorithm matches expected for each key

### Implementation Steps

- [ ] **Set up Key Rotation Infrastructure**
  - Generate multiple RSA key pairs (current + next)
  - Store in files: `private-key-2025-01.pem`, `private-key-2025-02.pem`
  - Publish JWKS with both public keys, each with unique `kid`
  - Sign new tokens with latest key
  - Verify tokens against all valid keys in JWKS
  - Rotate: Move "next" to "current", generate new "next"

- [ ] **Integrate with KMS (AWS KMS or Vault)**
  - Create master key in KMS
  - Use KMS to encrypt/decrypt data encryption keys
  - Envelope encryption pattern:
    - Generate data key (AES-256)
    - Encrypt user data with data key
    - Encrypt data key with KMS master key
    - Store encrypted data + encrypted data key
  - For JWT: Use KMS to sign tokens directly (AWS KMS supports RSA signing)

- [ ] **Implement JWE (Encrypted ID Tokens)**
  - Generate content encryption key (CEK)
  - Encrypt payload with CEK (AES-GCM)
  - Encrypt CEK with recipient's public key (RSA-OAEP)
  - Format: `header.encryptedKey.iv.ciphertext.tag` (base64url)
  - Use case: ID token with SSN, credit card, health data
  - Library: `jose` (TypeScript) or `python-jose` (Python)

- [ ] **Implement DPoP**
  - Client generates RSA key pair on first use
  - On token request, client creates DPoP proof:
    ```typescript
    {
      typ: "dpop+jwt",
      alg: "RS256",
      jwk: { /* client's public key */ }
    }.{
      jti: "random-id",
      htm: "POST",
      htu: "https://auth.example.com/token",
      iat: now
    }
    ```
  - Server validates DPoP proof, adds `cnf` claim to access token:
    ```json
    { "sub": "user123", "cnf": { "jkt": "hash-of-client-public-key" } }
    ```
  - On API request, client sends: `Authorization: DPoP <token>` + `DPoP: <proof>`
  - Resource server verifies: proof signature + proof's JWK hash matches token's `cnf.jkt`

- [ ] **Implement mTLS Certificate-Bound Tokens**
  - Generate client certificate (self-signed for testing)
  - Configure OAuth server to accept mTLS connections
  - Extract certificate from TLS handshake
  - Hash certificate (SHA-256), add to token's `cnf` claim
  - Resource server validates certificate in TLS matches token

- [ ] **Add Algorithm Validation Tests**
  - Test 1: Create token with `alg: none`, verify server rejects
  - Test 2: Create RS256 token, try to verify as HS256, verify server rejects
  - Test 3: Token signed with unknown `kid`, verify server rejects
  - Implementation: Explicitly set `algorithms=['RS256']` in verification

### Real-World Extras

- [ ] **PASETO (Platform-Agnostic Security Tokens)**
  - Alternative to JWT that addresses common pitfalls
  - No algorithm flexibility (version determines algorithm)
  - Mandatory encryption for local tokens
  - Simpler to use securely

- [ ] **Token Binding (RFC 8473)**
  - Browser-based token-to-TLS binding
  - Currently limited browser support
  - Future-proof understanding

### Outcome
✅ **Master-level key management, token encryption, proof-of-possession, and algorithm security - ready for finance/healthcare-grade systems**

---

## Sprint 6: Advanced OAuth Flows & Enterprise Identity

### Goals
- Implement advanced OAuth flows (PAR, JAR, JARM, Device Code)
- Add Dynamic Client Registration
- Implement Back-Channel Logout
- Add SCIM provisioning for user lifecycle
- Deep-dive on enterprise IdP integrations

### New Technologies
- **PAR (Pushed Authorization Requests)**: Push auth params to server before redirect
- **JAR (JWT-secured Authorization Requests)**: Sign authorization requests
- **JARM (JWT-secured Authorization Response Mode)**: Sign authorization responses
- **Device Authorization Grant**: OAuth for CLI tools, smart TVs, IoT
- **SCIM 2.0**: User provisioning and lifecycle management
- **Okta/Azure AD/Cognito**: Enterprise IdP specific features

### 🚨 MUST-KNOW (taught now)

- **PAR (RFC 9126)**:
  - Problem: Authorization request params in URL (visible in browser history, logs)
  - Solution: Client POSTs params to `/as/par` endpoint first
  - Server returns `request_uri` (opaque reference)
  - Client redirects with just: `?client_id=X&request_uri=urn:ietf:params:oauth:request_uri:ABC`
  - Benefits: Privacy, large request support, prevents tampering

- **JAR (RFC 9101)**:
  - Problem: Authorization params can be modified (attacker changes redirect_uri)
  - Solution: Client sends params as signed JWT
  - Server validates JWT signature before processing
  - Combines well with PAR

- **JARM**:
  - Secures the authorization response (code, state) with JWT
  - Server signs response before redirect
  - Client verifies signature
  - Prevents response tampering

- **Device Authorization Grant (RFC 8628)**:
  - Use case: CLI tools, smart TVs, IoT devices (no browser)
  - Flow:
    1. Device requests code: `POST /device_authorization`
    2. Server returns: `device_code`, `user_code`, `verification_uri`
    3. Device shows: "Go to https://example.com/activate and enter code: ABCD-1234"
    4. User visits URL on phone/laptop, enters code, authorizes
    5. Device polls `/token` with `device_code` until user authorizes
  - Used by: AWS CLI, Azure CLI, kubectl, Terraform

- **Dynamic Client Registration (RFC 7591)**:
  - Clients can register themselves programmatically
  - POST to `/register` with client metadata (name, redirect_uris)
  - Server returns `client_id` and optionally `client_secret`
  - Use case: Multi-tenant SaaS where customers bring their own apps

- **Back-Channel Logout (OIDC)**:
  - When user logs out of one app, notify all other apps
  - Server-to-server (back-channel), not redirect-based
  - Flow:
    1. User logs out of App A
    2. App A calls IdP logout endpoint
    3. IdP sends logout tokens (JWT) to all other apps via back-channel
    4. Apps invalidate user's session

- **SCIM 2.0 (System for Cross-domain Identity Management)**:
  - Standard for user provisioning and deprovisioning
  - REST API for user lifecycle: create, read, update, delete users
  - Use case: When employee joins company, provision access to all apps
  - Operations: `POST /Users`, `PATCH /Users/{id}`, `DELETE /Users/{id}`
  - Groups: `POST /Groups`, add users to groups

### Implementation Steps

- [ ] **Implement PAR (Pushed Authorization Requests)**
  - Add `/as/par` endpoint (POST)
  - Input: All authorization parameters (client_id, redirect_uri, scope, code_challenge, etc.)
  - Validate params, store with expiry (60 seconds)
  - Return: `{ "request_uri": "urn:ietf:params:oauth:request_uri:xyz", "expires_in": 60 }`
  - Update `/authorize`: Accept `request_uri` param, lookup stored params

- [ ] **Implement Device Authorization Grant**
  - Add `/device_authorization` endpoint
  - Generate `device_code` (long, random) and `user_code` (short, human-readable like "ABCD-1234")
  - Return: `{ "device_code": "...", "user_code": "ABCD-1234", "verification_uri": "https://auth.example.com/device", "interval": 5 }`
  - Create user-facing page at `/device`: Enter user_code, login, authorize
  - Device polls `/token` with `grant_type=urn:ietf:params:oauth:grant-type:device_code`
  - Return pending until user authorizes, then return tokens

- [ ] **Implement Dynamic Client Registration**
  - Add `/register` endpoint (POST, optionally protected by initial access token)
  - Input: `{ "client_name": "My App", "redirect_uris": ["https://app.example.com/callback"], "grant_types": ["authorization_code"], "response_types": ["code"] }`
  - Validate redirect URIs (HTTPS required, no wildcards)
  - Generate `client_id`, optionally `client_secret`
  - Store in database
  - Return client metadata

- [ ] **Implement Back-Channel Logout**
  - Track which clients user has logged into (store in session/DB)
  - On logout: Generate logout token (JWT with `events` claim)
  - Send logout token to each client's `backchannel_logout_uri` (registered during client registration)
  - Client validates token, terminates user's session

- [ ] **Implement SCIM 2.0 Endpoints**
  - Add `/scim/v2/Users` (GET, POST, PATCH, DELETE)
  - Schema: `{ "schemas": ["urn:ietf:params:scim:schemas:core:2.0:User"], "userName": "john@example.com", "name": { "givenName": "John", "familyName": "Doe" }, "emails": [{ "value": "john@example.com", "primary": true }] }`
  - Filtering: `GET /scim/v2/Users?filter=userName eq "john@example.com"`
  - Add `/scim/v2/Groups` for group management

- [ ] **Integrate with Enterprise IdP (Okta/Azure AD)**
  - Sign up for Okta Developer free tier
  - Configure OIDC application in Okta
  - Implement OIDC client in your app (use Okta as IdP)
  - Test: Login with Okta, receive ID token, display user info
  - Advanced: Add SCIM provisioning (Okta pushes users to your app)

### Real-World Extras

- [ ] **JAR (JWT-secured Authorization Requests)**
  - Client creates JWT with authorization params
  - Signs JWT, sends in `request` param: `/authorize?request=<jwt>`
  - Server validates signature, extracts params

- [ ] **JARM (JWT-secured Authorization Response Mode)**
  - Server creates JWT with authorization response (code, state)
  - Signs JWT, returns in response
  - Client validates signature

- [ ] **Token Introspection at Scale**
  - Implement caching layer (Redis) for introspection results
  - Cache token metadata for TTL
  - Reduce database hits

### Outcome
✅ **Enterprise-ready OAuth expertise: advanced flows, device authorization, SCIM provisioning, and real IdP integrations - ready for B2B SaaS roles**

---

## Sprint 7: AppSec, ABAC, Privacy & Production Hardening

### Goals
- Comprehensive AppSec beyond auth (SSRF, template injection, XSS hardening)
- Implement full ABAC (Attribute-Based Access Control) with policy engine
- Add multi-tenant boundary enforcement
- Implement privacy compliance (GDPR, data minimization, right-to-erasure)
- Add SAST/DAST/SCA to CI pipeline
- Implement secrets management with Vault/KMS

### New Technologies
- **OPA (Open Policy Agent)**: Policy engine for ABAC
- **Cedar/OSO**: Alternative policy languages
- **OWASP ZAP/Burp Suite**: Security testing tools
- **Semgrep/Snyk**: SAST/SCA tools
- **HashiCorp Vault**: Secrets management

### 🚨 MUST-KNOW (taught now)

- **ABAC (Attribute-Based Access Control) Deep Dive**:
  - Policy: `(user.role == "engineer" AND resource.confidentiality <= user.clearance) OR resource.owner == user.id`
  - Attributes:
    - Subject: user.id, user.role, user.department, user.clearance_level
    - Resource: resource.id, resource.owner, resource.confidentiality, resource.created_at
    - Environment: time, IP, location, device
  - Evaluation: Policy Decision Point (PDP) evaluates policy against attributes
  - Use case: Dynamic permissions (not fixed roles)

- **OPA (Open Policy Agent)**:
  - Policy language: Rego (declarative, like Datalog)
  - Example policy:
    ```rego
    package authz
    default allow = false
    allow {
      input.method == "GET"
      input.user.role == "viewer"
    }
    allow {
      input.method == "DELETE"
      input.user.id == input.resource.owner
    }
    ```
  - Integration: Middleware calls OPA API with input, OPA returns allow/deny

- **Multi-Tenant Boundary Enforcement**:
  - Problem: Tenant A shouldn't access Tenant B's data
  - Solution: Every query scoped by `tenant_id`
  - Example: `SELECT * FROM users WHERE tenant_id = ? AND id = ?`
  - Defense: Row-Level Security (RLS) in PostgreSQL
  - Testing: Try to access cross-tenant resources, verify 403

- **SSRF (Server-Side Request Forgery)**:
  - Attack: Attacker tricks server into making requests to internal services
  - Example: `POST /webhook` with `url=http://169.254.169.254/latest/meta-data` (AWS metadata)
  - Defense: Whitelist allowed domains, block private IP ranges, validate URLs

- **Template Injection**:
  - Attack: User input rendered in template engine without escaping
  - Example: `{{ user_input }}` where input is `{{ system('rm -rf /') }}`
  - Defense: Use auto-escaping templates, never eval user input

- **Secrets Management**:
  - Never hardcode secrets in code
  - Use environment variables (12-factor app)
  - Production: Vault/KMS for secrets storage
  - Rotation: Automate secret rotation (DB passwords, API keys)

- **SAST vs DAST vs SCA**:
  - **SAST** (Static Analysis): Analyze source code for vulnerabilities (Semgrep, SonarQube)
  - **DAST** (Dynamic Analysis): Test running app (OWASP ZAP, Burp)
  - **SCA** (Software Composition Analysis): Check dependencies for known vulnerabilities (Snyk, npm audit)

### Implementation Steps

- [ ] **Implement ABAC with OPA**
  - Install OPA: `docker run -p 8181:8181 openpolicyagent/opa run --server`
  - Write policy in Rego (policy.rego)
  - Load policy: `PUT /v1/policies/authz`
  - Middleware: Query OPA with `POST /v1/data/authz/allow`
  - Input: `{ "user": {...}, "resource": {...}, "action": "delete" }`
  - OPA returns: `{ "result": true/false }`

- [ ] **Multi-Tenant Boundary Enforcement**
  - Add `tenant_id` column to all tables
  - Update all queries to include `tenant_id` filter
  - PostgreSQL Row-Level Security (RLS):
    ```sql
    ALTER TABLE users ENABLE ROW LEVEL SECURITY;
    CREATE POLICY tenant_isolation ON users
      USING (tenant_id = current_setting('app.tenant_id')::uuid);
    ```
  - Set tenant context: `SET app.tenant_id = '<tenant-uuid>'`
  - Test: Try cross-tenant access, verify blocked

- [ ] **SSRF Prevention Lab**
  - Create webhook endpoint: `POST /webhook` with `{ "url": "..." }`
  - Intentionally vulnerable: Fetch URL without validation
  - Attack: Try `http://169.254.169.254/latest/meta-data/iam/security-credentials/`
  - Fix: Validate URL, block private IP ranges (10.0.0.0/8, 172.16.0.0/12, 192.168.0.0/16, 127.0.0.0/8, 169.254.0.0/16)
  - Library: Use `ssrf-req-filter` (npm) or implement manually

- [ ] **XSS Hardening Beyond CSP**
  - Test reflected XSS: `GET /search?q=<script>alert(1)</script>`
  - Fix: HTML-escape all user input in templates
  - Test stored XSS: Save `<img src=x onerror=alert(1)>` in profile, view profile
  - Fix: Sanitize on input AND escape on output
  - Use libraries: DOMPurify (JavaScript), Bleach (Python)

- [ ] **Template Injection Lab**
  - Intentionally vulnerable: Render user input in template
  - Template: `Hello {{ user.name }}` where `user.name` comes from input
  - Attack: Input `{{ config.SECRET_KEY }}` or `{{ ''.__class__.__mro__[1].__subclasses__() }}`
  - Fix: Never render untrusted input in template expressions, only in safe contexts

- [ ] **Secrets Management with Vault**
  - Run Vault in Docker: `docker run --cap-add=IPC_LOCK -p 8200:8200 vault server -dev`
  - Store secret: `vault kv put secret/db-password value=supersecret`
  - Read secret: `vault kv get secret/db-password`
  - Integrate with app: Use Vault API to fetch secrets at runtime
  - Rotate: Update secret in Vault, app fetches new value on next request

- [ ] **Add SAST/DAST/SCA to CI**
  - SAST: Add Semgrep to GitHub Actions
    ```yaml
    - uses: returntocorp/semgrep-action@v1
      with:
        config: >-
          p/security-audit
          p/secrets
    ```
  - SCA: Run `npm audit --audit-level=high` in CI, fail build on high/critical
  - DAST: Run OWASP ZAP against staging environment
    ```bash
    docker run -t owasp/zap2docker-stable zap-baseline.py -t https://staging.example.com
    ```

- [ ] **Privacy Compliance Implementation**
  - Data minimization: Audit database schema, remove unnecessary fields
  - Right to access: `GET /api/user/data-export` returns JSON with all user data
  - Right to erasure: `DELETE /api/user/account` deletes user + all associated data
  - Consent logging: Store when user accepted ToS, Privacy Policy (timestamp, version, IP)
  - Data retention: Cron job to delete old audit logs after 90 days
  - Breach notification: Draft email template, test delivery

### Real-World Extras

- [ ] **ReBAC (Relationship-Based Access Control)**
  - Model permissions as graphs (user → owns → resource, user → member_of → group)
  - Use Zanzibar-style systems (Google's internal authz system)
  - Libraries: Ory Keto, SpiceDB

- [ ] **Supply Chain Security**
  - Sign commits with GPG
  - Use lockfiles (package-lock.json, poetry.lock)
  - Verify package signatures (npm, pip)
  - Use private package registry for internal packages

- [ ] **WAF/IDS Integration**
  - CloudFlare WAF for DDoS protection
  - AWS WAF rules for common attacks
  - Fail2ban for brute force protection

### Outcome
✅ **Full-stack security expert: AppSec, ABAC policy engines, multi-tenant isolation, privacy compliance, CI security pipeline - ready for security-critical roles**

---

## 🎓 What You'll Know After Completing This Project

### Authentication & Authorization Mastery

**Session vs JWT**
- ✅ Implement both session-based (cookies + Redis) and JWT-based auth
- ✅ Understand trade-offs: revocation, scalability, token theft, payload size
- ✅ Choose the right approach for different scenarios

**OAuth 2.1 & OpenID Connect**
- ✅ Build complete OAuth 2.1 Authorization Server from scratch
- ✅ Implement Authorization Code Grant with PKCE
- ✅ Generate and validate access tokens, refresh tokens, ID tokens
- ✅ Understand roles: Resource Owner, Client, Authorization Server, Resource Server
- ✅ Implement token rotation and reuse detection
- ✅ Add OpenID Connect layer (ID tokens, UserInfo, Discovery)

**Multi-Factor Authentication**
- ✅ Implement TOTP (Google Authenticator style)
- ✅ Integrate WebAuthn/FIDO2 (security keys, biometrics)
- ✅ Handle backup codes and account recovery

**Enterprise Patterns**
- ✅ Implement SAML 2.0 for enterprise SSO
- ✅ Integrate with external Identity Providers (Keycloak, Okta, Auth0)
- ✅ Understand federated identity and trust relationships

**Access Control**
- ✅ Implement RBAC (Role-Based Access Control)
- ✅ Design permission systems and scopes
- ✅ Enforce authorization at API layer

### Security Skills

**Attack Awareness**
- ✅ Understand common attacks: CSRF, XSS, session fixation, token theft, brute force
- ✅ Implement defenses: CSRF tokens, SameSite cookies, rate limiting, account lockout
- ✅ Security headers: CSP, HSTS, X-Frame-Options

**Secure Development**
- ✅ Password hashing with bcrypt/argon2 (never plaintext!)
- ✅ JWT security: signature verification, expiration, algorithm selection
- ✅ PKCE for preventing authorization code interception
- ✅ Token rotation and refresh token reuse detection
- ✅ Secrets management (environment variables, vaults)

**Cryptography**
- ✅ Symmetric (HS256) vs asymmetric (RS256) signing
- ✅ Public key infrastructure (JWKS, certificate validation)
- ✅ Hashing, salting, key derivation
- ✅ Challenge-response authentication (WebAuthn)

### Technology Skills

**Python + FastAPI**
- ✅ Build high-performance async APIs
- ✅ Pydantic models for validation
- ✅ Dependency injection for middleware
- ✅ Integration with PostgreSQL and Redis

**TypeScript + Node.js**
- ✅ Type-safe Express applications
- ✅ JWT libraries (jose)
- ✅ Cookie and session management
- ✅ OAuth client and server implementation

**Docker & Orchestration**
- ✅ Multi-container applications with Docker Compose
- ✅ Containerize Python and Node.js apps
- ✅ Environment configuration and secrets
- ✅ Networking between services

**Databases**
- ✅ PostgreSQL for persistent data (users, clients, tokens)
- ✅ Redis for ephemeral data (sessions, rate limits, caches)
- ✅ Schema design for auth systems

**AWS (Optional)**
- ✅ Deploy with AWS SAM (Lambda, API Gateway, DynamoDB)
- ✅ Use Cognito as managed auth service
- ✅ Custom domains, ACM certificates, Route 53

### Production Skills

**Observability**
- ✅ Structured logging (JSON, correlation IDs)
- ✅ Metrics collection (Prometheus, Grafana)
- ✅ Distributed tracing (OpenTelemetry)
- ✅ Auth-specific metrics: login rate, token issuance, failures

**Operations**
- ✅ Key rotation procedures
- ✅ Incident response playbooks
- ✅ Audit logging and compliance
- ✅ Session management and revocation

**Testing**
- ✅ Test OAuth flows end-to-end
- ✅ Security testing (token expiration, CSRF, etc.)
- ✅ Load testing authentication systems

### Discussion Fluency

After this project, you can confidently discuss:
- ✅ **Sessions vs JWT**: When to use each, trade-offs, hybrid approaches
- ✅ **OAuth vs OIDC**: Difference, when to use, why OIDC extends OAuth
- ✅ **PKCE**: What it prevents, how it works, why mandatory in OAuth 2.1
- ✅ **Refresh Token Rotation**: Security benefits, reuse detection, implementation
- ✅ **MFA Trade-offs**: TOTP vs WebAuthn, recovery flows, UX considerations
- ✅ **SAML vs OIDC**: Enterprise preferences, complexity, migration paths
- ✅ **JWT Security**: Algorithm confusion, signature bypass, expiration handling
- ✅ **Token Storage**: HttpOnly cookies vs localStorage, XSS vs CSRF risks
- ✅ **Zero Trust**: Verify every request, least privilege, continuous validation

### Advanced Topics (Sprint 5-7 - Optional)

**Advanced Key Management & Token Security (Sprint 5)**
- ✅ Implement JWK rotation with multiple active keys
- ✅ Integrate with KMS/HSM for production key management
- ✅ Add JWE (JWT encryption) for sensitive data
- ✅ Implement DPoP (proof-of-possession) to prevent token theft
- ✅ Add mTLS certificate-bound tokens
- ✅ Defend against algorithm downgrade attacks (none algorithm, algorithm confusion)

**Enterprise OAuth & Identity Management (Sprint 6)**
- ✅ Implement PAR, JAR, JARM (advanced OAuth security)
- ✅ Add Device Authorization Grant (CLI tools, IoT)
- ✅ Implement Dynamic Client Registration
- ✅ Add Back-Channel Logout
- ✅ Implement SCIM 2.0 provisioning
- ✅ Deep integration with enterprise IdPs (Okta, Azure AD)

**AppSec, ABAC & Privacy (Sprint 7)**
- ✅ Comprehensive AppSec testing (SSRF, template injection, XSS hardening)
- ✅ Implement ABAC with OPA/Cedar policy engine
- ✅ Multi-tenant boundary enforcement (RLS in PostgreSQL)
- ✅ GDPR compliance (data minimization, right-to-erasure, consent logging)
- ✅ SAST/DAST/SCA in CI pipeline
- ✅ Production secrets management with Vault/KMS
- ✅ Security testing with ZAP/Burp Suite

### Career-Ready

**After Core Sprints (0-4)**:
- ✅ **Real implementation experience** (not just theory)
- ✅ **Production-quality code** (security, observability, error handling)
- ✅ **Multi-language proficiency** (Python and TypeScript)
- ✅ **End-to-end system design** (from login to audit logs)
- ✅ **Security mindset** (threat modeling, defense-in-depth)

You can join any team building auth systems, evaluate auth vendors, design secure APIs, or architect identity infrastructure.

**After Advanced Sprints (5-7)**:
- ✅ **Expert-level knowledge** ready for senior/staff engineer roles
- ✅ **Finance/healthcare-grade security** (key management, proof-of-possession, encryption)
- ✅ **Enterprise B2B expertise** (SCIM, device flows, advanced OAuth, multi-tenant)
- ✅ **Full-stack security** (AppSec beyond auth, policy engines, privacy compliance)
- ✅ **Security leadership** (architect secure systems, lead security reviews, mentor teams)

You can lead auth architecture, pass senior engineer interviews at FAANG/unicorns, consult on security, or architect identity for regulated industries.

---

## Session State

**Last Updated**: 2025-12-01
**Current Sprint**: Sprint 0 - Foundations & Environment Setup
**Next Step**: Verify Docker installation

**Progress**:
- Total Sprints: 8 (Sprint 0-7)
  - **Core Sprints** (0-4): Fundamentals to production-ready
  - **Advanced Sprints** (5-7): Optional, expert-level topics
- Completed: 0
- Current: Sprint 0 (0/12 tasks complete)
- Optional Extras: Not started
- Advanced Sprints: Not started (will tackle after Sprint 4 if desired)

**Notes**:
- Project just initialized
- User preferences: DevCollab theme, Python + TypeScript, Docker + AWS deployment
- Plan 8 structure adapted to be self-paced
- Sprint 5-7 added after user feedback on missing advanced topics (key management, ABAC, AppSec, privacy)

---

## Teaching Instructions (for Claude)

### 🔄 When Resuming a Session

1. **Read "Session State"** to identify current sprint and next unchecked item
2. **Locate next checkbox** in current sprint
3. **Teach the concept/step**:
   - Start with mental model (1-2 sentences: what it is, why it exists)
   - Show essential code patterns (Python or TypeScript depending on sprint)
   - Teach MUST-KNOWs just-in-time (when user encounters the need)
   - Provide real-world example from DevCollab Platform
   - Explain security implications
4. **Guide user through implementation**:
   - Don't just list steps — walk through them interactively
   - Answer questions as they arise
   - Check for understanding with questions
   - Review code if user shares it
5. **Verify user's work**:
   - Test endpoints with curl/Postman
   - Check Docker containers are running
   - Review logs for errors
   - Test security (try to break the implementation)
6. **Check the box** when user completes the task
7. **Update "Session State"** with progress
8. **Move to next sprint** when all main checkboxes complete (Real-World Extras are optional)

### 📚 Teaching Style (from CLAUDE.md)

- **Fast and effective** - no unnecessary theory, no long essays
- **Practical engineering focus** - always show WHY something matters
- **Just-in-time MUST-KNOWs** - teach concepts when user hits the problem, not upfront
- **Show both languages** - Python examples for Sprint 1 & 3, TypeScript for Sprint 2 & 4
- **Short, direct explanations** - no fluff, no certification-style content
- **Security emphasis** - auth is all about security, always explain the threat model

### 🎯 Sprint Workflow

- **Feature-driven** - each sprint builds a working auth feature
- **Deploy and test** - user should run and test after each sprint
- **Mix languages appropriately** - Python for auth-service/MFA, TypeScript for OAuth/clients
- **Docker from day 1** - always containerize, test with docker-compose
- **Emphasize trade-offs** - sessions vs JWT, TOTP vs WebAuthn, SAML vs OIDC

### ⚠️ Important Reminders

- This file is Claude's script — guide the user, don't just point them to the file
- Be interactive, not prescriptive
- Let user drive pace (don't auto-advance unless asked)
- Real-World Extras are optional (user decides if worth doing)
- Security is paramount — always discuss attack scenarios
- Authentication is complex — expect questions, be patient

### 🎓 Learning Style Notes

- User learns best by building (not reading)
- Mix of languages helps understand auth from multiple perspectives
- Errors are learning opportunities (help debug, explain why it failed)
- Testing is crucial (teach user to verify security properties)

### 📝 Progress Tracking

- Check boxes immediately when task is done
- Update Session State at end of each session
- Note any deviations from plan (user might explore tangents)
- Track optional extras separately

### 🔐 Security Testing

Throughout the project, guide user to:
- Try to bypass authentication (teaches why defenses exist)
- Test with expired tokens
- Attempt CSRF attacks (shows why tokens/SameSite matter)
- Try token replay attacks
- Test rate limiting with multiple failed logins

This hands-on security testing is core to learning auth properly.

---

**End of Teaching Plan**
