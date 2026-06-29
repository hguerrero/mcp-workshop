# Kong MCP Workshop

Hands-on Educates workshop series covering how Kong Gateway handles **Model Context Protocol (MCP)** traffic — from exposing REST APIs as AI tools all the way to centrally governing MCP server distribution across an engineering org.

The series is split into three independent labs. Each can be run on its own; Labs 2 and 3 build naturally on top of the concepts from the previous one.

---

## Workshop Series

| Lab | Title | Focus | Steps |
|-----|-------|-------|-------|
| [Lab 1](workshops/lab1-conversion-listener/) | **Conversion Listener** | Turn any REST API into an MCP server using Kong's AI MCP Proxy Plugin in `conversion-listener` mode. No upstream changes required. | 7 |
| [Lab 2](workshops/lab2-passthrough-auth/) | **Passthrough + Auth** | Front an existing MCP server with Kong in `passthrough-listener` mode, inject upstream credentials from Konnect Vault, and enforce OAuth2/PKCE via Kong Identity. | 7 |
| [Lab 3](workshops/lab3-mcp-registry/) | **Registry & Governance** | Centralize MCP server distribution with the Konnect MCP Registry. Publish server entries and expose the registry read-only through Kong so IDEs auto-discover approved servers. | 6 |

---

## Repository Layout

```
kong-mcp-workshop/
├── workshops/
│   ├── lab1-conversion-listener/
│   │   ├── resources/workshop.yaml       # Educates Workshop CRD
│   │   └── workshop/
│   │       ├── config.yaml               # Hugo pathway & nav
│   │       ├── content/                  # Markdown pages (00–06)
│   │       └── static/images/            # Screenshot assets for Lab 1
│   │
│   ├── lab2-passthrough-auth/
│   │   ├── resources/workshop.yaml
│   │   └── workshop/
│   │       ├── config.yaml
│   │       ├── content/                  # Markdown pages (00–06)
│   │       └── static/images/            # Screenshot assets for Lab 2
│   │
│   └── lab3-mcp-registry/
│       ├── resources/workshop.yaml
│       └── workshop/
│           ├── config.yaml
│           ├── content/                  # Markdown pages (00–05)
│           └── static/images/            # Screenshot assets for Lab 3
│
└── terraform/                        # Instructor: provision per-student Konnect environments
    ├── main.tf
    ├── variables.tf
    ├── outputs.tf
    ├── provider.tf
    └── terraform.tfvars.example
```

---

## Prerequisites

### For Students

Each lab specifies its own prerequisites in the Workshop Overview page. The common requirements are:

- A Konnect account with a provisioned Serverless Gateway (provided by the instructor)
- Access to the Konnect UI
- An MCP-capable IDE: [Cursor](https://cursor.sh), [VS Code](https://code.visualstudio.com) with Copilot, or [Claude Code](https://claude.ai/code)

### For Instructors

Before running a session you need to provision one isolated Konnect environment per student. The [`terraform/`](terraform/) module handles this. Each student environment includes a Konnect Serverless Gateway, a Kong Identity auth server and pre-registered client application, and a Konnect Config Store and Vault (prefix `ai`) for upstream secret injection.

**Quick start:**

```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars — set konnect_personal_access_token and student_count
terraform init
terraform plan
terraform apply
```

After `apply`, extract the per-student values to distribute:

```bash
terraform output serverless_gateway_urls        # → $PROXY per student
terraform output auth_server_urls               # → $KONG_IDENTITY_ISSUER per student
terraform output application_client_ids         # → $KONG_MCP_CLIENT_ID per student
terraform output -json system_account_access_token  # → $KONNECT_TOKEN
```

The Educates cluster that serves the lab instructions is provisioned separately (GKE + Educates operator). Refer to your internal cluster setup documentation.

> **Note:** Terraform provisions the **Konnect infrastructure** (gateways, auth servers, vaults). The workshop instructions themselves — the step-by-step lab content students follow — are delivered via the Educates platform. See the next section for how to publish and deploy those.

---

## Publishing & Deploying the Workshop Content

> These steps are for publishing the **lab instructions** to an Educates cluster. They are separate from the Konnect infrastructure provisioned by Terraform above.

### Local Development

You can run the full Educates workshop stack on your laptop using a local Kind cluster. This lets you preview and iterate on content without pushing to a remote registry or cluster.

#### Prerequisites

- [Docker Desktop](https://www.docker.com/products/docker-desktop/) (or equivalent container runtime)
- [Educates CLI](https://docs.educates.dev/en/stable/installation-guides/cli-based-installation.html) — install via the GitHub releases page

#### 1. Create the local cluster

This spins up a Kind-based Kubernetes cluster and deploys Educates, including a local image registry at `localhost:5001`:

```bash
educates create-cluster --domain 127-0-0-1.sslip.io
```

> The cluster uses a `sslip.io` wildcard domain by default. Workshops are accessible in your browser without any additional DNS configuration.

#### 2. Publish and deploy a lab

Run these commands from the repo root. Repeat for whichever lab(s) you want to test:

```bash
# Lab 1
educates publish-workshop --name lab-mcp-conversion
educates deploy-workshop --file workshops/lab1-conversion-listener/resources/workshop.yaml

# Lab 2
educates publish-workshop --name lab-mcp-passthrough
educates deploy-workshop --file workshops/lab2-passthrough-auth/resources/workshop.yaml

# Lab 3
educates publish-workshop --name lab-mcp-registry
educates deploy-workshop --file workshops/lab3-mcp-registry/resources/workshop.yaml
```

`educates publish-workshop` pushes the workshop OCI image to `localhost:5001`. `educates deploy-workshop` registers the workshop with the local training portal, which will print the URL where you can open the lab.

#### 3. List workshops and open the training portal

To see every workshop currently deployed to the local cluster:

```bash
educates list-workshops
```

This prints each workshop name, its URL, and current status. To open the training portal directly in your browser — where you can start a session for any deployed lab:

```bash
educates browse-workshops
```

If prompted for credentials, retrieve the generated password with:

```bash
educates view-credentials
```

The training portal is also where you end an active session and start a fresh one to pick up republished content.

#### 4. Tear down

```bash
educates delete-cluster
```

To also remove the local image registry and DNS resolver:

```bash
educates delete-cluster --all
```

### Further reading

- [Local Environment](https://docs.educates.dev/en/stable/getting-started/local-environment.html) — cluster creation, custom domains, image mirrors
- [Working on Content](https://docs.educates.dev/en/stable/workshop-content/working-on-content.html) — live updates, error logs, serve-workshop proxy options

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

Screenshot assets live in each lab's `workshop/static/images/` directory. Content pages reference them as `{{<baseurl>}}/images/filename.png`. When updating a screenshot, replace the file in the `static/images/` directory of every lab that uses it. Keep filenames stable so existing references don't break.
