# Auth Knowledge Base

Reference notes and useful snippets for authentication and authorization.

---

## Quick Reference

### Common JWT Claims

```
Standard claims (RFC 7519):
- iss (issuer): who created the token
- sub (subject): user/entity ID
- aud (audience): who token is intended for
- exp (expiration): Unix timestamp
- nbf (not before): Unix timestamp
- iat (issued at): Unix timestamp
- jti (JWT ID): unique identifier

Custom claims:
- email, name, role, permissions, scope, etc.
```

### HTTP Status Codes for Auth

```
200 OK - Successful auth
201 Created - User registered
204 No Content - Logout successful
400 Bad Request - Invalid credentials format
401 Unauthorized - Invalid/missing credentials
403 Forbidden - Valid auth, but insufficient permissions
404 Not Found - User doesn't exist (be careful, can leak info)
429 Too Many Requests - Rate limited
```

### Cookie Attributes

```
HttpOnly: Prevents JavaScript access (XSS protection)
Secure: Only sent over HTTPS
SameSite=Strict: Never sent cross-site
SameSite=Lax: Sent on top-level navigation (default, recommended)
SameSite=None: Sent everywhere (requires Secure flag)
Max-Age: Lifetime in seconds
Domain: Which domains can access
Path: Which paths can access
```

---

