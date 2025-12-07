# Authentication & Security Concepts - Learning Guide

A prioritized table of authentication protocols, security mechanisms, and identity concepts organized by learning path.

---

## 📚 How to Use This Guide

- **⭐ Priority Rating**: 5 stars = learn first, 1 star = specialized/optional
- **Learn After**: Prerequisites you should understand first
- **Learning Phases**: Start with Phase 1, progress through phases based on your needs

---

## Phase 1: Foundations 🎯
*Start here - these are the building blocks of modern authentication*

| Concept | Priority | Category | Quick Description | Where Used | Learn After |
|---------|----------|----------|-------------------|------------|-------------|
| **Session Management** | ⭐⭐⭐⭐⭐ | State | Managing user authentication state via cookies or tokens. Includes secure generation, storage, timeouts. | All web applications | None - start here |
| **Cookies** | ⭐⭐⭐⭐⭐ | State | Client-side storage for session state. Requires HttpOnly, Secure, SameSite flags for security. | Traditional web apps, session management | Session Management |
| **OAuth 2.0** | ⭐⭐⭐⭐⭐ | Protocol | Authorization framework enabling apps to obtain limited access to user accounts without passwords. | Third-party app access, API authorization, "Login with Google" | Session basics |
| **JWT (JSON Web Tokens)** | ⭐⭐⭐⭐⭐ | Token | Self-contained tokens with header, payload, signature. Encoded (not encrypted). Widely used but has security gotchas. | Access tokens, OIDC ID tokens, stateless auth | OAuth 2.0 |
| **OpenID Connect (OIDC)** | ⭐⭐⭐⭐⭐ | Protocol | Identity layer built on OAuth 2.0. Adds authentication to authorization. Uses JWT for ID tokens. | Modern SSO, social login, customer-facing apps | OAuth 2.0, JWT |
| **Authorization Code Grant** | ⭐⭐⭐⭐⭐ | OAuth Flow | Most secure OAuth 2.0 flow. Returns code exchanged for token. Must use with PKCE. | Web apps, mobile apps, most OAuth scenarios | OAuth 2.0 |
| **PKCE** | ⭐⭐⭐⭐⭐ | Security | Proof Key for Code Exchange. Prevents CSRF and code injection in OAuth. Required for public clients, recommended for all. | SPAs, mobile apps, all OAuth flows | OAuth 2.0, Authorization Code Grant |
| **Multi-Factor Auth (MFA)** | ⭐⭐⭐⭐⭐ | Method | Requires multiple verification methods (know/have/are). Critical security layer for modern systems. | All modern auth systems, enterprise SSO | Basic auth concepts |

---

## Phase 2: Web Security Essentials 🔒
*Critical patterns for secure web applications*

| Concept | Priority | Category | Quick Description | Where Used | Learn After |
|---------|----------|----------|-------------------|------------|-------------|
| **CORS** | ⭐⭐⭐⭐⭐ | Security | Cross-Origin Resource Sharing. Enables controlled cross-origin requests. Browsers send OPTIONS preflight. | SPAs with separate API servers, OAuth flows | OAuth 2.0 basics |
| **Refresh Tokens** | ⭐⭐⭐⭐⭐ | Token | Long-lived tokens to obtain new access tokens without re-auth. Should use rotation for security. | Mobile apps, SPAs, maintaining sessions | OAuth 2.0, JWT |
| **Token Rotation** | ⭐⭐⭐⭐⭐ | Security | Each refresh token use generates new tokens and invalidates old ones. Includes reuse detection. | SPAs, mobile apps, OAuth implementations | Refresh Tokens |
| **Bearer Tokens** | ⭐⭐⭐⭐⭐ | Token | Token-based auth in HTTP Authorization header. Modern, scalable. Vulnerable if stolen. | API authentication, OAuth 2.0, microservices | OAuth 2.0 |
| **CSP (Content Security Policy)** | ⭐⭐⭐⭐ | Security | Specifies which resources browsers can load. Prevents XSS by controlling content sources. | XSS prevention, clickjacking protection | Web fundamentals |
| **HSTS** | ⭐⭐⭐⭐ | Security | HTTP Strict Transport Security. Forces HTTPS, prevents protocol downgrades. | All production web apps, compliance | Web deployment basics |
| **SameSite Cookies** | ⭐⭐⭐⭐ | Security | Cookie attribute controlling cross-site behavior. Strict mode = highest protection. Essential for sessions. | Session cookies, CSRF protection | Cookies |
| **RBAC** | ⭐⭐⭐⭐ | Authorization | Role-Based Access Control. Permissions grouped into roles assigned to users. Simple but not fine-grained. | Most applications, enterprise systems | Auth basics |

