# Identity & Multi-Account — Teaching Plan (for Claude)

**🎯 Primary Audience**: Claude (AI teaching assistant)
**📋 Purpose**: Teaching script. Defines what to teach, when, in what order. Tracks progress across sessions.

**How Claude Uses This File**:
1. Read **Session State** at start of every `/learn` session
2. Find next unchecked checkbox under the current sprint
3. Teach interactively — never just say "do this", walk the user through it
4. Tick boxes as user completes them
5. Update Session State

**How User Uses This File** (secondary):
- See what's coming
- Reference MUST-KNOWs
- Browse adjacent tech via `/adjacent` slash cmd

**Constraint reminder**: **NO AWS CLI** in any sprint. Work laptop's default profile points to a different (work) AWS account. Everything happens via **AWS Console** or **CloudFormation/StackSets** (deployed from Console).

## Project Goal

Take `file-sharing-service` (currently in a single admin account, **not** in an Organization) and end up with:

- An **AWS Organization** rooted at that account → becomes **mgmt account**
- 3 additional member accounts: **Security**, **Workloads-Prod**, **Sandbox**
- OUs: `Root → {Security, Workloads, Sandbox}`
- An **SCP** on Workloads OU enforcing region lock + root-user deny
- **IAM Identity Center** as the only human-login mechanism (no IAM users)
- **file-sharing-service migrated** to the Workloads-Prod account
- A **cross-account role** letting a Lambda in Security read CloudTrail logs from Workloads-Prod

---

## Target Architecture

```
                       ┌─────────────────────────────────────┐
                       │  AWS Organization                   │
                       │  Mgmt Account (current admin acct)  │
                       │  - Billing                          │
                       │  - Organizations                    │
                       │  - IAM Identity Center              │
                       │  - NO workloads                     │
                       └─────────────────────────────────────┘
                                       │
                  ┌────────────────────┼────────────────────┐
                  │                    │                    │
            ┌─────▼──────┐      ┌──────▼──────┐      ┌──────▼──────┐
            │  Security  │      │  Workloads  │      │   Sandbox   │
            │     OU     │      │     OU      │      │     OU      │
            │  (SCP: A)  │      │  (SCP: B)   │      │  (SCP: C)   │
            └─────┬──────┘      └──────┬──────┘      └──────┬──────┘
                  │                    │                    │
            ┌─────▼──────┐      ┌──────▼──────┐      ┌──────▼──────┐
            │ Security   │      │ Workloads-  │      │ Sandbox     │
            │ account    │      │ Prod acct   │      │ account     │
            │ (audit,    │      │ (file-      │      │ (free play) │
            │  CloudTrail│      │  sharing-   │      │             │
            │  central)  │      │  service)   │      │             │
            └────────────┘      └─────────────┘      └─────────────┘
```

---

## Sprint 0 — Foundations: Why Multi-Account?

### Goal
You should be able to explain in 2 minutes why a serious AWS user runs >1 account.

### Activities
- [ ] **Discussion**: What does an "AWS account" actually isolate?
  - Resources, IAM principals, billing, service limits, CloudTrail trail boundary
- [ ] **The 5 reasons multi-account exists** (Claude walks you through each w/ a concrete file-sharing-service example):
  1. **Blast radius** — compromised IAM key in workloads acct can't touch billing or other workloads
  2. **Billing & cost attribution** — per-account invoicing, tag-independent
  3. **Service limits & quotas** — Lambda concurrency, EIPs, etc. are per-account
  4. **IAM boundary** — only way to truly say "this principal cannot reach that resource" without exotic SCP/condition logic
  5. **Compliance & data residency** — separate account for PII, audit, prod data
- [ ] **Anti-pattern audit**: Look at your current file-sharing-service. What 3 things are wrong with running it in your admin account?
- [ ] **Quiz checkpoint** — Claude asks: "Why can't IAM-only multi-tenancy give you the same blast-radius isolation as multi-account?"

### 🚨 MUST-KNOW
- **Account ≠ region ≠ VPC**. Account is the hardest isolation boundary AWS gives you; region is geographic; VPC is network. Mixing these mental models causes design errors.
- **The mgmt account is sacred**. AWS Well-Architected: keep it empty of workloads. Only Organizations, IdC, and billing live there. Why: a single root-user compromise there owns every member account.

