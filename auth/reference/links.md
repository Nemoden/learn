# Auth Learning - Reference Links

Curated resources for authentication and authorization protocols.

## RFCs and Specifications

### OAuth 2.1
- [OAuth 2.1 Draft](https://datatracker.ietf.org/doc/html/draft-ietf-oauth-v2-1-11) - Consolidated OAuth 2.0 + security best practices
- [RFC 6749 - OAuth 2.0](https://datatracker.ietf.org/doc/html/rfc6749) - Original OAuth 2.0 spec
- [RFC 7636 - PKCE](https://datatracker.ietf.org/doc/html/rfc7636) - Proof Key for Code Exchange
- [RFC 6750 - Bearer Tokens](https://datatracker.ietf.org/doc/html/rfc6750) - OAuth 2.0 bearer token usage

### OpenID Connect
- [OpenID Connect Core 1.0](https://openid.net/specs/openid-connect-core-1_0.html) - Authentication layer on OAuth 2.0
- [OpenID Connect Discovery 1.0](https://openid.net/specs/openid-connect-discovery-1_0.html) - Discovery metadata
- [OpenID Connect Session Management 1.0](https://openid.net/specs/openid-connect-session-1_0.html) - Session management

### JWT
- [RFC 7519 - JSON Web Token (JWT)](https://datatracker.ietf.org/doc/html/rfc7519)
- [RFC 7515 - JSON Web Signature (JWS)](https://datatracker.ietf.org/doc/html/rfc7515)
- [RFC 7516 - JSON Web Encryption (JWE)](https://datatracker.ietf.org/doc/html/rfc7516)
- [RFC 7517 - JSON Web Key (JWK)](https://datatracker.ietf.org/doc/html/rfc7517)

### SAML
- [SAML 2.0 Core](http://docs.oasis-open.org/security/saml/v2.0/saml-core-2.0-os.pdf) - SAML 2.0 specification
- [SAML 2.0 Profiles](http://docs.oasis-open.org/security/saml/v2.0/saml-profiles-2.0-os.pdf) - Web browser SSO profile

### WebAuthn / FIDO2
- [WebAuthn Level 2 W3C Recommendation](https://www.w3.org/TR/webauthn-2/)
- [CTAP2 Specification](https://fidoalliance.org/specs/fido-v2.0-ps-20190130/fido-client-to-authenticator-protocol-v2.0-ps-20190130.html)

### Other Auth Standards
- [RFC 6238 - TOTP](https://datatracker.ietf.org/doc/html/rfc6238) - Time-Based One-Time Password
- [RFC 4226 - HOTP](https://datatracker.ietf.org/doc/html/rfc4226) - HMAC-Based One-Time Password
- [RFC 7617 - HTTP Basic Auth](https://datatracker.ietf.org/doc/html/rfc7617)
- [RFC 7616 - HTTP Digest Auth](https://datatracker.ietf.org/doc/html/rfc7616)
- [RFC 8705 - OAuth mTLS](https://datatracker.ietf.org/doc/html/rfc8705) - Mutual TLS client authentication

## Security Best Practices

### OWASP
- [OWASP Authentication Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/Authentication_Cheat_Sheet.html)
- [OWASP Session Management Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/Session_Management_Cheat_Sheet.html)
- [OWASP JWT Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/JSON_Web_Token_for_Java_Cheat_Sheet.html)
- [OWASP Password Storage Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/Password_Storage_Cheat_Sheet.html)
- [OWASP Forgot Password Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/Forgot_Password_Cheat_Sheet.html)
- [OWASP Cross-Site Request Forgery (CSRF) Prevention](https://cheatsheetseries.owasp.org/cheatsheets/Cross-Site_Request_Forgery_Prevention_Cheat_Sheet.html)

### OAuth Security
- [OAuth 2.0 Security Best Current Practice](https://datatracker.ietf.org/doc/html/draft-ietf-oauth-security-topics) - Essential reading
- [OAuth 2.0 Threat Model and Security Considerations](https://datatracker.ietf.org/doc/html/rfc6819)

## Educational Resources

### Books
- "OAuth 2.0 Simplified" by Aaron Parecki - Excellent introduction
- "API Security in Action" by Neil Madden - Comprehensive security patterns
- "Real-World Cryptography" by David Wong - Crypto foundations for auth

### Articles & Guides
- [OAuth.com](https://www.oauth.com/) - Comprehensive OAuth 2.0 guide
- [JWT.io](https://jwt.io/) - JWT introduction and debugger
- [Auth0 Docs](https://auth0.com/docs) - Good explanations of auth concepts

### Tools
- [jwt.io Debugger](https://jwt.io/#debugger) - Decode and verify JWTs
- [OWASP Juice Shop](https://owasp.org/www-project-juice-shop/) - Practice finding auth vulnerabilities
- [OpenID Connect Playground](https://openidconnect.net/) - Test OIDC flows

## Attack Resources (for understanding threats)

- [OWASP Top 10](https://owasp.org/www-project-top-ten/) - Top web application security risks
- [PortSwigger Web Security Academy](https://portswigger.net/web-security) - Free training on web vulnerabilities
- [HackTricks - OAuth](https://book.hacktricks.xyz/pentesting-web/oauth-to-account-takeover) - Common OAuth attack vectors
- [Have I Been Pwned](https://haveibeenpwned.com/) - Check for compromised passwords

## Libraries and Tools

### Python
- [python-jose](https://python-jose.readthedocs.io/) - JWT implementation
- [passlib](https://passlib.readthedocs.io/) - Password hashing (bcrypt, argon2)
- [pyotp](https://pyauth.github.io/pyotp/) - TOTP implementation
- [authlib](https://docs.authlib.org/) - OAuth 1.0/2.0, OIDC, JOSE

### TypeScript/Node.js
- [jose](https://github.com/panva/jose) - JWT, JWS, JWE, JWK, JWKS (modern)
- [node-saml](https://github.com/node-saml/node-saml) - SAML 2.0 implementation
- [@simplewebauthn](https://simplewebauthn.dev/) - WebAuthn implementation
- [passport](http://www.passportjs.org/) - Authentication middleware

## Cloud Provider Docs

### AWS
- [Amazon Cognito Developer Guide](https://docs.aws.amazon.com/cognito/latest/developerguide/)
- [AWS Lambda Authorizers](https://docs.aws.amazon.com/apigateway/latest/developerguide/apigateway-use-lambda-authorizer.html)

### Other Providers
- [Auth0 Documentation](https://auth0.com/docs)
- [Keycloak Documentation](https://www.keycloak.org/documentation)
- [Okta Developer Docs](https://developer.okta.com/)
- [Google Identity Platform](https://developers.google.com/identity)

## Advanced Topics (queued for later)

- [GNAP](https://datatracker.ietf.org/doc/html/draft-ietf-gnap-core-protocol) - Grant Negotiation and Authorization Protocol
- [PASETO](https://paseto.io/) - Platform-Agnostic Security Tokens (JWT alternative)
- [Token Binding](https://datatracker.ietf.org/doc/html/rfc8471) - Preventing token export
- [CIBA](https://openid.net/specs/openid-client-initiated-backchannel-authentication-core-1_0.html) - Client-Initiated Backchannel Authentication
- [DPoP](https://datatracker.ietf.org/doc/html/rfc9449) - Demonstrating Proof of Possession