---

## Phase 3: Enterprise & SSO Patterns 🏢
*Essential for enterprise environments and B2B applications*

| Concept | Priority | Category | Quick Description | Where Used | Learn After |
|---------|----------|----------|-------------------|------------|-------------|
| **Single Sign-On (SSO)** | ⭐⭐⭐⭐⭐ | Pattern | Users access multiple apps with one credential set. Uses SAML or OIDC protocols. | Enterprise apps, suite access (Google Workspace) | OIDC or SAML |
| **SAML 2.0** | ⭐⭐⭐⭐ | Protocol | XML-based protocol for enterprise SSO. IdP authenticates users, informs Service Providers. Mature but heavier than OIDC. | Enterprise B2B SSO, legacy systems, cross-org federation | OIDC (for comparison) |
| **Identity Providers (IdP)** | ⭐⭐⭐⭐ | Infrastructure | Services that create, maintain, manage identity info. Provide auth services to apps (Okta, Auth0, Keycloak, Azure AD). | Enterprise identity, SSO implementation | OIDC and/or SAML |
| **Federated Identity** | ⭐⭐⭐⭐ | Pattern | Users access apps across different organizations. Exchanges auth info via SAML/OAuth. | B2B partnerships, cross-org access | SSO, SAML/OIDC |
| **Client Credentials Grant** | ⭐⭐⭐⭐ | OAuth Flow | For apps acting on own behalf (no user). Client uses ID and secret for token. Server-to-server. | Microservices, background jobs, M2M communication | OAuth 2.0 |
| **Kerberos** | ⭐⭐⭐ | Protocol | Ticket-based network auth using symmetric cryptography. Requires KDC. Default in Windows/AD. | Windows domain auth, enterprise network SSO | Enterprise context |
| **Active Directory / Azure AD** | ⭐⭐⭐ | Infrastructure | Microsoft's IAM system. Integrates Kerberos and LDAP. Default for Windows environments. | Enterprise Microsoft environments, Windows domains | Kerberos, LDAP concepts |
| **LDAP** | ⭐⭐⭐ | Protocol | Lightweight Directory Access Protocol. Directory management that can facilitate auth. Often works with Kerberos. | User directory management, permission lookups | Directory concepts |

---

## Phase 4: Modern & Advanced Security 🚀
*Cutting-edge and specialized authentication mechanisms*

| Concept | Priority | Category | Quick Description | Where Used | Learn After |
|---------|----------|----------|-------------------|------------|-------------|
| **WebAuthn / FIDO2** | ⭐⭐⭐⭐ | Method | W3C standard for passwordless auth using public key crypto. Supports biometrics, hardware tokens. Prevents phishing. | Passwordless login, biometric auth, security keys | MFA, PKI basics |
| **mTLS (Mutual TLS)** | ⭐⭐⭐ | Security | Two-way certificate verification between client and server. High security but complex cert management. | Finance, healthcare, high-security B2B, M2M | TLS/PKI fundamentals |
| **PASETO** | ⭐⭐⭐ | Token | Platform-Agnostic Security Tokens. Modern JWT alternative addressing vulnerabilities. Secure by default. | New apps prioritizing security, internal APIs | JWT (to understand differences) |
| **Zero Trust Architecture** | ⭐⭐⭐ | Architecture | "Never trust, always verify." Continuous auth/authorization. Assumes breach, verifies every request. | Modern enterprise, cloud environments, remote workforce | All auth fundamentals |
| **ABAC** | ⭐⭐⭐ | Authorization | Attribute-Based Access Control. Dynamic permissions based on user/resource/environment attributes. More flexible than RBAC. | Complex enterprises, dynamic policies, fine-grained control | RBAC |
| **Certificate-Bound Tokens** | ⭐⭐⭐ | Security | Combines mTLS with OAuth tokens bound to certificates. Prevents token theft. | Partner integrations, high-security APIs, server-to-server | mTLS, OAuth 2.0 |
| **Backend-for-Frontend (BFF)** | ⭐⭐⭐ | Architecture | Backend component for SPAs handling auth tokens securely. Reduces XSS impact. | Single-page applications, sensitive data | OAuth 2.0, SPA security |