### Outcome
You can defend the 4-account topology proposed in `architecture.md` against "why don't we just use IAM?".

### Here we could also use…
- **A single account with strict IAM + tags + permission boundaries** — cheaper to operate, no cross-acct complexity, but blast-radius and quota isolation are leaky. Pick when team is <5 people and one product.
- **Per-environment accounts (dev/staging/prod)** instead of per-domain (workloads/security/sandbox) — easier mental model for app teams, but worse for shared services and central audit. Mature orgs end up with a 2D grid (domain × env).

---

## Sprint 1 — IAM Deep Dive (Single Account)

### Goal
You can read any IAM-related JSON and predict whether a request is allowed.

### New Concepts
- IAM **users**, **groups**, **roles**, **federated identities**
- 6 policy types: **identity**, **resource**, **SCP**, **permission boundary**, **session**, **ACL**
- **Policy evaluation logic**: explicit deny > explicit allow > implicit deny; SCP gate before IAM
- `Principal`, `Action`, `Resource`, `Condition`, `NotAction`, `NotResource`

### Activities
- [ ] **Read [reference-cards/iam-policy-anatomy.md](./reference-cards/iam-policy-anatomy.md)** — 5 min
- [ ] **Walk through `file-sharing-service`'s current IAM** (Claude opens the SAM template w/ you):
  - Every `AWS::IAM::Role` + every `Policies:` block
  - Which are identity policies? Which are resource policies (S3 bucket policy, Lambda permission)?
  - Which use `Principal: Service: lambda.amazonaws.com`?
- [ ] **Exercise — policy puzzles** (Claude shows JSON, you predict allow/deny):
  - Identity policy says Allow s3:GetObject on `*`; bucket policy has explicit Deny on `kirill-private-bucket/*`. Result?
  - SCP on the OU denies `s3:DeleteBucket`; identity policy allows it. Result?
  - Permission boundary allows only `s3:*`; identity policy allows `s3:* dynamodb:*`. Result?
- [ ] **Concept: when to use a role vs a user**
  - Rule: **never create an IAM user except for break-glass**. Everything else is a role (federated humans via IdC, services via trust policy).
- [ ] **Quiz checkpoint** — Claude asks: "Why is a permission boundary fundamentally different from an IAM policy attached normally?"

### 🚨 MUST-KNOW
- **Roles have two policies**: a **trust policy** (who can assume) and **permission policies** (what they can do once assumed). Confusing these = the #1 IAM bug.
- **Resource policies cross account boundaries**; identity policies don't. To let acct B's principal touch acct A's S3 bucket, **both** sides must allow (resource policy on bucket in A, identity policy in B).
- **Explicit deny always wins**. SCP deny > identity allow. Boundary deny > inline allow.

### Outcome
You can audit `file-sharing-service`'s IAM in <15 min and explain every line.

### Here we could also use…
- **ABAC (attribute-based access control)** — tag principals + resources, write policies w/ `aws:PrincipalTag/X = aws:ResourceTag/X` conditions. Scales better than per-resource role explosion. Worth knowing once you have >50 roles.
- **AWS Verified Permissions** — Cedar-language external authorization service. Pulls fine-grained authz out of IAM entirely; useful for in-app permissions (e.g. "can user X share file Y with team Z?"). Not a replacement for IAM, sits on top.

---

## Sprint 2 — Roles & STS

### Goal
You can draw the full assume-role flow and explain what STS returns.

### New Concepts
- `sts:AssumeRole`, `sts:AssumeRoleWithWebIdentity`, `sts:AssumeRoleWithSAML`
- **Trust policy** structure (`Principal` block syntax)
- **Temporary credentials**: AccessKeyId, SecretAccessKey, **SessionToken**, Expiration
- **Session duration**, **MaxSessionDuration**, **role chaining** (1 hop max for chained assumes)
- **ExternalId** (confused-deputy mitigation in 3rd-party trust)
- **Source identity** + how it shows in CloudTrail

