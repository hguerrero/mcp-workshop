---
title: "Workshop Summary"
---

# Workshop Complete — Passthrough + Auth

Well done! You have completed this workshop and secured an external MCP server with Kong Identity, PAT injection, and the AI MCP OAuth2 plugin.

---

## What You Built

| Step | What You Built |
|---|---|
| ✅ Gateway Service + Route | `konnect-mcp-server` → `us.mcp.konghq.com`, streaming-safe |
| ✅ AI MCP Proxy (`passthrough-listener`) | Kong relays MCP traffic transparently |
| ✅ Request Transformer Advanced | Upstream PAT injected from Konnect Vault (never visible to clients) |
| ✅ AI MCP OAuth2 | JWT validation against Kong Identity + OAuth metadata discovery |
| ✅ IDE clients | VSCode / Cursor / Claude Code connected via OAuth2/PKCE |

**Best for:** Fronting an existing MCP server with enterprise security and governance.

---

## Key Design Principles You Applied

**Plugin ordering matters:** In Lab 2, execution order is OAuth2 → Transformer → Proxy. Configuring plugins in the UI in a different order is fine — Kong enforces priority-based execution automatically. OAuth2 always runs first to reject unauthenticated requests early.

**Never distribute upstream credentials:** The system account PAT never leaves Kong's Vault. Clients authenticate with short-lived JWTs; Kong handles the upstream identity separately. Rotating the PAT is a single Vault update — no client reconfiguration needed.

**Buffering breaks streaming:** MCP uses Server-Sent Events. Any buffering layer (Kong, proxy, load balancer) between client and upstream will break the streaming session. Always disable request and response buffering on MCP routes.

**Two paths on one route:** The `/.well-known/oauth-protected-resource/...` path and the MCP endpoint path share a single route. This lets the `ai-mcp-oauth2` plugin serve discovery metadata and enforce auth on the same logical resource.

---

## Continue the Series

This workshop is part of a three-workshop sequence:

| Workshop | What you build |
|---|---|
| 1 — Conversion Listener | REST API exposed as MCP tools via Kong |
| **2 — Passthrough + Auth** *(complete)* | External MCP server secured with OAuth2/PKCE and Vault-backed token injection |
| **3 — Registry & Governance** | Centralized MCP server catalogue served via Kong for IDE auto-discovery |

Ask your instructor for access to **Workshop 3 — Registry & Governance** to continue the series.
