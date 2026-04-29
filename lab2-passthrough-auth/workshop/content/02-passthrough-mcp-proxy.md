---
title: "Step 1: Add MCP Proxy (Passthrough)"
---

# Step 1: Add the AI MCP Proxy Plugin (Passthrough Mode)

The first plugin to configure is **AI MCP Proxy** in `passthrough-listener` mode. In this mode Kong acts as a transparent relay — it does not translate MCP into REST. It simply forwards the MCP protocol stream to the upstream Konnect MCP Server and streams the response back to the client.

## Why Start with the MCP Proxy?

Configuring the MCP Proxy first establishes that the route *speaks MCP*. The route is now reachable and will relay traffic — just without authentication yet. This lets you verify connectivity before layering security on top.

---

## Steps

**1. Open the Plugin Catalog**

From the `konnect-mcp-server` **Route** screen (not the Service), click the **Plugins** tab, then **+ New plugin**.

**2. Find the AI MCP Proxy Plugin**

In the plugin filter, type `mcp proxy`. Click the **AI MCP Proxy** tile.

**3. Configure the Plugin**

| Field | Value |
|---|---|
| **Mode** | `passthrough-listener` |

In the **Logging** section:

| Setting | Value |
|---|---|
| **Log payloads** | ✅ Checked |
| **Log statistics** | ✅ Checked |

Expand **Show additional settings** and set:

| Field | Value |
|---|---|
| **Instance Name** | `konnect-mcp-proxy` |
| **Tags** | `mcp` |

**4. Save**

Click **Save**.

---

## Understanding Passthrough vs Conversion

| | `passthrough-listener` | `conversion-listener` |
|---|---|---|
| **Upstream type** | Real MCP server | REST API |
| **Kong translates** | No — relays as-is | Yes — MCP → HTTP |
| **Tools defined in Kong** | No (upstream owns tools) | Yes (you define each tool) |
| **When to use** | Fronting an existing MCP server | Wrapping a REST API as MCP |

---

## Verify (Optional)

At this point the route is live but unauthenticated. You can confirm the MCP endpoint is reachable with:

```bash
curl -sI -X POST $PROXY/konnect-mcp-server
# Expected: HTTP/2 401
# The 401 from the upstream means Kong reached us.mcp.konghq.com successfully.
# Auth errors from the upstream are expected here — you haven't injected the PAT yet.
```

---

## Checkpoint ✅

- Plugin `konnect-mcp-proxy` (AI MCP Proxy) is enabled on the `konnect-mcp-server` route
- Mode: `passthrough-listener`
- Log payloads + log statistics enabled

Click **Continue** to add Step 2: the Request Transformer plugin.
