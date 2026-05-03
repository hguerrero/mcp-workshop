---
title: "Point IDE Clients at the Registry"
---

# Point IDE Clients at the Registry

With the registry live and accessible via Kong, you can now update client configurations to reference it. Once the `gallery` field is set, IDEs pull server metadata from the registry automatically — no more manual URL management.

---

## VSCode

Update the MCP config file you created in Lab 2 (`~/Library/Application Support/Code/User/mcp.json` or `.vscode/mcp.json`) to add the `gallery` and `version` fields:

```json
{
  "servers": {
    "kong-mcp-workshop": {
      "type": "http",
      "url": "$PROXY/konnect-mcp-server",
      "gallery": "$PROXY/se-registry/servers",
      "version": "1.0.0"
    }
  }
}
```

Replace `$PROXY` with your actual proxy URL.

### What `gallery` and `version` Do

| Field | Effect |
|---|---|
| `gallery` | The registry URL VSCode queries for server metadata and updates |
| `version` | The version of the server entry to use from the registry |

When VSCode starts, it fetches `$PROXY/se-registry/servers`, finds the `io.kong/konnect-mcp` entry at version `1.0.0`, and uses the `remotes[0].url` from the registry as the canonical endpoint URL. If the registry entry is updated to `1.0.1` with a new URL, VSCode picks it up automatically on next start — without any config change on the developer's side.

### Enforcing Registry-Only Access

When your organization's VSCode policy sets `chat.mcp.access=registry`, VSCode will **only accept** servers whose `gallery` URL matches an approved registry. Any server without a matching `gallery` entry is rejected — this is the governance enforcement point that prevents shadow MCP usage.

Developers cannot bypass this by editing their `mcp.json` without the `gallery` field once the policy is applied.

---

## Cursor

Cursor does not currently support a native `gallery` field in its MCP config. The recommended approach is to keep the `mcp-remote` configuration from Lab 2 unchanged, and separately communicate new server URLs to developers via your registry's web UI or internal documentation.

```json
{
  "mcpServers": {
    "kong-mcp-workshop": {
      "command": "npx",
      "args": [
        "-y",
        "mcp-remote",
        "$PROXY/konnect-mcp-server",
        "33419",
        "--static-oauth-client-info",
        "{\"client_id\":\"$KONG_MCP_CLIENT_ID\"}"
      ]
    }
  }
}
```

> Watch for native registry support in future Cursor releases.

---

## Claude Code

Claude Code does not yet have a `gallery` field in `.mcp.json`. As with Cursor, keep the Lab 2 config as-is. The registry still benefits Claude Code users indirectly — it provides a single source of truth for URL and version that your team can reference when updating configs manually.

```json
{
  "mcpServers": {
    "kong-mcp-workshop": {
      "type": "http",
      "url": "$PROXY/konnect-mcp-server",
      "oauth": {
        "clientId": "$KONG_MCP_CLIENT_ID",
        "callbackPort": 33420,
        "scopes": "openid"
      }
    }
  }
}
```

---

## Verifying Registry-Driven Discovery in VSCode

After saving the updated `mcp.json`:

1. Open the Command Palette: `Cmd+Shift+P` → **MCP: List Servers**
2. The `kong-mcp-workshop` server should show a **version badge** (e.g., `1.0.0`) next to its name, indicating it was sourced from the registry
3. Hover over the server — the tooltip should display the `description` field from the registry entry: *"Kong Konnect Admin API exposed via Kong Gateway..."*

If the version badge is missing, confirm the `gallery` URL is reachable (`curl -s $PROXY/se-registry/servers`) and that the entry `name` in the registry (`io.kong/konnect-mcp`) matches the server name in `mcp.json`.

---

## Governance Checklist

Before rolling this out to your full team:

- [ ] Confirm `$PROXY/se-registry/servers` is publicly accessible (or accessible to all developers on the network)
- [ ] Confirm the registry read PAT (`konnect-mcp-registry-pat`) vault secret is scoped to **Viewer** only — never Admin
- [ ] Publish all team-approved MCP servers to the registry before enforcing `chat.mcp.access=registry`
- [ ] Document the `$KONG_MCP_CLIENT_ID` for developers — they will need it for the initial VSCode client registration prompt
- [ ] Agree on a version bump cadence — increment `version` whenever the server URL or behavior changes

---

## Checkpoint ✅

- VSCode `mcp.json` updated with `gallery` and `version` fields
- VSCode shows the server with a version badge sourced from the registry
- `$PROXY/se-registry/servers` returns your published entry

Click **Continue** for the final workshop summary.
