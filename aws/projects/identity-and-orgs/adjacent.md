# Adjacent Tech — Identity & Multi-Account

Alternatives to what we build in this project. Browse anytime via `/adjacent identity-and-orgs`.

Categorized by **what they replace**. Each entry: one-line description, when to pick it, when not to.

---

## Replaces: AWS Organizations + manual account vending

### AWS Control Tower
Managed multi-acct blueprint. Sets up Org + IdC + baseline SCPs + account factory + log archive + audit account, all via wizard.
- **Pick when**: starting from scratch and want AWS's opinionated landing zone w/o reinventing it.
- **Skip when**: you already have a custom Org (Control Tower is hard to retrofit), or you need a non-standard OU structure.

### Account Factory for Terraform (AFT)
Control Tower's IaC layer. Define account requests in Terraform, AFT provisions + bootstraps them.
- **Pick when**: you have many accts to vend and want it in code, w/ a pipeline.
- **Skip when**: you have <10 accts total. Control Tower's Console-based Account Factory is enough.

### Terraform `aws_organizations_*` resources (raw)
Build the Org yourself in Terraform: `aws_organizations_organization`, `_account`, `_organizational_unit`, `_policy`.
- **Pick when**: you want full control and your team is Terraform-fluent.
- **Skip when**: you want AWS to maintain the baseline blueprint for you (use Control Tower instead).

---

## Replaces: IAM Identity Center

### Direct SAML 2.0 / OIDC federation to IAM (no IdC)
Configure SAML/OIDC trust on each IAM role; users log in via your IdP and assume those roles directly.
- **Pick when**: legacy setup; you have <5 accounts and a corporate IdP already.
- **Skip when**: starting fresh — use IdC. It's strictly more capable.

### Okta / Entra ID / Google Workspace as identity source for IdC
Replace IdC's native directory w/ your corporate IdP. SCIM provisions users.
- **Pick when**: company already has the IdP. Single source of truth for joiners/leavers.
- **Skip when**: solo / hobby setup. Native IdC directory is fine.

### Cognito for human admin login
You could (mis)use Cognito User Pools to gate AWS Console access via custom federation.
- **Pick when**: never. Cognito is for app users, not for admin federation. Use IdC.

---

## Replaces: SCPs

### Permission Boundaries
Set on individual IAM principals. Caps what that principal can do regardless of identity policy.
- **Pick when**: you can't move the workload into a separate account but want to cap a role's max permissions.
- **Skip when**: account isolation is feasible. Boundaries are per-principal — they don't help if a different role does the same thing.

### Resource Control Policies (RCPs)
Org-level deny rules attached to resources (S3, SQS, KMS, etc.), not principals.
- **Pick when**: "no public S3 in this org, ever, no matter who". Catches even cross-account access.
- **Skip when**: you only need principal-side constraints. RCPs and SCPs compose, often used together.

### Config Rules + Auto-Remediation
Detect violations after the fact w/ AWS Config rules; auto-fix via Systems Manager / Lambda.
- **Pick when**: you want detect-and-correct, not prevent. Useful for policies SCPs can't express.
- **Skip when**: prevention is required (e.g., compliance). Use SCPs first.

---

## Replaces: Cross-Account Role Assumption

### AWS RAM (Resource Access Manager)
Share resources (VPC subnets, Route 53 zones, Glue Catalog, Transit Gateway, etc.) across accounts w/o role assumption.
- **Pick when**: you want acct B to use a network/data resource from acct A directly, not via API call.
- **Skip when**: you need a principal in B to act on resources in A (use role assumption).

### EventBridge cross-account event buses
Push events from acct A to acct B's event bus; B reacts. No pull, no role assumption.
- **Pick when**: event-driven integration. e.g., "Workloads emits, Security audits".
- **Skip when**: you need synchronous read/write (use role assumption).

### S3 Cross-Account bucket policies (no role assumption)
Allow another acct's principal directly in the bucket policy. They use their own identity (no AssumeRole).
- **Pick when**: simple object-level cross-acct sharing. No role hop needed.
- **Skip when**: you need server-side identity ("acted on behalf of"). Bucket policy gives B's principal full identity; role assumption produces a session w/ traceable assume.

---

## Replaces: IAM (the whole authorization model, for app-level perms)

### AWS Verified Permissions
External authz service using Cedar language. Decisions like "can user X share file Y w/ team Z?" — fine-grained, in-app.
- **Pick when**: building multi-tenant SaaS w/ rich permission semantics. file-sharing-service is a candidate (share-with-team logic).
- **Skip when**: AWS-resource-level perms (use IAM). Verified Permissions is for *your app's* authz, not AWS's.

### Open Policy Agent (OPA) / Cedar standalone
Self-hosted policy engines. Verified Permissions is essentially Cedar as a service.
- **Pick when**: multi-cloud, want portable policies.
- **Skip when**: AWS-only and managed service is acceptable.

### ABAC (attribute-based) within IAM
Don't replace IAM — change how you use it. Tag principals + resources, write `aws:PrincipalTag = aws:ResourceTag` conditions.
- **Pick when**: you have >50 roles and identity policies explode w/ per-resource patterns.
- **Skip when**: small setup. ABAC has a learning cliff and requires tag discipline.

---

## Replaces: CloudFormation StackSets

### Terraform w/ multi-acct providers
`provider "aws" { alias = "prod" }` pattern; deploy same stack to many accts from one Terraform repo.
- **Pick when**: company is Terraform-shop already.
- **Skip when**: you want AWS-native (CFN/StackSets) or you want stack-instance-level retry semantics StackSets gives you.

### CDK w/ multi-stack deploys
Define stacks in TypeScript/Python; `cdk deploy --all` across accts via cross-acct trust.
- **Pick when**: you prefer code over YAML and want CFN semantics.
- **Skip when**: ops team writes infra (CFN/Terraform are more accessible).

### Pulumi
Same idea as CDK but multi-cloud + multiple languages.
- **Pick when**: multi-cloud.
- **Skip when**: AWS-only.

---

## Quick-Pick Matrix

| Need | Default (we build) | When the alternative wins |
|------|--------------------|---------------------------|
| Multi-account skeleton | Organizations + manual OUs | Control Tower (greenfield, opinionated OK) |
| Human SSO | IAM Identity Center | Existing Okta/Entra as IdC source |
| Org-wide deny | SCP | RCP (resource-scoped), Permission Boundary (principal-scoped) |
| Cross-acct API | sts:AssumeRole | RAM (resource share), EventBridge (event push), S3 cross-acct bucket policy (sync read) |
| App-level authz | IAM (poorly) | Verified Permissions / Cedar |
| Multi-acct deploy | CloudFormation StackSets | Terraform multi-provider, CDK multi-stack |
| Account vending | Console (Sprint 3) | AFT (IaC), Control Tower Account Factory (Console+wizard) |

---

## When you finish Sprint 8

Pick 1-2 from above that you'd actually use in real work. Claude will add them to `to-learn.md` w/ today's date so future sessions can pick them up.

Recommendations based on file-sharing-service's trajectory:
- **Verified Permissions** — file-sharing has share-with-team semantics; classic Cedar use case.
- **Control Tower** — if you ever do this for real at a company, start there.
- **RAM** — if file-sharing grows to have a separate "shared services" acct hosting Route 53 + ACM certs.
