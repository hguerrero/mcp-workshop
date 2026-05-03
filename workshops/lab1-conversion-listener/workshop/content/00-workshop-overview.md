---
title: "Workshop Overview"
---

# Kong MCP Workshop — Conversion Listener

Welcome to the first Kong MCP workshop! In this hands-on lab you will experience how Kong Gateway can automatically expose an existing REST API as an **MCP server** — making it instantly consumable by AI agents and LLM-powered clients, with zero changes to the upstream service.

## What You Will Learn

By the end of this workshop you will be able to:

1. **Create a Gateway Service and Route** in Konnect for a mock Marketplace API
2. **Configure the Mocking Plugin** to simulate realistic API responses from an OpenAPI spec
3. **Install the AI MCP Proxy Plugin** in `conversion-listener` mode — the mode that translates REST APIs into MCP tools
4. **Define typed MCP tools** with parameters that map to upstream HTTP endpoints
5. **Connect an MCP client** (Insomnia, Cursor, or Antigravity) and invoke the tools

## Kong Gateway: Extend with Plugins

Kong's plugin system is central to everything you'll do in this workshop. The gateway overview shows the "Extend with plugins" entry point for every service and route:

![Konnect gateway overview — "Extend with plugins" call-to-action]({{<baseurl>}}/images/konnect-plguins.png)

## How Conversion Listener Works

In `conversion-listener` mode, **Kong itself becomes the MCP server**. The upstream only needs to speak HTTP — no MCP support required.

```
AI Client (Insomnia / Cursor / Antigravity)
         │  MCP protocol (tools/call)
         ▼
Kong Gateway ──── AI MCP Proxy (conversion-listener)
   Route: /marketplace
         │  Translates MCP → HTTP
         ▼
   Upstream REST API  (served by Mocking Plugin)

   MCP Tools you define:
   ├── marketplace-users  → GET /marketplace/users
   └── marketplace-orders → GET /marketplace/orders
```

## Prerequisites

Before you begin, make sure you have:

- Access to your assigned **Konnect Control Plane** — URL and credentials provided by your instructor
- An MCP-capable client installed: [Insomnia](https://insomnia.rest/), [Cursor](https://cursor.sh/), or [Google Antigravity](https://developers.google.com/gemini)
- The **`exercises/marketplace.yaml`** file open in the editor panel — you will paste its contents during the Mocking Plugin step

Your instructor has pre-provisioned one Serverless Gateway Control Plane per student. The Gateway Manager view looks like this:

![Konnect Gateway Manager showing per-student Control Planes]({{<baseurl>}}/images/konnect-cps.png)

> **`$PROXY`** — throughout this workshop, `$PROXY` refers to the Proxy URL shown on your Konnect Gateway Service screen. Copy it once it appears and keep it handy.

## Workshop Series

This is **Workshop 1 of 3** in the Kong MCP series:

| Workshop | Pattern | What you build |
|---|---|---|
| **1 — Conversion Listener** *(this one)* | REST → MCP | Marketplace mock API as MCP tools |
| 2 — Passthrough + Auth | Proxy an MCP server + OAuth2 | Konnect MCP Server behind Kong Identity |
| 3 — Registry & Governance | Centralized discovery | MCP Registry served via Kong for IDE auto-consume |

Click **Continue** to start building.
