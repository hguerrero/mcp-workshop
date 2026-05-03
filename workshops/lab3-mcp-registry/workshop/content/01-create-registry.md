---
title: "Create the Registry"
---

# Create the MCP Registry

The MCP Registry is created once per organization via the Konnect Labs API. This is an administrative step — in a real team, a platform engineer would do this once and then developers publish server entries into it.

---

## Step 1 — Set Your Tokens

You will need two tokens for this lab. Set them as environment variables in the terminal:

```bash
# Your personal Konnect token (or the workshop system account token provided
# by your instructor — used for creating and publishing to the registry)
export KONNECT_TOKEN=<your-token>

# The publish token (system account with MCP Registry Admin role)
# Your instructor will provide this value
export KONNECT_PUBLISH_TOKEN=<publish-token>
```

> If your instructor has provided a single token with both roles, you can set both variables to the same value.

---

## Step 2 — Create the Registry

Run the following `curl` command from a terminal:

```bash
curl -X POST "https://klabs.us.api.konghq.com/v0/mcp-registries" \
  -H "Authorization: Bearer $KONNECT_TOKEN" \
  -H "Content-Type: application/json" \
  --data '{
    "name": "se-registry",
    "display_name": "SE Registry",
    "description": "Registry for MCP servers approved for internal AI agents"
  }'
```

A successful response looks like:

```json
{
  "id": "...",
  "name": "se-registry",
  "display_name": "SE Registry",
  "description": "Registry for MCP servers approved for internal AI agents",
  "created_at": "...",
  "updated_at": "..."
}
```

> **Registry name rules:** lowercase letters, numbers, and hyphens only — no spaces. The name is used as a URL path segment, so keep it short and descriptive.

---

## Step 3 — Verify the Registry Exists

```bash
curl -s "https://klabs.us.api.konghq.com/v0/mcp-registries/se-registry" \
  -H "Authorization: Bearer $KONNECT_TOKEN" | python3 -m json.tool
```

You should see the registry object returned. If you receive a `404`, re-check the name spelling and confirm the MCP Registry feature is enabled on your Konnect organization.

---

## Understanding Registry Roles

The Konnect MCP Registry has two relevant role levels:

| Role | What It Allows |
|---|---|
| **MCP Registry Admin** | Create, publish, update, and delete server entries in the registry |
| **MCP Registry Viewer** | Read server entries — used for the Kong route in Step 3 (read-only PAT) |

The workshop system account used for the Kong route (`{vault://ai/konnect-mcp-registry-pat}`) has **Viewer** rights only. It can serve registry content to IDEs but cannot modify the registry.

---

## Checkpoint ✅

- Registry `se-registry` created and visible via `GET /v0/mcp-registries/se-registry`
- `$KONNECT_TOKEN` and `$KONNECT_PUBLISH_TOKEN` set in your terminal session

Click **Continue** to publish the Konnect MCP server entry into the registry.
