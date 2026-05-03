---
title: "Workshop Overview"
---

# Kong MCP Workshop — Passthrough + Auth

Welcome to the second Kong MCP workshop! In this lab the upstream is already a real MCP server — the **Konnect MCP Server** at `us.mcp.konghq.com`. Kong's role is not to generate an MCP server, but to **protect and govern** access to one that already exists.

You will add three plugins to a single route — in this order — using the Konnect UI:

1. **AI MCP Proxy** in `passthrough-listener` mode — relay MCP traffic transparently to the upstream
2. **Request Transformer Advanced** — inject the upstream system account PAT from Konnect Vault
3. **AI MCP OAuth2** — validate developer JWTs issued by the Kong Identity auth server

The end result: developers authenticate with their IDE using OAuth2/PKCE against Kong Identity, while the upstream PAT stays locked in Vault — clients never see or handle it.

## Architecture

```
IDE Client (VSCode / Cursor / Claude Code)
         │  Bearer <jwt>  (OAuth2 PKCE via Kong Identity)
         ▼
Kong Gateway — Route: /konnect-mcp-server
  ┌───────────────────────────────────────────────────┐
  │  ① ai-mcp-oauth2       → validate JWT             │
  │  ② request-transformer → inject upstream PAT      │
  │  ③ ai-mcp-proxy        → relay MCP traffic        │
  └───────────────────────────────────────────────────┘
         │  Authorization: Bearer spat_...
         ▼
   Konnect MCP Server (us.mcp.konghq.com)
```

> **Plugin ordering:** Kong enforces execution priority automatically. OAuth2 always runs first regardless of the order you add plugins in the UI.

## Prerequisites

Before you begin, make sure you have:

- Access to your assigned **Konnect Control Plane** — URL and credentials provided by your instructor
- The following values from your instructor:

| Variable | Description |
|---|---|
| `$PROXY` | Your Konnect Gateway Proxy URL |
| `$KONG_IDENTITY_ISSUER` | OIDC issuer URL of the provisioned Kong Identity auth server |
| `$KONG_MCP_CLIENT_ID` | Client ID of the pre-registered MCP public application |

- An IDE with MCP support: [VSCode](https://code.visualstudio.com/), [Cursor](https://cursor.sh/), or [Claude Code](https://claude.ai/code)
- The following resources are **pre-provisioned** in your control plane — you do not need to create them:
  - Konnect Vault `ai` with secret `konnect-mcp-spat` (system account PAT for `us.mcp.konghq.com`)
  - Kong Identity auth server with a public PKCE client (`$KONG_MCP_CLIENT_ID`)

> **Background:** If you haven't done Workshop 1 (Conversion Listener), that's fine — this workshop is self-contained. Workshop 1 covers a different pattern (`conversion-listener` mode for REST APIs) and is not a prerequisite.

## Workshop Series

This is **Workshop 2 of 3** in the Kong MCP series:

| Workshop | Pattern | What you build |
|---|---|---|
| 1 — Conversion Listener | REST → MCP | Marketplace mock API as MCP tools |
| **2 — Passthrough + Auth** *(this one)* | Proxy an MCP server + OAuth2 | Konnect MCP Server behind Kong Identity |
| 3 — Registry & Governance | Centralized discovery | MCP Registry served via Kong for IDE auto-consume |

Click **Continue** to create the Gateway Service and Route.
