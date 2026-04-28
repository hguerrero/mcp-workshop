# Kong Serverless Gateways Terraform Deployment

Minimal Terraform deployment for provisioning Kong serverless gateways for a variable number of students.

## Usage

1. Copy `terraform.tfvars.example` to `terraform.tfvars`:
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   ```

2. Edit `terraform.tfvars` and set your Konnect personal access token:
   ```hcl
   konnect_personal_access_token = "your-token-here"
   student_count = 10  # number of students
   ```

3. Initialize Terraform:
   ```bash
   terraform init
   ```

4. Preview the changes:
   ```bash
   terraform plan
   ```

5. Apply the configuration:
   ```bash
   terraform apply
   ```

## Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `konnect_personal_access_token` | Konnect PAT (required) | - |
| `konnect_api_url` | Konnect API URL | `https://us.api.konghq.com` |
| `student_count` | Number of students | 5 |
| `student_start_number` | Starting number for IDs | 1 |
| `student_name_prefix` | Prefix for student names | `student` |
| `control_plane_labels` | Labels for control planes | `{purpose: "workshop"}` |
| `control_plane_description` | Description for CPs | `Serverless gateway for workshop student` |

## Outputs

- `serverless_gateway_urls`: Map of student IDs to their gateway URLs
- `control_plane_ids`: Map of student IDs to their control plane IDs
- `control_plane_names`: Map of student IDs to their control plane names

## Notes

The serverless gateway URLs are constructed using the control plane ID pattern:
`https://<control-plane-id>.us.serverless.gateways.konggateway.com`

This follows the current Kong Konnect pattern for serverless gateways.