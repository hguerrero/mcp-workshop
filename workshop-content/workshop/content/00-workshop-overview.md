---
title: "Workshop Overview"
---

# Kong MCP Workshop

Welcome to the **Kong Model Context Protocol (MCP) Workshop**! In this hands-on lab you will experience how Kong Gateway can automatically expose your existing APIs as an MCP server — making them instantly consumable by AI agents and LLM-powered clients.

## What You Will Learn

By the end of this workshop you will be able to:

1. **Use the MCP Proxy Plugin** to auto-generate an MCP server at the data plane
2. **Understand the available modes** in the MCP Proxy Plugin (`passthrough-listener`, `conversion-listener`, `conversion-only`, `listener`)
3. **Configure a set of tools** in the MCP Proxy Plugin that map to your upstream API endpoints
4. **Connect an MCP client** (Insomnia, Cursor, or Google Antigravity) to the generated MCP server and invoke tools

## How This Workshop Is Structured

| Section | What You Will Do |
|---|---|
| **Prep** | Create a Gateway Service, Route, and a Mocking Plugin to simulate a Marketplace API |
| **Setup** | Install and configure the AI MCP Proxy Plugin with two tools (users & orders) |
| **Testing** | Connect an MCP client and validate end-to-end tool invocation |

## Prerequisites

Before you begin, make sure you have:

- Access to your assigned **Konnect Control Plane** (your instructor will provide the URL and credentials)
- The **`exercises/marketplace.yaml`** file open in the editor — you will need its contents in the Mocking Plugin step
- An MCP-capable client installed: [Insomnia](https://insomnia.rest/), [Cursor](https://cursor.sh/), or [Google Gemini/Antigravity](https://developers.google.com/gemini)

> **Note:** Throughout this lab the variable `$PROXY` refers to the Proxy URL shown on your Konnect Gateway Service screen. Copy it once it is available and keep it handy.

## Architecture Overview

```
AI Client (Insomnia / Cursor / Claude)
        │  MCP protocol (SSE / HTTP)
        ▼
Kong Gateway  ──── AI MCP Proxy Plugin ────► Upstream APIs
   Route: /marketplace                        (mocked by Mocking Plugin)
        │
        ▼
  MCP Tools
  ├── marketplace-users  → GET /marketplace/users
  └── marketplace-orders → GET /marketplace/orders
```

When you are ready, click **Continue** to start building.
