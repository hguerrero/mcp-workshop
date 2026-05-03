---
title: "Publish a Server Entry"
---

# Publish the MCP Server Entry

With the registry created, you now publish the Konnect MCP server from Lab 2 as an entry. This makes it discoverable to any IDE that queries the registry.

---

## Step 1 — Create the Server Entry Payload

Create a file called `konnect-mcp-server.json` in your working directory. You can use the editor panel or paste the following into the terminal:

```bash
cat > konnect-mcp-server.json << 'EOF'
{
  "name": "io.kong/konnect-mcp",
  "title": "Kong Konnect MCP",
  "description": "Kong Konnect Admin API exposed via Kong Gateway with OAuth2/PKCE protection and system account token injection.",
  "version": "1.0.0",
  "$schema": "https://static.modelcontextprotocol.io/schemas/2025-12-11/server.schema.json",
  "remotes": [
    {
      "type": "streamable-http",
      "url": "$PROXY/konnect-mcp-server"
    }
  ]
}
EOF
```

Replace `$PROXY` with your actual Konnect Gateway Proxy URL before running.

### Payload Field Reference

| Field | Purpose |
|---|---|
| `name` | Unique identifier for this server entry in the registry. Reverse-domain format is the convention. |
| `title` | Human-readable name shown in IDE MCP panels |
| `description` | Displayed in IDE tooltips and registry UIs |
| `version` | Semantic version — increment when the URL or behavior changes |
| `$schema` | Declares conformance to the MCP server schema specification |
| `remotes[].type` | `streamable-http` for SSE-based MCP endpoints (what Kong serves) |
| `remotes[].url` | The public URL clients will connect to — your Kong proxy route |

---

## Step 2 — Publish to the Registry

```bash
curl -X POST \
  "https://klabs.us.api.konghq.com/v0/mcp-registries/se-registry/v0.1/publish" \
  -H "Authorization: Bearer $KONNECT_PUBLISH_TOKEN" \
  -H "Content-Type: application/json" \
  --data @konnect-mcp-server.json
```

A successful response returns the published entry with an assigned ID and timestamps.

> **Permissions:** this request uses `$KONNECT_PUBLISH_TOKEN` — the system account with **MCP Registry Admin** role. A regular Konnect Viewer token is not sufficient and will return `403 Forbidden`.

---

## Step 3 — Verify the Entry Is Listed

```bash
curl -s \
  "https://klabs.us.api.konghq.com/v0/mcp-registries/se-registry/v0.1/servers" \
  -H "Authorization: Bearer $KONNECT_TOKEN" | python3 -m json.tool
```

You should see `io.kong/konnect-mcp` in the `servers` array with `version: "1.0.0"` and the `remotes` URL pointing at your proxy.

---

## Updating a Published Entry

If you need to change the URL or bump the version, re-publish with the same `name` and the updated fields. The registry stores versions — clients that reference a specific `version` will continue to receive the old metadata until they update their config.

```bash
# Example: bump to 1.0.1 after rotating the proxy URL
jq '.version = "1.0.1" | .remotes[0].url = "$NEW_PROXY/konnect-mcp-server"' \
  konnect-mcp-server.json > konnect-mcp-server-v2.json

curl -X POST \
  "https://klabs.us.api.konghq.com/v0/mcp-registries/se-registry/v0.1/publish" \
  -H "Authorization: Bearer $KONNECT_PUBLISH_TOKEN" \
  -H "Content-Type: application/json" \
  --data @konnect-mcp-server-v2.json
```

---

## Checkpoint ✅

- Entry `io.kong/konnect-mcp` v1.0.0 visible in `GET .../se-registry/v0.1/servers`
- `remotes[0].url` points to your `$PROXY/konnect-mcp-server`

Click **Continue** to expose the registry through Kong so IDEs can reach it without a Konnect token.
