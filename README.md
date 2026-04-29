# Kong MCP Workshop

Hands-on Educates workshop series covering how Kong Gateway handles **Model Context Protocol (MCP)** traffic — from exposing REST APIs as AI tools all the way to centrally governing MCP server distribution across an engineering org.

The series is split into three independent labs. Each can be run on its own; Labs 2 and 3 build naturally on top of the concepts from the previous one.

---

## Workshop Series

| Lab | Title | Focus | Steps |
|-----|-------|-------|-------|
| [Lab 1](lab1-conversion-listener/) | **Conversion Listener** | Turn any REST API into an MCP server using Kong's AI MCP Proxy Plugin in `conversion-listener` mode. No upstream changes required. | 7 |
| [Lab 2](lab2-passthrough-auth/) | **Passthrough + Auth** | Front an existing MCP server with Kong in `passthrough-listener` mode, inject upstream credentials from Konnect Vault, and enforce OAuth2/PKCE via Kong Identity. | 7 |
| [Lab 3](lab3-mcp-registry/) | **Registry & Governance** | Centralize MCP server distribution with the Konnect MCP Registry. Publish server entries and expose the registry read-only through Kong so IDEs auto-discover approved servers. | 6 |

---

## Repository Layout

```
kong--mcp-workshop/
├── lab1-conversion-listener/
│   ├── resources/workshop.yaml       # Educates Workshop CRD
│   └── workshop/
│       ├── config.yaml               # Hugo pathway & nav
│       └── content/                  # Markdown pages (00–06)
│
├── lab2-passthrough-auth/
│   ├── resources/workshop.yaml
│   └── workshop/
│       ├── config.yaml
│       └── content/                  # Markdown pages (00–06)
│
├── lab3-mcp-registry/
│   ├── resources/workshop.yaml
│   └── workshop/
│       ├── config.yaml
│       └── content/                  # Markdown pages (00–05)
│
├── decK/
│   └── konnect-mcp/
│       └── config.yaml               # Declarative Kong config for Lab 2 (passthrough + auth)
│
├── terraform-serverless-gateways/    # Instructor: provision per-student environments
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
│   ├── provider.tf
│   └── terraform.tfvars.example
│
└── *.png                             # Screenshot assets used in workshop content
```

---

## Prerequisites

### For Students

Each lab specifies its own prerequisites in the Workshop Overview page. The common requirements are:

- A Konnect account with a provisioned Serverless Gateway (provided by the instructor)
- Access to the Konnect UI
- An MCP-capable IDE: [Cursor](https://cursor.sh), [VS Code](https://code.visualstudio.com) with Copilot, or [Claude Code](https://claude.ai/code)

### For Instructors

Use the Terraform module in [`terraform-serverless-gateways/`](terraform-serverless-gateways/) to provision one isolated environment per student. Each environment includes:

- A Konnect Serverless Gateway (control plane + data plane on AWS `us`)
- A Kong Identity auth server and pre-registered client application
- A Konnect Config Store and Vault (prefix `ai`) for secret injection

See the [Terraform README](terraform-serverless-gateways/README.md) for full provisioning instructions.

---

## Deploying a Workshop

Each lab is a standalone Educates workshop published as an OCI image.

### Publish (build & push the workshop image)

```bash
educates publish-workshop --name lab-mcp-conversion   # Lab 1
educates publish-workshop --name lab-mcp-passthrough  # Lab 2
educates publish-workshop --name lab-mcp-registry     # Lab 3
```

### Deploy to a cluster

```bash
educates deploy-workshop --file lab1-conversion-listener/resources/workshop.yaml
educates deploy-workshop --file lab2-passthrough-auth/resources/workshop.yaml
educates deploy-workshop --file lab3-mcp-registry/resources/workshop.yaml
```

### Automated publishing (GitHub Actions)

Each lab's `resources/workshop.yaml` references an OCI image tag tied to `$(workshop_version)`. Tag a release to trigger the Educates GitHub Actions workflow:

```bash
git tag v1.0.0
git push origin v1.0.0
```

The workflow (`educates/educates-github-actions/publish-workshop@v6`) builds and pushes the image automatically.

---

## decK Config (Lab 2)

The `decK/konnect-mcp/config.yaml` file is a ready-to-sync declarative Kong configuration for Lab 2. It covers the full three-plugin stack (AI MCP Proxy → Request Transformer Advanced → AI MCP OAuth2) and is useful for automated environment setup or as a reference when following the Konnect UI steps.

Before syncing, replace the two placeholders:

```bash
# $KONG_IDENTITY_ISSUER  — issuer URL of the provisioned Kong Identity auth server
# $KONG_PROXY_HOST       — public hostname of your Kong Gateway proxy

deck gateway sync decK/konnect-mcp/config.yaml \
  --konnect-token $KONNECT_TOKEN \
  --konnect-control-plane-name $CP_NAME
```

---

## Environment Variables Reference

Variables surfaced in the Educates session (set by the instructor at deploy time):

| Variable | Used in | Description |
|----------|---------|-------------|
| `PROXY` | Lab 1, 2, 3 | Public URL of the student's Kong Gateway proxy |
| `KONG_IDENTITY_ISSUER` | Lab 2 | OIDC issuer URL of the provisioned Kong Identity auth server |
| `KONG_MCP_CLIENT_ID` | Lab 2 | Pre-registered client application ID for IDE OAuth2 PKCE flows |
| `KONNECT_TOKEN` | Lab 3 | Konnect PAT for Viewer access to the MCP Registry |
| `KONNECT_PUBLISH_TOKEN` | Lab 3 | Konnect PAT with Admin access to publish registry entries |

---

## Contributing

Content lives in `workshop/content/*.md` for each lab. Page order is controlled by `workshop/config.yaml` — add the step name to the `steps` list and create the matching `.md` file with a `title:` frontmatter field.

Screenshot assets at the repo root are referenced from content pages using relative paths. When updating screenshots, keep filenames stable so existing references don't break.
