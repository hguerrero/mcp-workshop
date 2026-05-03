---
title: "Prep: Add a Marketplace Route"
---

# Add a Marketplace Route

With the Gateway Service created, you now need a **Route** to expose it. The route defines which incoming requests are forwarded to the service.

## Steps

**1. Open the Route creation form**

From the `Marketplace-MCP-Service` screen, click the **"Add a Route"** button in the top-right area (or the link in the centre of the empty routes list).

**2. Fill in General Information**

| Field | Value |
|---|---|
| **Name** | `Marketplace-MCP-Route` |
| **Tags** | `mcp` |

**3. Configure the Route**

Keep the configuration mode set to **Basic** and fill in the following:

| Field | Value |
|---|---|
| **Path** | `/marketplace` |
| **Strip Path** | ✅ Checked (leave the default) |

> Leaving **Strip Path** checked means Kong will remove the `/marketplace` prefix before forwarding requests to the upstream, which keeps the mock paths clean.

**4. Save the Route**

Click the **"Save"** button.

You will land on the Route detail screen for `Marketplace-MCP-Route`, which shows its association with `Marketplace-MCP-Service`.

## Checkpoint ✅

| Property | Expected Value |
|---|---|
| Route name | `Marketplace-MCP-Route` |
| Path | `/marketplace` |
| Tags | `mcp` |
| Attached service | `Marketplace-MCP-Service` |

> **Tip:** Note the **Proxy URL** shown on the service screen — this is your `$PROXY` value. You will need it later when connecting your MCP client.

Click **Continue** to configure the Mocking Plugin on this route.
