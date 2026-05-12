# terraform

Terraform module for provisioning per-student Konnect environments for the Kong MCP Workshop series. Run this once before a workshop session to create an isolated, fully configured Konnect environment for each student.

## What Gets Provisioned

For each student the module creates the following resources in Konnect:

| Resource | Name pattern | Purpose |
|----------|-------------|---------|
| Serverless Gateway Control Plane | `<prefix><id>-cp` | Student's Kong Gateway (AWS `us`) |
| Cloud Gateway Configuration | — | Attaches a data plane group to the CP |
| Kong Identity Auth Server | `<prefix><id>-auth-server` | OIDC issuer for Lab 2 OAuth2/PKCE flows |
| Identity Auth Server Client | `<prefix><id>-application` | Pre-registered IDE client (`client_credentials`) |
| Config Store | `<prefix><id>-config-store` | Backing store for the Konnect Vault |
| Gateway Vault | prefix `ai` | Vault for injecting upstream credentials (`{vault://ai/...}`) |
| System Account Access Token | `workshop-access-token` | 1-year PAT for the workshop system account |

A single system account access token is created once (not per student) and is tied to the `system_account_id` variable.

---

## Prerequisites

- [Terraform](https://developer.hashicorp.com/terraform/install) ≥ 1.5
- A Konnect organisation with permission to create control planes, Identity auth servers, and system account tokens
- A Konnect Personal Access Token (PAT) with Org Admin or equivalent permissions
- The ID of a Konnect System Account to bind the workshop access token to

---

## Usage

### 1. Copy and fill in the variables file

```bash
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars` and set the two required values:

```hcl
konnect_personal_access_token = "kpat_..."   # your Konnect PAT
system_account_id             = "abc123..."  # system account UUID
```

Adjust optional values as needed:

```hcl
student_count        = 20        # how many students
student_start_number = 1         # IDs start at student01
student_name_prefix  = "student" # prefix for all resource names
```

### 2. Initialise Terraform

```bash
terraform init
```

### 3. Preview the plan

```bash
terraform plan
```

Review the output to confirm the expected number of resources (`student_count × 6 + 1`).

### 4. Apply

```bash
terraform apply
```

Type `yes` when prompted. Provisioning ~20 students typically takes 2–3 minutes.

### 5. Extract student handout data

After apply, retrieve the values you need to distribute to students:

```bash
# Gateway proxy URLs (share with students as $PROXY)
terraform output serverless_gateway_urls

# Kong Identity issuer URLs (share as $KONG_IDENTITY_ISSUER)
terraform output auth_server_urls

# Identity client IDs (share as $KONG_MCP_CLIENT_ID)
terraform output application_client_ids

# System account access token (sensitive — for instructor use)
terraform output -raw system_account_access_token
```

Sensitive outputs (`application_client_secrets`, `system_account_access_token`) are masked in plain `terraform output`. Use `-raw` or `-json` to retrieve them.

---

## Variables

| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| `konnect_personal_access_token` | ✅ | — | Konnect PAT used to authenticate the provider |
| `system_account_id` | ✅ | — | UUID of the system account to bind the workshop access token to |
| `konnect_api_url` | | `https://us.api.konghq.com` | Konnect control-plane API endpoint |
| `konnect_region` | | `us` | Konnect region (`us`, `eu`, `au`) |
| `student_count` | | `5` | Number of student environments to provision |
| `student_start_number` | | `1` | Lowest student ID number (IDs are zero-padded to 2 digits) |
| `student_name_prefix` | | `student` | String prepended to all student resource names |
| `control_plane_labels` | | `{purpose: "workshop", managed_by: "terraform"}` | Labels applied to every control plane |
| `control_plane_description` | | `Serverless gateway for workshop student` | Description text for each control plane |

---

## Outputs

| Output | Sensitive | Description |
|--------|-----------|-------------|
| `serverless_gateway_urls` | | Map of student ID → gateway proxy URL |
| `control_plane_ids` | | Map of student ID → Konnect control plane UUID |
| `control_plane_names` | | Map of student ID → control plane name |
| `auth_server_ids` | | Map of student ID → Kong Identity auth server UUID |
| `auth_server_urls` | | Map of student ID → OIDC issuer URL (`$KONG_IDENTITY_ISSUER`) |
| `application_client_ids` | | Map of student ID → OAuth2 client ID (`$KONG_MCP_CLIENT_ID`) |
| `application_client_secrets` | ✅ | Map of student ID → OAuth2 client secret |
| `config_store_ids` | | Map of student ID → config store UUID |
| `vault_ids` | | Map of student ID → vault UUID |
| `system_account_access_token` | ✅ | Workshop system account PAT (1-year expiry) |

---

## Teardown

To destroy all provisioned resources after the workshop:

```bash
terraform destroy
```

> **Note:** `terraform.tfstate` contains sensitive values (access tokens, client secrets). Do not commit it to source control — it is already listed in `.gitignore`.

---

## Provider

Uses the official [Kong Konnect Terraform provider](https://registry.terraform.io/providers/kong/konnect/latest) pinned to `~> 3.14.0`.
