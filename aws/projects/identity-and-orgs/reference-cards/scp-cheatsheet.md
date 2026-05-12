# SCP Cheatsheet

## What an SCP is (and isn't)

- **Is**: a max-permissions filter for accounts in an Org. Same JSON syntax as IAM.
- **Isn't**: a permission grant. SCPs alone allow nothing; IAM still has to grant within the filtered set.
- **Scope**: attached at Root, OU, or individual account. Inherits down the tree.
- **Exempt**: mgmt account is never affected by SCPs.

## Two strategies

### Allow-list (whitelist)
Replace `FullAWSAccess` w/ a custom SCP listing exactly what's allowed. **Strict but brittle** — every new service requires an SCP edit.

### Deny-list (blacklist)
Keep `FullAWSAccess` attached. Layer additional SCPs that explicitly Deny certain things. **Pragmatic default for most orgs.**

## Common guardrails

### 1. Region lock (deny outside allowed regions)

```json
{
  "Version": "2012-10-17",
  "Statement": [{
    "Sid": "DenyOutsideApprovedRegions",
    "Effect": "Deny",
    "NotAction": [
      "iam:*", "organizations:*", "route53:*",
      "cloudfront:*", "waf:*", "wafv2:*", "shield:*",
      "globalaccelerator:*", "support:*",
      "sts:GetCallerIdentity", "sts:GetSessionToken"
    ],
    "Resource": "*",
    "Condition": {
      "StringNotEquals": {
        "aws:RequestedRegion": ["us-east-1", "eu-west-1"]
      }
    }
  }]
}
```

`NotAction` exempts global services (IAM, Route 53, CloudFront, ...) which are region-less; without this they'd be denied because their requests appear to use `us-east-1` arbitrarily.

### 2. Deny root user

```json
{
  "Sid": "DenyAllExceptListedIfRoot",
  "Effect": "Deny",
  "Action": "*",
  "Resource": "*",
  "Condition": {
    "StringLike": {
      "aws:PrincipalArn": "arn:aws:iam::*:root"
    }
  }
}
```

### 3. Deny disabling CloudTrail

```json
{
  "Sid": "ProtectCloudTrail",
  "Effect": "Deny",
  "Action": [
    "cloudtrail:StopLogging",
    "cloudtrail:DeleteTrail",
    "cloudtrail:UpdateTrail",
    "cloudtrail:PutEventSelectors"
  ],
  "Resource": "*"
}
```

### 4. Deny leaving the Org

```json
{
  "Sid": "DenyOrgLeave",
  "Effect": "Deny",
  "Action": "organizations:LeaveOrganization",
  "Resource": "*"
}
```

### 5. Deny public S3 buckets

```json
{
  "Effect": "Deny",
  "Action": ["s3:PutBucketAcl", "s3:PutBucketPolicy"],
  "Resource": "*",
  "Condition": {
    "Bool": { "s3:x-amz-acl": "public-read" }
  }
}
```

(For complete "no public S3 ever" coverage, use an **RCP** instead — it works on the resource side.)

### 6. Restrict EC2 instance types (cost control)

```json
{
  "Effect": "Deny",
  "Action": "ec2:RunInstances",
  "Resource": "arn:aws:ec2:*:*:instance/*",
  "Condition": {
    "StringNotEquals": {
      "ec2:InstanceType": ["t3.micro", "t3.small", "t3.medium"]
    }
  }
}
```

## Pitfalls

- **An OU w/ no SCP attached implicitly has `FullAWSAccess`**. Detaching it w/o replacement = total lockout for the OU.
- **SCPs use the same JSON as IAM but Effect: Allow means "in the allowed set", not "granted"**. To actually let a principal do something, IAM still needs to allow it.
- **Mgmt acct is exempt**. SCP at Root OU does NOT constrain mgmt. Use IAM there.
- **Service-linked roles** can sometimes bypass SCPs (e.g., for Org-managed services). Check `aws:ViaAWSService` if you need to allow them.
- **Test SCPs in Sandbox OU first**. Attaching a bad SCP to Workloads can lock out prod traffic instantly.
- **Inheritance**: child OU/account gets the **intersection** of all SCPs in its chain. A Deny anywhere up the tree = Deny.

## Testing an SCP w/o breaking things

1. Attach to **Sandbox OU** first.
2. Try the denied action in Sandbox acct — confirm "explicit deny" error w/ `AccessDeniedException`.
3. Move SCP to Workloads OU once verified.
4. Use **IAM Access Analyzer (Policy validation)** in Console to validate JSON before attaching.
