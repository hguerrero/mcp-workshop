---
title: "Testing: Connect an MCP Client"
---

# Connect an MCP Client

Your Kong route is now a fully functional MCP server. In this step you will point an MCP-capable client at it and invoke the tools you configured.

The MCP server URL for all clients is:

```
$PROXY/marketplace
```

> Replace `$PROXY` with your actual Kong Proxy URL (e.g., `https://kong-abc123.konghq.com`).

---

## Option A — Insomnia

Insomnia supports MCP natively through its **MCP Server Manager**.

1. Open Insomnia and create a new **MCP Collection**
2. Click the **MCP Server Manager** icon in the sidebar
3. Click **"Add server"** and enter the URL:
   ```
   $PROXY/marketplace
   ```
4. Once connected, the tool list will show:
   - `marketplace-orders` — *Gets marketplace orders*
   - `marketplace-users` — *Gets marketplace users*
5. Select `marketplace-users` and click **"Call Tool"** — you should receive a list of users
6. Select `marketplace-orders`, provide a `userid` (e.g., `1`), and click **"Call Tool"**

---

## Option B — Google Antigravity / Gemini

Add the following to your MCP servers configuration file:

```json
{
  "mcpServers": {
    "marketplace": {
      "serverURL": "https://YOUR-PROXY-HERE/marketplace"
    }
  }
}
```

Replace `YOUR-PROXY-HERE` with your actual Kong Proxy hostname.

---

## Option C — Cursor

Add the following block to your Cursor MCP configuration (`~/.cursor/mcp.json` or the project-level `.cursor/mcp.json`):

```json
{
  "marketplace": {
    "transport": "http",
    "timeout": 30000,
    "restartOnExit": true,
    "restartDelay": 1000,
    "restartOnError": true,
    "url": "http://YOUR-PROXY-HERE/marketplace"
  }
}
```

After saving, open a Cursor chat window. You should see `marketplace` listed as an available MCP server with **2 / 2 tools** loaded.

---

## Validating Tool Invocation

Regardless of the client you use, try the following invocations:

### Get all marketplace users

```
Tool: marketplace-users
Parameters: (none)
```

Expected response: a JSON array of user objects with `id`, `username`, and `email`.

### Get orders for a specific user

```
Tool: marketplace-orders
Parameters:
  userid: "1"
```

Expected response: a JSON array of order objects with `id`, `userid`, `product`, `quantity`, and `status`.

---

## Troubleshooting

| Symptom | Likely Cause | Fix |
|---|---|---|
| Connection refused | Wrong proxy URL | Copy the Proxy URL from the Konnect service screen |
| `404 Not Found` | Path mismatch | Ensure the MCP server URL ends with `/marketplace` |
| Empty tool list | Plugin not saved | Go back and verify `Marketplace-MCP-Proxy` is enabled |
| Tool call returns error | Parameter missing | Check `userid` is provided for `marketplace-orders` |

Click **Continue** for the workshop summary.
