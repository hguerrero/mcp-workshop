---
title: "Setup: Create the MCP Proxy Plugin"
---

# Create the MCP Proxy Plugin

The **AI MCP Proxy Plugin** is the core of this workshop. It exposes Kong-managed API endpoints as **MCP Tools**, allowing AI clients to discover and invoke them using the Model Context Protocol.

## Plugin Modes

Before configuring, it helps to understand the available modes:

| Mode | Description |
|---|---|
| `passthrough-listener` | Forwards raw MCP messages to the upstream as-is |
| `conversion-listener` | **Recommended** — Kong converts MCP tool calls into HTTP requests and calls the upstream |
| `conversion-only` | Converts MCP calls but does not start an SSE listener |
| `listener` | Starts an SSE listener without conversion |

In this workshop you will use **`conversion-listener`**, which is the most common production mode.

---

## Step 1 — Install the Plugin

From the `Marketplace-MCP-Route` detail screen:

1. Click the **Plugins** tab
2. Click **"+ New plugin"**
3. In the filter field type `mcp proxy`
4. Click the **"AI MCP Proxy"** tile

![Plugin Catalog filtered by "mcp" showing the AI MCP Proxy tile]({{<baseurl>}}/images/konnect-mcp-search.png)

## Step 2 — Select the Mode

In the **Mode** dropdown, select **`conversion-listener`**.

![AI MCP Proxy plugin config — mode set to conversion-listener, scoped to Marketplace-MCP-Route]({{<baseurl>}}/images/konnect-mcp-proxy-details-1.png)

## Step 3 — Configure Tool #1: marketplace-users

Click the **"+"** icon next to the **Tools** section to add the first tool.

### Tool #1 Details

| Field | Value |
|---|---|
| **Name** | `marketplace-users` |
| **Description** | `Gets marketplace users` |

![Tool #1 — name and description fields filled in]({{<baseurl>}}/images/konnect-mcp-proxy-details-2.png)

### Tool #1 Parameters

In the **Parameters** field paste the following JSON:

```json
[
  {
    "description": "Optional user ID",
    "in": "query",
    "name": "id",
    "required": false,
    "schema": {
      "type": "string"
    }
  }
]
```

### Tool #1 Request Mapping

| Field | Value |
|---|---|
| **Path** | `/marketplace/users` |
| **Method** | `GET` |

### Tool #1 Annotations

In the **Annotations** section, set:

| Field | Value |
|---|---|
| **Title** | `Marketplace Users` |

![Tool #1 — path=/marketplace/users, method=GET, title=Marketplace Users]({{<baseurl>}}/images/konnect-mcp-proxy-details-3.png)

---

## Step 4 — Configure Tool #2: marketplace-orders

Scroll back up to the **Tools** header and click the **"+"** icon again to add a second tool.

### Tool #2 Details

| Field | Value |
|---|---|
| **Name** | `marketplace-orders` |
| **Description** | `Gets marketplace orders` |

### Tool #2 Parameters

In the **Parameters** field paste the following JSON:

```json
[
  {
    "description": "User ID to filter orders",
    "in": "query",
    "name": "userid",
    "required": true,
    "schema": {
      "type": "string"
    }
  }
]
```

### Tool #2 Request Mapping

| Field | Value |
|---|---|
| **Path** | `/marketplace/orders` |
| **Method** | `GET` |

### Tool #2 Annotations

| Field | Value |
|---|---|
| **Title** | `Marketplace Orders` |

### Tool #2 Server Section

In the **Server** section at the bottom of Tool #2:

| Setting | Value |
|---|---|
| **Server toggle** | ✅ Enabled |
| **Tag** | *(leave empty)* |
| **Forward client headers** | ✅ Checked |

---

## Step 5 — Logging & Save

In the **Logging** section:

| Setting | Value |
|---|---|
| **Log statistics** | ✅ Checked |

![Logging section — statistics, payloads, and audits checked]({{<baseurl>}}/images/konnect-mcp-proxy-details-4.png)

Click **"Show additional settings"** and fill in:

| Field | Value |
|---|---|
| **Instance Name** | `Marketplace-MCP-Proxy` |
| **Tags** | `mcp` |

![Instance name set to "marketplace-mcp-proxy" — Save button visible]({{<baseurl>}}/images/konnect-mcp-proxy-details-5.png)

Click the **"Save"** button.

---

## Checkpoint ✅

After saving, the `Marketplace-MCP-Route` Plugins tab should show:

| Plugin | Enabled |
|---|---|
| `Marketplace-MCP-Mock` (Mocking) | ✅ |
| `Marketplace-MCP-Proxy` (AI MCP Proxy) | ✅ |

Your Kong route is now an MCP server exposing two tools: `marketplace-users` and `marketplace-orders`.

Click **Continue** to connect an MCP client and test the tools.
