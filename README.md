# React on AWS — with AI Guardrails

A React app deployed to AWS S3 + CloudFront using Terraform and GitHub Actions.  
The twist: the entire Claude Code environment was engineered from scratch so an AI could help build and operate it — safely.

---

## Stack

React · Docker · Terraform · AWS S3 · CloudFront · GitHub Actions · Claude Code

---

## How it works

| Layer | What's inside |
|---|---|
| **App** | React SPA, Dockerized build, unit tested before every deploy |
| **Infrastructure** | Terraform — S3 (versioned, encrypted, access-logged) + CloudFront with OAC |
| **CI/CD** | GitHub Actions, OIDC auth — no stored AWS keys or secrets |
| **AI Skills** | `/deploy`, `/infra-audit`, `/tf-plan`, `/tf-apply`, `/scaffold-terraform` |
| **AI Agents** | `security-auditor`, `drift-detector`, `cost-optimizer` — run in parallel |
| **AI Hooks** | Block `terraform destroy`, `rm -rf`, pipe-to-shell attacks, agent edits to config |
| **Permissions** | AI can inspect — it cannot delete, push to git, or read secrets |

---

## Project Structure

```
my-react-app/
├── src/                  # React components and tests
├── terraform/            # AWS infrastructure (S3, CloudFront, IAM)
├── .github/workflows/    # GitHub Actions CI/CD pipeline
├── .claude/
│   ├── agents/           # security-auditor, drift-detector, cost-optimizer
│   ├── skills/           # deploy, infra-audit, tf-plan, tf-apply, scaffold-terraform
│   ├── hooks/            # command-validator, file-protector, post-tool-logger
│   └── settings.json     # permissions, hooks, MCP servers
├── CLAUDE.md             # Project spec — drives all AI decisions
└── Dockerfile
```

---

## Security highlights

- CloudFront serves via OAC — S3 bucket is never publicly exposed directly
- `github-actions-deploy` IAM role scoped to S3 read/write + CloudFront invalidation only
- OIDC authentication — zero long-lived credentials stored anywhere
- AI hooks block destructive commands at the shell level before execution
