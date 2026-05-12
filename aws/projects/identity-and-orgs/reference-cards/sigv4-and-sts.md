# SigV4 & STS

## SigV4 in one paragraph

SigV4 = AWS's request-signing algorithm. Every API call to AWS is **signed** w/ HMAC-SHA256 using your credentials, a canonical representation of the request, and the date+region+service. The server recomputes the signature; if it matches, the request is authentic and untampered.

## What SigV4 actually signs

```
HTTP request                          Canonical request               Signature
─────────────                         ─────────────────              ─────────
Method                                Method                          HMAC-SHA256(
URI path                              URI path (URI-encoded)            signing key,
Query string                          Query string (sorted)             string-to-sign)
Headers (incl. x-amz-date,            Signed headers (sorted)
  x-amz-content-sha256,               + their values
  optionally x-amz-security-token)
Body                                  SHA256(body)
```

The result is `Authorization: AWS4-HMAC-SHA256 Credential=..., SignedHeaders=..., Signature=...`.

## Where credentials come from

| Source | Mechanism |
|--------|-----------|
| IAM user (static keys) | `~/.aws/credentials` — access key + secret. **Avoid.** |
| EC2 instance role | IMDSv2 endpoint `http://169.254.169.254/...` returns temp creds for the instance profile |
| Lambda execution role | Env vars `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, `AWS_SESSION_TOKEN` injected by Lambda runtime |
| ECS task role | Task metadata endpoint returns temp creds |
| EKS IRSA | Pod's projected service-account token exchanged for STS creds via OIDC |
| IAM Identity Center | `aws sso login` → SSO portal → STS temp creds |
| `sts:AssumeRole` | Explicit assume — returns temp creds for the assumed role |

**Temp creds = access key + secret key + session token + expiration.** All 3 must be sent on every signed request when using temp creds. Static creds (IAM user keys) don't have a session token.

## STS API surface

| API | Use |
|-----|-----|
| `sts:AssumeRole` | Cross-account or same-account role-switch |
| `sts:AssumeRoleWithWebIdentity` | Federated via OIDC (e.g., Cognito Identity, Google, GitHub Actions) |
| `sts:AssumeRoleWithSAML` | Federated via SAML (e.g., Okta, AD FS) |
| `sts:GetSessionToken` | Boost an IAM user's session w/ MFA |
| `sts:GetCallerIdentity` | Who am I? Returns Account, UserId, ARN of the caller |
| `sts:GetFederationToken` | Like AssumeRole but for IAM users; rarely used now |

## AssumeRole response shape

```json
{
  "Credentials": {
    "AccessKeyId": "ASIA...",
    "SecretAccessKey": "...",
    "SessionToken": "...",                // required for SigV4 w/ temp creds
    "Expiration": "2026-05-12T14:00:00Z"
  },
  "AssumedRoleUser": {
    "AssumedRoleId": "AROA...:session-name",
    "Arn": "arn:aws:sts::111122223333:assumed-role/RoleName/session-name"
  },
  "PackedPolicySize": 0
}
```

The `Arn` field above is what you'll see as the **caller identity** in CloudTrail.

## STS regional vs global

- **Global endpoint** (`sts.amazonaws.com`) → us-east-1. **Avoid** — single-region failure mode.
- **Regional endpoints** (`sts.us-east-1.amazonaws.com`) → preferred. Lower latency, regional independence.
- Most SDKs default to regional since boto3 1.20+; configure via `AWS_STS_REGIONAL_ENDPOINTS=regional`.

## SigV4 in cross-account flows

```
1. Lambda (Security acct) → STS endpoint
   Authorization: SigV4 using Lambda's execution role temp creds
   Body: AssumeRole(RoleArn=arn:...:role/S3LogReader, ExternalId=abc)

2. STS verifies trust policy of S3LogReader, issues new temp creds.

3. Lambda code uses those new creds → S3 endpoint in Workloads-Prod
   Authorization: SigV4 using S3LogReader's temp creds
   Header: x-amz-security-token (the new session token)
```

Two separate SigV4 signatures, two separate credential sets, one Python call sequence:

```python
sts = boto3.client('sts')
resp = sts.assume_role(
    RoleArn='arn:aws:iam::WORKLOADS-PROD-ID:role/S3LogReader',
    RoleSessionName='cross-acct-read',
    ExternalId='abc123'
)
creds = resp['Credentials']
s3 = boto3.client(
    's3',
    aws_access_key_id=creds['AccessKeyId'],
    aws_secret_access_key=creds['SecretAccessKey'],
    aws_session_token=creds['SessionToken'],
)
obj = s3.get_object(Bucket='file-sharing-prod', Key='log.txt')
```

## CloudFront → S3 (SigV4 by OAC)

When you set up Origin Access Control:

1. CloudFront builds an HTTPS GET to the S3 origin endpoint.
2. OAC signs it w/ SigV4 using CloudFront's **service-linked credentials** for that distribution.
3. The signed `Authorization` header is added before the req leaves the edge POP.
4. S3 verifies SigV4 + the bucket policy condition `aws:SourceArn = arn:aws:cloudfront::ACCT:distribution/DIST_ID`.
5. Match → 200 OK. Mismatch → 403.

Neither you nor CloudFront ever creates static creds for this. The signing identity is "CloudFront-as-a-service for distribution X".
