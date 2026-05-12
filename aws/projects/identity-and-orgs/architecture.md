# Architecture Reference — Identity & Multi-Account

Three diagrams you'll keep coming back to. Read top-to-bottom on the first pass; bookmark for later sprints.

---

## 1. Target AWS Organization

End-of-project structure. Sprint 3 builds the skeleton; Sprint 7 puts file-sharing-service inside it.

```
┌──────────────────────────────────────────────────────────────────┐
│                                                                  │
│  AWS Organization (root)                                         │
│                                                                  │
│  ┌──────────────────────────────────────────────────────────┐    │
│  │  Mgmt Account  (your current admin acct, post-Sprint 3)  │    │
│  │  • Organizations                                         │    │
│  │  • IAM Identity Center                                   │    │
│  │  • Billing                                               │    │
│  │  • CloudTrail org trail (writes to Security acct)        │    │
│  │  • NO workloads                                          │    │
│  │  • Exempt from SCPs                                      │    │
│  └──────────────────────────────────────────────────────────┘    │
│                                                                  │
│  ┌─────── Root OU ───────┐                                       │
│  │  SCP: DenyRootAndOrgEscape                                    │
│  │                                                               │
│  │  ┌──────── Security OU ────────┐                              │
│  │  │  Security account            │                             │
│  │  │  • CloudTrail log archive    │                             │
│  │  │  • cross-acct-reader Lambda  │                             │
│  │  │  • Config aggregator         │                             │
│  │  └──────────────────────────────┘                             │
│  │                                                               │
│  │  ┌──────── Workloads OU ───────────────────────────────────┐  │
│  │  │  SCP: RegionLock-EU-US                                   │ │
│  │  │  Workloads-Prod account                                  │ │
│  │  │  • file-sharing-service (post-Sprint 7)                  │ │
│  │  │    - API GW, Lambda, S3, DynamoDB, Cognito               │ │
│  │  │  • S3LogReader role (trusted by Security)                │ │
│  │  └──────────────────────────────────────────────────────────┘ │
│  │                                                               │
│  │  ┌──────── Sandbox OU ─────────┐                              │
│  │  │  Sandbox account             │                             │
│  │  │  • Free experimentation      │                             │
│  │  │  • No prod data ever         │                             │
│  │  └──────────────────────────────┘                             │
│  └───────────────────────────────────────────────────────────────┘
│                                                                  │
└──────────────────────────────────────────────────────────────────┘
```

**Why this shape?**
- Mgmt isolated → root-user compromise can't reach workloads
- Security separate → audit logs unreachable to compromised app code
- Workloads separate → blast radius capped per-environment
- Sandbox separate → free experimentation w/o risk to anything real

---

## 2. IAM Trust Chain (Single Account → Cross-Account)

What happens when a Lambda in **Security** reads S3 in **Workloads-Prod**. Sprint 6.

```
   Security account                          Workloads-Prod account
   ─────────────────                          ─────────────────────

   ┌─────────────────┐
   │  Lambda fn:     │
   │  cross-account- │
   │  reader         │
   │                 │
   │  Execution Role │ ◀── (1) Lambda runtime injects
   │  CrossReadRole  │      temp creds for CrossReadRole
   │                 │      into env vars
   └────────┬────────┘
            │
            │ (2) boto3.client('sts').assume_role(
            │       RoleArn='...:role/S3LogReader',
            │       ExternalId='abc123')
            │
            ▼
   ┌─────────────────┐    SigV4-signed                ┌─────────────────┐
   │  STS endpoint   │ ──────────────────────────────▶│ STS evaluates   │
   │  (regional)     │                                │ trust policy of │
   └─────────────────┘                                │  S3LogReader    │
                                                      │                 │
                       (3) trust policy says:         │ Match?          │
                       Principal: arn:aws:iam::       │ - Principal ✓   │
                       <Sec>:role/CrossReadRole       │ - ExternalId ✓  │
                       Condition: sts:ExternalId       │ - Permission ✓  │
                                                      └────────┬────────┘
                                                               │
                                                               │ (4) issue temp creds:
                                                               │     AccessKeyId
                                                               │     SecretAccessKey
                                                               │     SessionToken
                                                               │     Expiration
                                                               ▼
                                                      ┌─────────────────┐
                                                      │  S3LogReader    │
                                                      │  (assumed)      │
                                                      │  Permissions:   │
                                                      │  s3:GetObject,  │
                                                      │  s3:ListBucket  │
                                                      └────────┬────────┘
                                                               │
                                                               │ (5) call S3 with
                                                               │     SigV4 using
                                                               │     temp creds
                                                               ▼
                                                      ┌─────────────────┐
                                                      │  S3 bucket      │
                                                      │  (Workloads-    │
                                                      │   Prod)         │
                                                      │                 │
                                                      │  Bucket policy  │
                                                      │  allows         │
                                                      │  S3LogReader    │
                                                      └─────────────────┘
```

