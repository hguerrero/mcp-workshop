---
title: "Prep: Create a Gateway Service"
---

# MCP Prep-work — Create a Gateway Service

Before configuring the MCP Proxy Plugin you need a **Gateway Service** and a **Route** for the Marketplace API. In this step you will create the service. The route is added in the next step.

> **Why a dummy upstream?** The Mocking Plugin will intercept all requests and return synthetic data, so the upstream URL never actually receives traffic. You can use any valid URL as a placeholder.

## Steps

**1. Navigate to your Konnect Control Plane**

Log in to [cloud.konghq.com](https://cloud.konghq.com) and open your assigned Control Plane. In the left-hand menu, select **Gateway Manager → Services**.

**2. Click "New Service"**

Then select **"Add a Service"** or **"+ New Service"** from the top-right corner.

**3. Fill in the Service Endpoint**

In the **Full URL** field enter:

```
https://httpbin.konghq.com
```

> This is a placeholder — the Mocking Plugin will prevent requests from ever reaching this URL.

**4. Fill in General Information**

| Field | Value |
|---|---|
| **Name** | `Marketplace-MCP-Service` |
| **Tags** | `mcp` |

Click **"Add tags"** to reveal the Tags field before filling it in.

**5. Save the Service**

Click the **"Save"** button. You will be taken to the main screen for the `Marketplace-MCP-Service` service.

> **Stay on this screen!** You will add a Route from here in the next step.

## Checkpoint ✅

Your service screen should show:
- Name: `Marketplace-MCP-Service`
- Tag: `mcp`
- An upstream URL of `https://httpbin.konghq.com`
- A prompt saying *"Add a route to this Gateway Service to start receiving traffic"*

Click **Continue** to add the route.
