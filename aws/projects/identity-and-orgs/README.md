# Identity & Multi-Account on AWS

Project that takes you from **single-account IAM** to a **multi-account AWS Organization** with SSO and cross-account access, then migrates the existing `file-sharing-service` into a dedicated workload account.

**Constraint**: Console + CloudFormation/StackSets only. No AWS CLI (work-laptop default profile points elsewhere).

**Start here**: read [`plan.md`](./plan.md) — your teaching script.

## Layout

| Path | Purpose |
|------|---------|
| [`plan.md`](./plan.md) | Sprint-by-sprint teaching script (8 sprints) |
| [`architecture.md`](./architecture.md) | Diagrams: target Org tree, IAM trust chain, SSO flow |
| [`adjacent.md`](./adjacent.md) | Alternatives (Control Tower, AFT, Terraform, ABAC, Verified Permissions) |
| [`reference-cards/`](./reference-cards/) | Quick-lookup cards: IAM policy anatomy, trust vs permission, SCP, SigV4/STS |
| [`templates/`](./templates/) | Sample CloudFormation/StackSets snippets used in sprints |

## How sprints feel

Each sprint = one concrete capability added to your AWS environment. You **always come out with something that works** at the end of every sprint, even if it's just a deeper audit of what you already have.

End of project: `file-sharing-service` lives in a **Workloads** account, you log into it via the **IAM Identity Center** portal, an SCP blocks region drift, and a Lambda in a **Shared Services** account can read its S3 bucket via **cross-account role assumption**.
