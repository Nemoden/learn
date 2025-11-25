## CORS (Cross-Origin Resource Sharing)

### What CORS Prevents
CORS enforces the Same-Origin Policy - browsers block JavaScript from reading responses from different origins (domain, protocol, or port).

**Same vs Different Origin:**
```
✅ Same: https://example.com/page → https://example.com/api/data
❌ Different: https://example.com → https://api.other.com/data
❌ Different: https://example.com → http://example.com (protocol)
❌ Different: https://example.com → https://example.com:8080 (port)
```

### CORS vs XSS vs CSRF

**CORS ≠ XSS Protection**
- XSS = attacker injects code into YOUR site
- That code runs with YOUR origin, so CORS doesn't help
- CORS prevents reading responses from OTHER origins

**CORS Prevents CSRF-Style Reading Attacks:**
```javascript
// On evil.com trying to read your bank balance
fetch('https://bank.com/api/balance', { credentials: 'include' })
  .then(r => r.json())
  .then(data => {
    // CORS blocks this - attacker can't see 'data'
  })
```

**Key Confusion: "CORS doesn't prevent the request from being sent"**
- Request IS sent to server (with cookies!)
- Server DOES process it (potential damage done!)
- Browser only blocks JavaScript from READING the response
- This is why CORS alone isn't enough - need CSRF tokens too!

### Simple vs Complex Requests

**Simple requests (NO preflight):**
- Methods: GET, POST, HEAD
- Content-Type: application/x-www-form-urlencoded, multipart/form-data, text/plain
- Only simple headers (Accept, Content-Language, etc.)

**Complex requests (PREFLIGHT required):**
- Methods: PUT, DELETE, PATCH
- Content-Type: application/json
- Custom headers: Authorization, X-Custom-Header, etc.

### CORS Preflight Flow

Preflight = automatic OPTIONS request browser sends BEFORE the actual request for complex requests.

```
1. PREFLIGHT (OPTIONS)
   Browser → OPTIONS /api/users/123
             Origin: https://myapp.com
             Access-Control-Request-Method: DELETE
             Access-Control-Request-Headers: authorization

   Server  → 200 OK
             Access-Control-Allow-Origin: https://myapp.com
             Access-Control-Allow-Methods: DELETE, GET, POST
             Access-Control-Allow-Headers: authorization
             Access-Control-Max-Age: 86400  (cache 24hrs)

2. ACTUAL REQUEST (DELETE)
   Browser → DELETE /api/users/123
             Origin: https://myapp.com
             Authorization: Bearer token

   Server  → 200 OK
             Access-Control-Allow-Origin: https://myapp.com  ⚠️ MUST BE HERE TOO!
             { "status": "deleted" }
```

**Why CORS headers needed on BOTH responses:**
- Preflight checks: "Am I allowed to make this TYPE of request?"
- Actual response checks: "Am I allowed to READ this specific response?"
- Browser enforces CORS on both - if actual response missing headers, JavaScript can't read it
- Server-side effects (DB changes) happen anyway - response just blocked from JS

**Why preflight exists:**
- Protects legacy servers built before CORS
- Gives server chance to reject BEFORE destructive operations (DELETE, PUT)
- Only for non-simple requests (simple requests can be sent via `<img>` or `<form>` anyway)

### Key CORS Headers

