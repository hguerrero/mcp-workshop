---
title: "Workshop Summary"
---

# Workshop Complete — Conversion Listener

Well done! You have built a fully functional MCP server from scratch using Kong's `conversion-listener` mode.

## What You Built

| Step | What You Did |
|---|---|
| ✅ Gateway Service | `Marketplace-MCP-Service` → `https://httpbin.konghq.com` (placeholder) |
| ✅ Route | `/marketplace` via `Marketplace-MCP-Route` |
| ✅ Mocking Plugin | OpenAPI spec serving synthetic users + orders data |
| ✅ AI MCP Proxy Plugin | `conversion-listener` mode with two typed tools |
| ✅ Tool: marketplace-users | `GET /marketplace/users` with optional `id` parameter |
| ✅ Tool: marketplace-orders | `GET /marketplace/orders` with required `userid` parameter |
| ✅ Client Connection | Verified tool invocation via Insomnia, Cursor, or Antigravity |

## Key Insight: Conversion Listener

In `conversion-listener` mode, **Kong itself is the MCP server**. The upstream only speaks REST. Kong:
- Receives MCP `tools/call` requests from clients
- Translates them into HTTP requests to the upstream
- Returns the HTTP response wrapped as an MCP tool result

This is ideal when you want to expose existing REST APIs as AI tools — without modifying the upstream at all.

## Continue the Series

This workshop is part of a three-workshop sequence. Each can be taken independently:

| Workshop | What you build |
|---|---|
| **1 — Conversion Listener** *(complete)* | REST API exposed as MCP tools via Kong |
| **2 — Passthrough + Auth** | External MCP server fronted by Kong with OAuth2/PKCE and Vault-backed token injection |
| **3 — Registry & Governance** | Centralized MCP server catalogue served via Kong for IDE auto-discovery |

Ask your instructor for access to **Workshop 2 — Passthrough + Auth** to continue the series.
