---
title: "Create Service & Route"
---

# Create a Service and Route for Passthrough

Before adding any plugins, you need a dedicated Gateway Service and Route for the Konnect MCP upstream.

## Step 1 — Create the Gateway Service

In your Konnect Control Plane, navigate to **Gateway Manager → Services → + New Service**.

Fill in the following:

| Field | Value |
|---|---|
| **Full URL** | `https://us.mcp.konghq.com` |
| **Name** | `konnect-mcp-server` |
| **Tags** | `mcp` |

Click **Save**. Stay on the service screen.

> This is a real upstream — the Konnect MCP Server. Unlike Lab 1, there is no Mocking Plugin here.

---

## Step 2 — Create the Route

From the `konnect-mcp-server` service screen, click **Add a Route**.

Fill in the **General Information**:

| Field | Value |
|---|---|
| **Name** | `konnect-mcp-server` |
| **Tags** | `mcp` |

Switch the Route Configuration to **Advanced** mode to add two paths and set streaming options.

### Paths

Add both of these paths (click **+ Add Path** after the first):

```
/konnect-mcp-server
/.well-known/oauth-protected-resource/konnect-mcp-server
```

> **Why two paths?** The second path (`/.well-known/...`) is where Kong publishes the **OAuth Protected Resource Metadata** — the discovery document that tells IDE clients which authorization server to use. IDE MCP clients follow this standard automatically when they receive a `401` with a `WWW-Authenticate: Bearer resource_metadata=...` header.

### Route Configuration

Set the following options:

| Setting | Value |
|---|---|
| **Strip Path** | ✅ Enabled |
| **Preserve Host** | ☐ Disabled |
| **Request Buffering** | ☐ Disabled |
| **Response Buffering** | ☐ Disabled |

> **Buffering must be off.** MCP uses Server-Sent Events (SSE) for streaming responses. Buffering breaks SSE by waiting for the full response before forwarding it to the client.

Click **Save**.

---

## Checkpoint ✅

| Resource | Expected Value |
|---|---|
| Service name | `konnect-mcp-server` |
| Service URL | `https://us.mcp.konghq.com` |
| Route name | `konnect-mcp-server` |
| Route paths | `/konnect-mcp-server` and `/.well-known/oauth-protected-resource/konnect-mcp-server` |
| Strip Path | Enabled |
| Buffering | Disabled |

Click **Continue** to add the first plugin: AI MCP Proxy in passthrough mode.