**Key insights:**
- Lambda's execution role is **NOT** the role that reads S3. The Lambda role only has `sts:AssumeRole`. The assumed role has the S3 perms.
- The trust handshake is **2-sided**: trust policy in target + identity policy with `sts:AssumeRole` in source.
- ExternalId blocks confused-deputy: even if someone tricks `CrossReadRole` into calling assume, they need the secret ExternalId to succeed.
- STS, S3, and CloudTrail each see this in their own log. Trace via CloudTrail's `sessionIssuer`.

---

## 3. IAM Identity Center Login Flow

What happens when you click a permission-set tile in the IdC portal. Sprint 5.

```
   Browser                IdC (mgmt acct)         Target Account
   ───────                ────────────────        ──────────────

   (1) navigate to
       https://<id>.awsapps.com/start
       ────────────────────────────▶  ┌──────────────────┐
                                      │  IdC portal      │
   (2) authn:                          │                  │
   email + password + MFA              │  Identity source:│
       ────────────────────────────▶  │  IdC directory   │
                                      └────────┬─────────┘
                                               │
                                               │ (3) issue IdC session
                                               │     (browser cookie)
                                      ┌────────▼─────────┐
                                      │  Show tiles:     │
                                      │  for each        │
                                      │  (acct × perm    │
                                      │   set) assigned  │
                                      │  to user         │
                                      └────────┬─────────┘
                                               │
   (4) click tile                              │
   "AdminAccess in Workloads-Prod"             │
       ────────────────────────────▶           │
                                               │ (5) IdC has, at provisioning time,
                                               │     created an IAM role in
                                               │     Workloads-Prod named
                                               │     AWSReservedSSO_AdminAccess_<hash>
                                               │     with trust policy → IdC service
                                               │
                                      ┌────────▼─────────┐    cross-acct assume
                                      │  IdC calls STS:  │ ────────────────────▶
                                      │  AssumeRoleWith  │
                                      │  SAML (internal) │      ┌──────────────┐
                                      │  to that role    │      │ STS in       │
                                      └──────────────────┘      │ Workloads-   │
                                                                │ Prod         │
                                                                │ verifies +   │
                                                                │ issues temp  │
                                                                │ creds        │
                                                                └──────┬───────┘
                                                                       │
   (6) redirect to AWS Console                                          │
       with signed-in role session                                      │
       ◀──────────────────────────────────────────────────────────────────
   You see Console as
   AWSReservedSSO_AdminAccess
   in Workloads-Prod
```

**Key insights:**
- IdC is just an STS broker. Once you have the role session, AWS forgets you logged in via IdC; everything is normal STS from then on.
- The IdC-provisioned role **already exists** in the target account before you click. IdC pre-creates it at "assignment" time, not at click time.
- Session duration is the permission set's setting, not anything you control at click time.
- You never see static AWS keys. Console + (optional) `aws sso login` for the CLI both use the same flow.
