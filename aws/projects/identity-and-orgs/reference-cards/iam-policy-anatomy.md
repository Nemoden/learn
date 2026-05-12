# IAM Policy Anatomy

## The 6 policy types

| Type | Attached to | Grants? | Constrains? | Crosses account? |
|------|-------------|---------|-------------|------------------|
| **Identity** | user/group/role | yes | no | no |
| **Resource** | resource (S3 bucket, SNS topic, KMS key, ...) | yes | no | yes |
| **SCP** | Org root / OU / account | no | yes (max) | applies org-wide |
| **Permission Boundary** | user/role | no | yes (max for that principal) | no |
| **Session** | session at assume-role time | no | yes (max for that session) | no |
| **ACL** | S3 object/bucket (legacy) | yes (limited) | no | yes |

**Mnemonic**: identity + resource = grants. SCP + boundary + session = ceilings. ACL = legacy, avoid.

## Document skeleton

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "OptionalLabel",
      "Effect": "Allow" | "Deny",
      "Principal": { ... },          // resource policies only
      "Action": ["s3:GetObject"],
      "NotAction": [...],            // alternative to Action
      "Resource": ["arn:aws:s3:::bucket/*"],
      "NotResource": [...],          // alternative to Resource
      "Condition": {
        "StringEquals": { "aws:RequestedRegion": "us-east-1" }
      }
    }
  ]
}
```

## Principal block forms

```json
"Principal": "*"                                                    // anyone (rare, careful)
"Principal": { "AWS": "arn:aws:iam::111122223333:root" }            // any principal in that account
"Principal": { "AWS": "arn:aws:iam::111122223333:role/MyRole" }     // specific role
"Principal": { "Service": "lambda.amazonaws.com" }                  // AWS service
"Principal": { "Federated": "cognito-identity.amazonaws.com" }      // federated identity
"Principal": { "CanonicalUser": "abc..." }                          // S3 canonical user (legacy)
```

## Evaluation order (cross-account request)

```
1. Service Control Policy (SCP)           [target acct's org chain]
2. Resource-based policy                  [resource's policy]
3. Identity-based policy                  [caller's identity policy in caller's acct]
4. Permission Boundary                    [caller's boundary if any]
5. Session policy                         [if AssumeRole'd w/ inline policy]
```

**Rule**: any **explicit Deny** anywhere = denied. Otherwise, need explicit Allow at every step that applies.

## Common conditions

| Key | Use |
|-----|-----|
| `aws:RequestedRegion` | block actions outside allowed regions |
| `aws:PrincipalTag/<key>` | ABAC — match principal's tag |
| `aws:ResourceTag/<key>` | ABAC — match resource's tag |
| `aws:SourceArn` | scope resource policy to one specific calling resource (CloudFront, EventBridge) |
| `aws:SourceAccount` | scope resource policy to a calling account |
| `aws:MultiFactorAuthPresent` | require MFA |
| `aws:SecureTransport` | require TLS |
| `sts:ExternalId` | confused-deputy mitigation for cross-account |

## Common mistakes

- `Principal: "*"` in a trust policy w/o conditions → world-readable role. Don't.
- Confusing trust policy (who can assume) w/ permission policy (what assumed session can do).
- Resource policy alone can let acct B's principal in — but ONLY if B's identity policy also allows the action. Both sides needed for cross-account.
- `NotAction` is rarely what you want. Almost always you mean `Action` w/ explicit list.
- Forgetting `Resource: "*"` is required for actions that don't apply to a specific resource (`sts:GetCallerIdentity`, `iam:ListUsers`).
