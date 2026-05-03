---
title: "Workshop Summary"
---

# Workshop Complete — Registry & Governance

Congratulations! You have completed the Kong MCP Registry workshop and built a centralized distribution layer for MCP servers.

---

## What You Built

| Step | What You Did |
|---|---|
| ✅ Registry created | `se-registry` via the Konnect Labs API |
| ✅ Server entry published | `io.kong/konnect-mcp` v1.0.0 pointing to your Kong proxy |
| ✅ Registry exposed via Kong | `/se-registry` route with read-only Vault-injected PAT |
| ✅ Copilot shim route | `/se-registry/servers` with URI rewrite for GitHub Copilot compatibility |
| ✅ VSCode pointed at registry | `gallery` field wired — version badge visible, governance-ready |

---

## Key Design Decisions

**Two routes, one service.** The main `/se-registry` route and the Copilot shim `/se-registry/servers` share the same upstream service (`konnect-mcp-registry-se`). This keeps the upstream URL in one place — if the Konnect Labs API path changes, you update the service definition only.

**Read-only PAT in Vault.** The `konnect-mcp-registry-pat` secret has `MCP Registry Viewer` rights only — it can serve content to IDEs but cannot publish or modify registry entries. The publish token (`$KONNECT_PUBLISH_TOKEN`) never goes near Kong or client configs.

**`version=latest` query string.** Adding `version:latest` in the Request Transformer's query string ensures IDEs always receive the most recently published version of each server entry without needing to specify a version themselves.

**`gallery` drives governance.** Once your organization enforces `chat.mcp.access=registry` in VSCode policy, any MCP server without a matching `gallery` entry is blocked. Roll out the registry before enabling the policy, or developers will lose access to their existing servers.

---

## What to Explore Next

- **Add more server entries** — publish the Lab 1 `marketplace` endpoint and any other Kong-fronted MCP servers to the same registry
- **Automate publishing** — use the Konnect Labs API in CI/CD to auto-publish new server versions on deploy
- **Enforce registry policy** — work with your IT/MDM team to push `chat.mcp.access=registry` to developer VSCode settings
- **Registry versioning** — increment `version` in published entries whenever the endpoint URL or tool schema changes; old versions remain accessible to pinned clients

---

## Resources

- [Konnect MCP Registry Docs](https://docs.konghq.com/konnect/catalog/mcp-registry/)
- [AI MCP Proxy Plugin](https://docs.konghq.com/hub/kong-inc/ai-mcp-proxy/)
- [AI MCP OAuth2 Plugin](https://docs.konghq.com/hub/kong-inc/ai-mcp-oauth2/)
- [Request Transformer Advanced](https://docs.konghq.com/hub/kong-inc/request-transformer-advanced/)
- [Konnect Vaults Reference](https://docs.konghq.com/konnect/gateway-manager/configuration/vaults/)
- [Model Context Protocol Specification](https://modelcontextprotocol.io/)
- [Kong Konnect](https://cloud.konghq.com)

---

> **Feedback:** Let your instructor know what you found most useful — or what you'd like to see in a future session.