---

## Phase 5: Practical & Commercial Tools 🛠️
*Hands-on implementation and platform-specific knowledge*

| Concept | Priority | Category | Quick Description | Where Used | Learn After |
|---------|----------|----------|-------------------|------------|-------------|
| **Social Login** | ⭐⭐⭐ | Method | SSO using social credentials (Google, Facebook, GitHub). Uses OAuth 2.0/OIDC. Reduces registration friction. | Consumer apps, SaaS products | OAuth 2.0, OIDC |
| **API Keys** | ⭐⭐⭐ | Method | Simple random credentials for API access. Fast setup but lack scopes, expiration, granular control. | Simple APIs, developer onboarding, public APIs | API basics |
| **Keycloak** | ⭐⭐ | Platform | Open-source Red Hat IdP. Supports SAML, OIDC. Highly customizable but requires infrastructure. | On-premise identity, custom requirements | OIDC, SAML |
| **Okta / Auth0** | ⭐⭐ | Platform | Cloud-based IAM platforms. Quick deployment, extensive integrations. Auth0 = CIAM focus, Okta = enterprise. | Enterprise IAM, customer identity, quick deployment | OIDC, SAML |
| **X-Frame-Options** | ⭐⭐ | Security | Prevents page embedding in frames/iframes to stop clickjacking. Legacy but still useful with CSP. | Web applications, clickjacking prevention | Web security basics |

---

## Legacy / Know But Don't Use 🚫
*Important to recognize but not recommended for new implementations*

| Concept | Priority | Category | Quick Description | Where Used | Learn After |
|---------|----------|----------|-------------------|------------|-------------|
| **Implicit Grant** | ⭐ | OAuth Flow | DEPRECATED. Returns access token directly, skipping auth code. Less secure, no longer recommended. | Legacy SPAs only - don't use for new apps | OAuth 2.0 (to understand history) |
| **Password Grant** | ⭐ | OAuth Flow | DISCOURAGED. User shares credentials directly with client. Requires high trust, less secure. | First-party apps only, migration scenarios | OAuth 2.0 (to understand history) |

---

## 🎓 Recommended Learning Sequence

### Week 1-2: Core Foundations
1. Session Management & Cookies
2. OAuth 2.0 framework
3. JWT tokens
4. OpenID Connect
5. Authorization Code Grant + PKCE

### Week 3-4: Security & Tokens
1. CORS fundamentals
2. Refresh Tokens & Token Rotation
3. Bearer Tokens for APIs
4. CSP, HSTS, SameSite cookies
5. RBAC for authorization

### Week 5-6: Enterprise (if needed)
1. SSO concepts
2. SAML 2.0
3. Identity Providers overview
4. Federated Identity
5. Client Credentials Grant

### Week 7-8: Advanced Topics (as needed)
1. WebAuthn/FIDO2
2. mTLS for high security
3. Zero Trust principles
4. Practical implementations (Social Login, etc.)

---

## 🔗 Key Concept Relationships

```
OAuth 2.0 (Foundation)
├── OpenID Connect (extends for authentication)
├── PKCE (secures flows)
├── JWT (common token format)
├── Refresh Tokens (part of flow)
├── Authorization Code Grant (primary flow)
└── Social Login (practical implementation)

Security Layers (Defense in Depth)
├── CORS + CSP + Security Headers
├── PKCE + Token Rotation
├── MFA + WebAuthn
└── mTLS + Certificate-Bound Tokens

Enterprise Stack
├── SAML/OIDC (protocols)
├── Identity Provider (infrastructure)
├── Active Directory (Microsoft ecosystem)
│   ├── Kerberos (authentication)
│   └── LDAP (directory)
└── SSO + Federated Identity (patterns)
```

---

## 📝 Notes

- **Priority ratings** reflect both importance and recommended learning order
- **5 stars (⭐⭐⭐⭐⭐)**: Fundamental concepts - learn these first
- **4 stars (⭐⭐⭐⭐)**: Important for most scenarios
- **3 stars (⭐⭐⭐)**: Specialized but valuable
- **2 stars (⭐⭐)**: Specific use cases or platforms
- **1 star (⭐)**: Legacy or deprecated - know but don't use

Focus on Phase 1 & 2 for web development. Add Phase 3 for enterprise work. Phase 4 & 5 are specialized - learn as needed for your specific requirements.
