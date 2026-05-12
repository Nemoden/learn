# Templates

JSON snippets used in sprints. Pasted directly into AWS Console (Organizations → Policies → JSON editor; IAM → Roles → Trust relationships → Edit).

| File | Used in | Purpose |
|------|---------|---------|
| [`scp-region-lock.json`](./scp-region-lock.json) | Sprint 4 | Deny actions outside `us-east-1` and `eu-west-1`. NotAction exempts global services. |
| [`scp-deny-root.json`](./scp-deny-root.json) | Sprint 4 | Deny root-user actions + leaving the org + disabling CloudTrail/Config. |
| [`cross-acct-trust-policy.json`](./cross-acct-trust-policy.json) | Sprint 6 | Trust policy for `S3LogReader` in Workloads-Prod, allowing the Security account's role to assume with ExternalId. |

## Conventions

- All ARNs use placeholders like `SECURITY_ACCT_ID` — find/replace before pasting.
- Region lists in SCPs match the project's chosen regions; edit if you operate elsewhere.
- ExternalId values must be replaced with a real secret (generated, not guessed).

## How to apply a JSON SCP via Console

1. **AWS Organizations** → **Policies** → **Service control policies**.
2. **Create policy**, name it (e.g., `RegionLock-EU-US`).
3. Paste JSON in the editor. Console validates inline.
4. Save.
5. **Targets** tab → **Attach** → pick the OU or account.
6. Verify by attempting a denied action; expect `AccessDenied` w/ "explicit deny in service control policy".
