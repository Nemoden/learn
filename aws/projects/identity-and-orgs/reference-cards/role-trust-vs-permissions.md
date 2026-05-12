# Role: Trust Policy vs Permission Policy

The #1 IAM bug: confusing these two.

## Anatomy

A role has **exactly two** policy categories:

| Policy | Question it answers | Where attached |
|--------|---------------------|----------------|
| **Trust policy** | Who is allowed to *become* this role? | The `AssumeRolePolicyDocument` of the role |
| **Permission policies** | What can the assumed session do? | Attached as managed/inline policies to the role |

Visually:

```
              ┌────────────────────────────┐
              │           Role             │
              │  arn:aws:iam::...:role/X   │
              │                            │
   trust ────▶│ AssumeRolePolicyDocument   │◀──── permission
              │   (who may sts:AssumeRole) │      policies
              │                            │      (what session may do)
              │  + Permissions             │
              │    - inline policies       │
              │    - attached managed      │
              └────────────────────────────┘
```

## Trust policy examples

**Lambda execution role** (lambda service can assume):

```json
{
  "Version": "2012-10-17",
  "Statement": [{
    "Effect": "Allow",
    "Principal": { "Service": "lambda.amazonaws.com" },
    "Action": "sts:AssumeRole"
  }]
}
```

**Cross-account role** (acct 111 may assume):

```json
{
  "Version": "2012-10-17",
  "Statement": [{
    "Effect": "Allow",
    "Principal": { "AWS": "arn:aws:iam::111111111111:root" },
    "Action": "sts:AssumeRole",
    "Condition": {
      "StringEquals": { "sts:ExternalId": "abc123" }
    }
  }]
}
```

**EC2 instance role** (ec2 service can assume):

```json
{
  "Principal": { "Service": "ec2.amazonaws.com" },
  "Action": "sts:AssumeRole"
}
```

**Cognito federated** (Cognito identity pool):

```json
{
  "Principal": { "Federated": "cognito-identity.amazonaws.com" },
  "Action": "sts:AssumeRoleWithWebIdentity",
  "Condition": {
    "StringEquals": {
      "cognito-identity.amazonaws.com:aud": "us-east-1:abc..."
    }
  }
}
```

## Permission policies (just like identity policies)

```json
{
  "Version": "2012-10-17",
  "Statement": [{
    "Effect": "Allow",
    "Action": ["s3:GetObject", "s3:ListBucket"],
    "Resource": [
      "arn:aws:s3:::file-sharing-prod",
      "arn:aws:s3:::file-sharing-prod/*"
    ]
  }]
}
```

## Cross-account: the 2-sided handshake

**Source acct (caller side)**:
- Principal (user or role) needs identity policy allowing `sts:AssumeRole` on the target role ARN

```json
{
  "Effect": "Allow",
  "Action": "sts:AssumeRole",
  "Resource": "arn:aws:iam::TARGET-ACCT:role/CrossRole"
}
```

**Target acct (resource side)**:
- The role's trust policy must allow the source principal

```json
{
  "Effect": "Allow",
  "Principal": { "AWS": "arn:aws:iam::SOURCE-ACCT:role/CallerRole" },
  "Action": "sts:AssumeRole"
}
```

Missing either side = denied. Both required.

## Pitfalls

- **`Principal: "AWS": "...:root"`** in trust = any principal in that acct *that has the assume-role permission*. NOT just root user.
- **Trust policy can't grant permissions to the role** — it only allows assumption. The role's actions are governed by permission policies.
- **Service role vs service-linked role**:
  - **Service role**: you create it, you control its perms.
  - **Service-linked role** (`AWSServiceRoleFor...`): AWS creates + manages it; you can't usually delete the policies. Used for Org-wide service integration.
- **Lambda execution role** is just a service role for the Lambda service. Nothing special.
- **MaxSessionDuration** is set on the role, capped 12h (Lambda execution role: irrelevant b/c Lambda re-issues for every invoke).

## Quick test

If you're asked "why can't this role do X?", check in order:

1. SCP on target acct's OU — denied?
2. Resource policy on the resource — denies or doesn't allow?
3. Permission policy on the role — has the action?
4. Permission boundary on the role — caps the action?
5. Session policy (if AssumeRole'd w/ inline policy) — caps the action?

If none of those deny + 3 allows = should work. If still fails, it's almost always a `Condition` mismatch (region, MFA, source IP).