### Activities
- [ ] **Read [reference-cards/role-trust-vs-permissions.md](./reference-cards/role-trust-vs-permissions.md)**
- [ ] **Read [reference-cards/sigv4-and-sts.md](./reference-cards/sigv4-and-sts.md)** — what SigV4 signs, what STS issues
- [ ] **Diagram exercise** — on paper or whiteboard, draw:
  - Browser → API Gateway → Lambda (Lambda's execution role assumed via STS) → DynamoDB
  - Mark every place a credential exists, what type, who issued it, who verifies it
- [ ] **Confused-deputy explanation** — Claude walks through the classic CloudTrail-trust scenario. You explain back when an `ExternalId` matters.
- [ ] **Console exercise**: In your current admin account, create a role with trust policy `Principal: AWS: arn:aws:iam::<your-acct>:root` and a permission policy `s3:ListAllMyBuckets`. Switch role via Console role switcher. (We'll use this same flow cross-account in Sprint 6.)
  - [ ] Role created
  - [ ] Successfully switched to it via "Switch Role" UI
  - [ ] Confirmed STS issued temp creds (look at IAM → Access Analyzer / CloudTrail)
- [ ] **Quiz checkpoint** — "If Lambda's execution role allows `s3:PutObject` and you call `sts:AssumeRole` from inside Lambda to a second role that allows only `s3:GetObject`, what can the assumed session do?"

### 🚨 MUST-KNOW
- **Lambda doesn't need to call `sts:AssumeRole` manually**. The Lambda runtime injects temp creds for the execution role into env vars. You only call AssumeRole when you want a *different* role (e.g. cross-account).
- **MaxSessionDuration cap is per-role**. Default 1h, max 12h. IdC permission sets have a separate session duration.
- **Role chaining caps the session at 1 hour** regardless of MaxSessionDuration. Surprises people doing assume-then-assume.

### Outcome
You have a working "switch role" example in your admin account. You can explain trust policy vs perm policy w/o looking.

### Here we could also use…
- **IAM Roles Anywhere** — gives on-prem workloads SigV4 creds via X.509 certs, no static keys. Useful if you have to integrate a non-AWS server.
- **EC2 Instance Profiles / EKS IRSA / ECS Task Role** — same pattern as Lambda execution role, just different compute. All resolve via STS under the hood.

---

## Sprint 3 — Organizations & OUs

### Goal
Your admin account is now an Org mgmt account with 3 member accounts under 3 OUs.

### New Concepts
- **AWS Organizations**: management account vs member accounts
- **OU (Organizational Unit)**: hierarchical grouping for policy inheritance
- **Account creation via Organizations** (`CreateAccount` API) vs **inviting existing accounts**
- **Consolidated billing**: all member account bills roll up to mgmt account
- **Trusted services** (e.g., CloudTrail, Config, IdC — can be enabled org-wide)
- **OrganizationAccountAccessRole** — auto-created role in member accounts that mgmt can assume

### Activities
- [ ] **Plan account emails** — you'll use Gmail `+aliases`. Decide names now:
  - Mgmt: your existing email (it's already attached to the admin account)
  - Security: `<you>+aws-security@gmail.com`
  - Workloads-Prod: `<you>+aws-workloads-prod@gmail.com`
  - Sandbox: `<you>+aws-sandbox@gmail.com`
- [ ] **Enable AWS Organizations** in your admin account (Console: Organizations → "Create an organization", choose "All features", **not** "consolidated billing only")
  - [ ] Org created, mgmt account confirmed in dashboard
- [ ] **Create 3 OUs** under Root: `Security`, `Workloads`, `Sandbox`
  - [ ] OUs visible in tree view
- [ ] **Create 3 member accounts** (Organizations → Add an AWS account → Create an AWS account). For each, set the alias email + IAM role name (leave default `OrganizationAccountAccessRole`).
  - [ ] Security account created (status Active, account ID noted)
  - [ ] Workloads-Prod account created
  - [ ] Sandbox account created
- [ ] **Move each new account into its OU** (drag/drop or "Move" action)
  - [ ] Security acct → Security OU
  - [ ] Workloads-Prod acct → Workloads OU
  - [ ] Sandbox acct → Sandbox OU
- [ ] **Verify cross-account access** — from mgmt console, use "Switch Role" with the new member account ID + `OrganizationAccountAccessRole`. Confirm you land in the member account as admin.
  - [ ] Successfully assumed `OrganizationAccountAccessRole` into Workloads-Prod from mgmt

### 🚨 MUST-KNOW
- **`OrganizationAccountAccessRole` is the back door**. It's auto-created in every account you create via Organizations, with a trust policy allowing the mgmt account. **This is how you bootstrap access** before IdC is set up. Delete it later (after Sprint 5) for tighter security.
- **Account email is the recovery vector**. If you lose the password and the email, the account is gone. Use email aliases you actually control; consider 2FA on the inbox itself.
- **"All features" vs "consolidated billing only"** — pick All features. SCPs + IdC + service-org-integration all require it.
- **Account closure is slow** (90 days to fully delete) and limited to 10% of your org accounts per month. Don't create accounts you don't need.

### Outcome
4-account org. Tree visible. You can switch into each member acct via Console role switcher.

### Here we could also use…
- **AWS Control Tower** — managed blueprint for Orgs+IdC+baseline SCPs+account vending via Service Catalog. Solves "I want this whole sprint pre-built". Trade-off: opinionated, hard to undo, locks you into its OU layout.
- **Account Factory for Terraform (AFT)** — Control Tower's IaC layer. Account creation as code.

---

## Sprint 4 — SCPs (Service Control Policies)

### Goal
An SCP on the Workloads OU enforces region lock and denies root-user actions.

### New Concepts
- **SCP**: org-level policy. Only acts as a **deny filter** (or allow-list). Does NOT grant permissions.
- **SCP vs IAM**: SCPs filter the *maximum* set of permissions; IAM grants within that. SCPs cannot grant.
- **Strategies**: allow-list (`FullAWSAccess` + deny patches) vs deny-list (start from `FullAWSAccess`, layer denies)
- **Common guardrails**: region lock, deny root user, deny disabling CloudTrail, deny leaving the org
- **Mgmt account is exempt** from SCPs (one more reason to keep it empty)

### Activities
- [ ] **Read [reference-cards/scp-cheatsheet.md](./reference-cards/scp-cheatsheet.md)**
- [ ] **Enable SCPs in your org** (Organizations → Policies → Service control policies → Enable)
  - [ ] SCPs enabled (the `FullAWSAccess` SCP is auto-attached to everything)
- [ ] **Create SCP `RegionLock-EU-US`**: deny any action where `aws:RequestedRegion` is not in `[us-east-1, eu-west-1]`. Use template in `templates/scp-region-lock.json`.
  - [ ] SCP created
  - [ ] Attached to Workloads OU
- [ ] **Create SCP `DenyRootAndOrgEscape`**: deny if `aws:PrincipalArn` ends in `:root`; deny `organizations:LeaveOrganization`; deny `cloudtrail:StopLogging`. Template: `templates/scp-deny-root.json`.
  - [ ] SCP created
  - [ ] Attached to Root OU (applies to all member accts except mgmt)
- [ ] **Verify**: switch into Workloads-Prod, try to launch a resource in `ap-southeast-1`. Should be explicitly denied with SCP error in API response.
  - [ ] Region-blocked action denied as expected
- [ ] **Verify SCP doesn't grant**: temporarily detach `FullAWSAccess` from Sandbox OU. Try anything in sandbox. Everything fails.
  - [ ] Confirmed: removing FullAWSAccess = total lockout (then re-attach)
- [ ] **Quiz checkpoint** — "User in Workloads-Prod has IAM policy allowing `s3:*` and SCP on the OU denies `s3:DeleteBucket`. Mgmt account user with the same IAM policy is in the same org. Who can delete a bucket?"

### 🚨 MUST-KNOW
- **SCPs evaluate before IAM**. The order: SCP → resource policy → identity policy → permission boundary → session policy. Any denial along the way = denied.
- **Mgmt account is exempt** — SCPs attached at Root OU do NOT apply to mgmt account. Use IAM in mgmt to constrain it.
- **An OU with no SCP attached implicitly has only `FullAWSAccess`**. New OUs you create get FullAWSAccess by default; don't accidentally detach it without a replacement.
- **`aws:RequestedRegion` is request-time; `aws:PrincipalRegion` is principal-time**. Use RequestedRegion for region-lock SCPs.

### Outcome
file-sharing-service (still in mgmt acct for now) is unaffected by the SCP. Sandbox & Workloads & Security accounts are region-locked + root-protected.

### Here we could also use…
- **Permission Boundaries** instead of SCPs — boundary is set on an individual IAM principal, not an OU. Useful when you can't move workloads into a separate account but want to cap a specific role's blast radius.
- **Resource Control Policies (RCPs)** — newer than SCPs, attach to resources (S3, KMS, etc.) and apply org-wide. Better for "no public S3 ever in this org" rules.

---

## Sprint 5 — IAM Identity Center (SSO)

### Goal
You log into all 4 accounts via the IdC portal. No IAM users anywhere.

### New Concepts
- **IAM Identity Center** (formerly AWS SSO): an identity broker that federates into accounts via STS
- **Identity sources**: native IdC directory / external IdP (Okta/Entra/Google Workspace) / AD
- **Permission Sets**: templates that IdC translates into IAM roles in target accounts at provisioning time
- **Account assignments**: (user/group) × (permission set) × (account)
- **Session duration** is set on the permission set; max 12h
- IdC vs old "IAM Federation" (SAML 2.0 directly to IAM) — IdC is the modern path

### Activities
- [ ] **Enable IAM Identity Center** in mgmt account, region of your choice (often us-east-1 for blast-radius reasons)
  - [ ] IdC enabled, your portal URL is shown
- [ ] **Use native IdC directory** as identity source (no Okta needed)
  - [ ] Identity source set to "Identity Center directory"
- [ ] **Create your user** in IdC (your email + name). Set password via the verification email.
  - [ ] User created, can log into the portal URL
- [ ] **Create 2 Permission Sets**:
  - `AdminAccess` — AWS-managed `AdministratorAccess`, session 4h
  - `ReadOnly` — AWS-managed `ReadOnlyAccess`, session 8h
  - [ ] Both permission sets visible
- [ ] **Assign yourself**:
  - `AdminAccess` to mgmt, Workloads-Prod, Sandbox
  - `ReadOnly` to Security
  - [ ] Assignments visible per account
- [ ] **Log in via IdC portal**. Confirm role-switch tiles appear for each account.
  - [ ] Portal works
  - [ ] Tile click → lands in target account as the IdC-provisioned role
- [ ] **Inspect** the IAM role in a member account: it's named like `AWSReservedSSO_AdminAccess_<hash>`. Trust policy → IdC service. **You did not create this role manually**; IdC did, behind the scenes.
- [ ] **Quiz checkpoint** — "Why is a Permission Set not the same as an IAM role, even though IdC produces an IAM role from it?"

### 🚨 MUST-KNOW
- **IdC writes IAM roles into accounts on-demand**. A permission set is a template; the actual role only exists in an account after an assignment.
- **Renaming a permission set = recreating roles**. IdC un-provisions and re-provisions. Trust policies on those roles will see a new role ARN.
- **IdC portal != AWS Console URL**. You get a unique `https://<id>.awsapps.com/start` URL. Bookmark it; it's the only login surface humans should use.
- **Stop creating IAM users**. After this sprint, every human login is IdC. The only IAM users that should exist are emergency break-glass (long-rotated, MFA, locked in a vault).

### Outcome
SSO is live across all 4 accounts. You can revoke your own access in one place. You no longer need `OrganizationAccountAccessRole` for daily work (keep it as backup or delete after Sprint 7).

### Here we could also use…
- **External IdP (Okta / Entra / Google Workspace)** as identity source — wires IdC to your existing corporate directory. SCIM provisions users automatically. The setup is identical from the AWS side; only the identity source changes.
- **Direct SAML 2.0 federation to IAM** (no IdC) — the old path. Still works but you manage roles per-account by hand. Don't pick this for new setups.

---

## Sprint 6 — Cross-Account Role Assumption

### Goal
A Lambda in the Security account can read S3 from Workloads-Prod via cross-account role assumption.

### New Concepts
- Cross-account **trust policy** w/ `Principal: AWS: arn:aws:iam::<other-acct>:role/<role>`
- The 2-sided handshake: resource side (trust + bucket policy) + principal side (identity policy with `sts:AssumeRole`)
- CloudTrail event `AssumeRole` in source account, target account, and `userIdentity.sessionIssuer` for chained trace
- `ExternalId` for 3rd-party scenarios (not needed when both accounts are yours, but practice it)

### Activities
- [ ] **Sketch the trust chain on paper** before clicking anything (Claude asks you to)
- [ ] **In Workloads-Prod**: create role `S3LogReader` with:
  - Trust policy: `Principal: AWS: arn:aws:iam::<Security-acct-id>:root` (or a specific role)
  - Permission policy: `s3:GetObject, s3:ListBucket` on a specific bucket (use the file-sharing bucket once you migrate; for now create a test bucket)
  - [ ] Role created
  - [ ] Test bucket created + 1 sample object
- [ ] **In Security**: create a Lambda function `cross-account-reader`
  - Execution role with `sts:AssumeRole` permission on the Workloads-Prod role ARN
  - Code (paste in Console editor): `boto3.client('sts').assume_role(...)`, then use returned creds to call S3
  - [ ] Lambda deployed
  - [ ] Lambda execution successful — reads object from Workloads-Prod S3
- [ ] **CloudTrail trace**: find the matching `AssumeRole` events in both accounts' CloudTrail logs (Console: CloudTrail → Event history → filter by event name)
  - [ ] Trace identified in Security account (caller)
  - [ ] Trace identified in Workloads-Prod (target)
- [ ] **Add `ExternalId`** to the trust policy. Update Lambda to pass it. Confirm calls without it fail.
  - [ ] ExternalId enforced
- [ ] **Quiz checkpoint** — "If I drop `ExternalId` from the trust policy condition but the caller still sends one, does it succeed?"

### 🚨 MUST-KNOW
- **Both sides must agree**. The trust policy in account A says who *may* assume; the identity policy in account B says who *will try*. Missing either = denied.
- **`Principal: AWS: arn:...:root`** doesn't mean "root user". It means "any principal in this account that has an `sts:AssumeRole` allow in their identity policy". Account-level scoping.
- **ExternalId is anti-confused-deputy**. Use it whenever the caller is a third-party SaaS (e.g., monitoring tools). For your own org, optional but harmless practice.
- **Role chaining limits**: assume → assume = 1-hour cap. The 2nd hop session can't last longer than 1h regardless of MaxSessionDuration.

### Outcome
You have a working cross-account read flow + the CloudTrail trace to prove what happened.

### Here we could also use…
- **EventBridge cross-account event bus** — for event-driven (push) cross-account instead of pull. Useful when source account emits, target reacts.
- **AWS RAM (Resource Access Manager)** — share resources (subnets, Route 53 zones, Glue Catalog, etc.) across accounts without role assumption. Different mental model: "share resource", not "delegate identity".

---

## Sprint 7 — Migrate file-sharing-service into Workloads-Prod

### Goal
file-sharing-service no longer runs in mgmt account. It runs in Workloads-Prod. Mgmt account is now empty of workloads.

### New Concepts
- **Migration strategy**: redeploy (clean) vs move-in-place (impossible — accts can't be merged)
- **CloudFormation StackSets** — deploy a stack to many accts from mgmt
- **Account-bound resources that don't move**: account ID is in ARNs, S3 bucket names are global, Cognito User Pools are account+region scoped. Users will need to re-register or you migrate data.
- **DNS / Route 53**: hosted zones in mgmt acct → optionally delegate or move. Often easier to put hosted zone in a Shared Services account.

### Activities
- [ ] **Strategy decision**: clean redeploy in Workloads-Prod, then point traffic over. Old resources deleted from mgmt after verification.
  - [ ] Strategy confirmed; you accept that Cognito users + S3 objects will be migrated by hand or test-data-only
- [ ] **Switch to Workloads-Prod** via IdC portal
- [ ] **Bootstrap SAM in Workloads-Prod**: `sam deploy --guided` (uses your IdC creds from Console-issued shell, OR redeploy via CloudFormation Console direct-upload)
  - Since you can't use AWS CLI: use **CloudFormation Console** → "Create stack" → upload `template.yaml` directly
  - [ ] Stack deployed in Workloads-Prod
- [ ] **Verify** the new endpoints work end-to-end (sign up, upload, download)
  - [ ] New API endpoint tested
- [ ] **Delete the old stack** from mgmt account (CloudFormation Console → delete stack)
  - [ ] Mgmt account confirmed empty of workloads
- [ ] **Optional: enable centralized CloudTrail** — create org trail in mgmt, log into S3 bucket in Security account. Read-only by Security.
  - [ ] Org trail enabled
  - [ ] Logs landing in Security acct S3
- [ ] **Remove `OrganizationAccountAccessRole` from Workloads-Prod** (optional, security hardening — you have IdC now)
  - [ ] Role deleted (or marked unused)

### 🚨 MUST-KNOW
- **You can't move an account between Orgs without account closure**. You CAN move it between OUs in the same org freely.
- **S3 bucket names are globally unique** across all AWS. You can't reuse the old name; pick a new one prefixed with the account context.
- **CloudFormation stacks are account+region scoped**. The "same" stack in 2 accounts is 2 different stacks.
- **The mgmt account never runs your code**. Keep this rule even when it feels easier to "just put it back".

### Outcome
file-sharing-service lives in Workloads-Prod under the Workloads OU, governed by the region-lock SCP, accessed only via IdC.

### Here we could also use…
- **StackSets** — deploy the SAM template to N member accounts from mgmt with one operation. Pick when you have multi-env (deploy same stack to dev/staging/prod accounts).
- **Terraform with multi-acct providers** — `provider "aws" { alias = "prod" }` pattern; one repo deploys to many accounts. More common at companies that already have Terraform.
- **CDK with multi-stack deployments** — same idea with TypeScript/Python.

---

## Sprint 8 — Adjacent Tech Survey (Anti-Tunnel-Vision)

### Goal
You can name 5 alternatives to the stack you just built and say when each wins.

### Activities
- [ ] **Read [adjacent.md](./adjacent.md)** end to end
- [ ] **Discussion** w/ Claude on each entry — when does it beat what we built?
- [ ] **Pick 1-2** that genuinely interest you. Claude adds them to `to-learn.md` w/ today's date.
  - [ ] Picks added to `to-learn.md`
- [ ] **Reflection**: what 3 things would you build differently if starting over?

### Outcome
A short list of follow-up topics in `to-learn.md` and a clear-eyed view of where the chosen stack sits.

---

## Teaching Instructions (for Claude)

**Style**: Caveman-ultra is the user's default. Drop articles, use fragments, keep technical precision. Code blocks unchanged. Console steps numbered.

**Per sprint cadence**:
1. Restate the goal + read the Session State
2. Walk through the sprint's "Activities" sequentially; at each step, ask the user to do the action, then verify (via screenshot or describing what they see)
3. After main activities, present the **"Here we could also use X"** subsection briefly (~3-5 sentences total)
4. Run the quiz checkpoint if one exists; do NOT just give the answer — ask, wait, then correct
5. Tick the checkboxes as items complete
6. Update Session State

**Verification w/o AWS CLI**:
- Ask user to describe what they see in Console
- Ask for screenshots if ambiguous
- For IaC: walk through CloudFormation events in Console; trace failures via "Events" tab
- Trust user reporting; spot-check by asking targeted follow-up questions

**Learn-by-doing requests**: When asking the user to write a policy JSON, an SCP, or a Lambda code snippet of 5+ lines, frame it as a `Learn by Doing` block with `TODO(human)` markers in a file under `templates/`. See output style guide.

**Insights**: Drop a 2-3 point `★ Insight ─` block after teaching a concept that has a non-obvious connection to something earlier in this project or to AWS more broadly. Don't pad; only when there's real signal.

**The `/adjacent` slash command**: User may invoke at any time to surface alternatives during a sprint, not only at Sprint 8. Pull the matching section from `adjacent.md`.

---

## Session State

**Current Sprint**: Sprint 0 — Foundations
**Next Step**: First activity of Sprint 0 — "What does an AWS account actually isolate?"
**Completed Sprints**: none
**Last Updated**: 2026-05-12

### Progress Counters

- Sprint 0: 0 / 4 checkboxes
- Sprint 1: 0 / 5 checkboxes
- Sprint 2: 0 / 8 checkboxes (3 sub-tasks under role exercise)
- Sprint 3: 0 / 11 checkboxes
- Sprint 4: 0 / 9 checkboxes
- Sprint 5: 0 / 8 checkboxes
- Sprint 6: 0 / 9 checkboxes
- Sprint 7: 0 / 8 checkboxes
- Sprint 8: 0 / 4 checkboxes

### Notes for next session

- User is on work laptop; default AWS profile points to **work account, NOT** the admin account that hosts file-sharing-service. Therefore **no AWS CLI in this project**. Console + CloudFormation Console uploads only.
- User has unlimited Gmail `+aliases` for new accounts.
- file-sharing-service currently lives in the admin account (not yet an Org mgmt account). Sprint 3 converts that admin acct → mgmt acct.