**Server sends:**
- `Access-Control-Allow-Origin`: Which origins allowed (* or specific)
- `Access-Control-Allow-Methods`: Which HTTP methods allowed
- `Access-Control-Allow-Headers`: Which headers client can send
- `Access-Control-Allow-Credentials`: Allow cookies (can't use with *)
- `Access-Control-Max-Age`: Cache preflight duration

**Browser sends:**
- `Origin`: Where request comes from
- `Access-Control-Request-Method`: Method for preflight
- `Access-Control-Request-Headers`: Headers for preflight

---

## CSRF (Cross-Site Request Forgery) Tokens

### The Problem
Attacker can trigger requests from their site that include your session cookies:

```javascript
// On evil.com
fetch('https://bank.com/api/transfer', {
  method: 'POST',
  credentials: 'include',  // Sends YOUR bank.com cookies
  body: JSON.stringify({ to: 'attacker', amount: 10000 })
})

// Request IS sent, server DOES process it (bad!)
// CORS only blocks attacker from READING the response
```

### How CSRF Tokens Work

**Principle:** Attacker can send cookies but can't READ the CSRF token (blocked by CORS).

```
1. User visits legitimate site
   Browser → GET https://bank.com/dashboard
   Server  → Set-Cookie: csrf_token=xyz789random
             <meta name="csrf-token" content="xyz789random">

   [Server stores: session abc123 → csrf_token xyz789random]

2. Legitimate request includes token
   Browser → POST https://bank.com/api/transfer
             Cookie: session=abc123; csrf_token=xyz789random
             X-CSRF-Token: xyz789random  ← In header or body

   Server checks:
     ✅ Session valid?
     ✅ CSRF token matches session?
     ✅ Process request

3. Attack from evil.com
   Browser → POST https://bank.com/api/transfer
             Cookie: session=abc123  (sent automatically)
             ❌ NO X-CSRF-Token (attacker can't read it from bank.com)

   Server checks:
     ✅ Session valid?
     ❌ CSRF token missing/invalid
     ❌ REJECT - 403 Forbidden
```

**Why attacker can't include token:**
- Token stored in bank.com page or cookie
- CORS prevents evil.com from reading bank.com content
- Can't read it → can't include it → request rejected

### CSRF Token Best Practices

1. **Unpredictable:** Use cryptographically random tokens
   ```python
   import secrets
   token = secrets.token_hex(32)  # ✅
   token = str(user_id + timestamp)  # ❌ Guessable
   ```

2. **Per session or per request:** Store in server-side session

3. **Don't store in localStorage:** XSS can read it
   - Store in memory (React state) or HttpOnly=false cookie

4. **Double-submit cookie pattern (alternative):**
   ```
   Set-Cookie: csrf_token=xyz789; HttpOnly=false

   Frontend reads cookie, sends in header:
   X-CSRF-Token: xyz789

   Server compares cookie value === header value
   (Attacker can't set cookies for your domain)
   ```

---

## Modern Alternative: SameSite Cookies

Instead of (or in addition to) CSRF tokens:

```python
Set-Cookie: session=abc123; SameSite=Strict; HttpOnly; Secure
```

**SameSite Options:**
- `Strict` - Cookie NEVER sent on cross-site requests (strictest)
- `Lax` - Cookie sent on top-level navigation (links) but NOT fetch/XHR
- `None` - Old behavior, requires `Secure` flag (HTTPS only)

**Effect:**
```javascript
// On evil.com
fetch('https://bank.com/api/transfer', {
  credentials: 'include'
})
// With SameSite=Strict: Browser doesn't send session cookie at all!
// Request reaches server but user is NOT authenticated
```

**Modern approach:** Use SameSite=Lax + CSRF tokens for defense in depth
- SameSite blocks most attacks
- CSRF tokens provide fallback for edge cases and older browsers

---

## Defense in Depth Summary

| Layer | Prevents | Limitation |
|-------|----------|------------|
| **CORS** | Reading responses cross-origin | Doesn't prevent request being sent; server still processes it |
| **CSRF Tokens** | Forged requests | Vulnerable if XSS exists (attacker can read token) |
| **SameSite Cookies** | Cross-site cookies being sent | Not supported in very old browsers |
| **CORS Preflight** | Non-simple requests before server approval | Only for complex requests (JSON, custom headers, PUT/DELETE) |

**Bottom line:** CORS checks happen on BOTH preflight and actual response. Server-side effects happen regardless of CORS blocking - browser only blocks JavaScript from reading the response.
