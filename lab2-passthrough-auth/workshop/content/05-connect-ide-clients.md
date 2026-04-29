---
title: "Testing: Connect IDE Clients"
---

# Connect IDE Clients with OAuth2

Your Kong route is now a fully secured MCP endpoint. IDE clients will:
1. Receive a `401` with a resource metadata URL
2. Fetch the discovery document to learn which authorization server to use
3. Run a PKCE OAuth2 flow against Kong Identity
4. Present the resulting JWT to Kong on every request

The MCP server URL for all clients is:

```
$PROXY/konnect-mcp-server
```

The client ID for the pre-registered Kong Identity application is:

```
$KONG_MCP_CLIENT_ID
```

Both values are provided by your instructor.

---

## Option A — VSCode

### Configuration

Add to your user-level or workspace-level MCP config file (`~/Library/Application Support/Code/User/mcp.json` on macOS, or `.vscode/mcp.json` in your project):

```json
{
  "servers": {
    "kong-mcp-workshop": {
      "type": "http",
      "url": "$PROXY/konnect-mcp-server"
    }
  }
}
```

Replace `$PROXY` with your actual Proxy URL.

### First-Run Flow

1. Open the Command Palette: `Cmd+Shift+P` → **MCP: List Servers** → start `kong-mcp-workshop`
2. VSCode sends a request, receives a `401` and discovers the Kong Identity auth server
3. VSCode attempts Dynamic Client Registration — Kong Identity rejects this (expected)
4. VSCode shows an **"Add Client Registration Details"** prompt
5. Paste `$KONG_MCP_CLIENT_ID` as the Client ID. Leave Client Secret **blank** (PKCE public client)
6. A browser tab opens to Kong Identity → log in with your workshop credentials
7. Consent → Allow
8. VSCode stores the token in the OS keychain. Tools populate in the MCP server list.

> VSCode caches the client ID per (auth server, resource) pair. Subsequent sessions reuse it automatically.

---

## Option B — Cursor

Cursor uses `mcp-remote` (a Node.js stdio-to-HTTP bridge) for reliable OAuth support with remote MCP servers.

### Configuration

Add to `.cursor/mcp.json` (project-level) or `~/.cursor/mcp.json` (user-level):

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

Replace `$PROXY` and `$KONG_MCP_CLIENT_ID` with your values.

> **Port 33419** is intentionally offset from VSCode's default (33418) so both can run simultaneously without port conflicts. Your instructor has pre-registered `http://localhost:33419/oauth/callback` as a redirect URI on the Kong Identity client.

### First-Run Flow

1. Cursor → Settings → Tools & MCPs → toggle `kong-mcp-workshop` on
2. `mcp-remote` starts, detects the `401`, runs discovery
3. Browser opens Kong Identity → authenticate with your workshop credentials
4. Redirect to `http://localhost:33419/oauth/callback` — `mcp-remote` captures the token
5. Tokens cached in `~/.mcp-auth/`. Tools populate in Cursor.

To force re-authentication: `rm -rf ~/.mcp-auth` and toggle the server off/on.

---

## Option C — Claude Code

Claude Code handles OAuth2/PKCE natively — no `mcp-remote` bridge needed.

### Configuration

Run from your project directory:

```bash
claude mcp add --transport http --scope project kong-mcp-workshop \
  $PROXY/konnect-mcp-server
```

Then edit the generated `.mcp.json` to pin the client ID and callback port:

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

> `callbackPort: 33420` pins the OAuth callback to the port pre-registered on the Kong Identity client. Without it, Claude Code picks a random port that Kong Identity will reject.

### First-Run Flow

1. Start Claude Code: `claude`
2. In the session: `/mcp` → select `kong-mcp-workshop` → **Authenticate**
3. A browser tab opens to Kong Identity → authenticate
4. Redirect to `http://localhost:33420/callback` — Claude Code captures the code
5. Token stored in macOS keychain. `/mcp` shows `kong-mcp-workshop` as **connected**

To re-authenticate: `/mcp` → `kong-mcp-workshop` → **Clear authentication**, then **Authenticate** again.

---

## Validating the Connection

Once connected with any client, verify the tools are available and callable:

### Check tool list

The connected MCP server should expose the Konnect MCP tools — the set depends on the system account's Konnect roles. Common examples:
- `GetService`, `ListServices`
- `GetRoute`, `ListRoutes`
- `GetPlugin`, `ListPlugins`

### Test a tool call

In your IDE's MCP panel or chat interface, try:

```
List all services in my control plane
```

The IDE will translate this into an MCP `tools/call` request. Kong will validate your JWT, inject the system account PAT, and the Konnect MCP Server will return the result.

---

## Troubleshooting

| Symptom | Likely Cause | Fix |
|---|---|---|
| `403 Invalid session` on auth start | IDE tried Dynamic Client Registration (DCR) | Provide the pre-registered `$KONG_MCP_CLIENT_ID` when prompted |
| `400 Bad Request — redirect_uri not in allowlist` | IDE used an unexpected port | Ensure you're using port 33418 (VSCode), 33419 (Cursor/mcp-remote), or 33420 (Claude Code) |
| `401` after successful auth | Vault secret missing or wrong format | Confirm `konnect-mcp-spat` secret value is the full `Authorization: Bearer spat_...` string |
| Tools list empty after connect | System account lacks required Konnect roles | Contact instructor to verify the system account's role assignments |
| SSE stream drops immediately | Response buffering enabled on the route | Go back to the route config and disable both buffering settings |

Click **Continue** for the final workshop summary.
