---
title: "Workshop Summary"
---

# Workshop Summary

Congratulations — you have completed the **Kong MCP Workshop**! 🎉

## What You Built

In this lab you constructed an end-to-end MCP server powered by Kong Gateway:

| Step | What You Did |
|---|---|
| ✅ Created a Gateway Service | Registered `Marketplace-MCP-Service` pointing to a placeholder upstream |
| ✅ Added a Route | Exposed the service at `/marketplace` via `Marketplace-MCP-Route` |
| ✅ Configured the Mocking Plugin | Used an OpenAPI spec to simulate realistic Marketplace API responses |
| ✅ Installed the AI MCP Proxy Plugin | Auto-generated an MCP server in `conversion-listener` mode |
| ✅ Defined two MCP Tools | `marketplace-users` and `marketplace-orders` with typed parameters |
| ✅ Connected an MCP Client | Validated tool discovery and invocation via Insomnia, Cursor, or Antigravity |

## Key Takeaways

**Kong as an MCP gateway unlocks several powerful capabilities:**

- **Zero-code MCP servers** — any existing HTTP API behind Kong can become an MCP tool in minutes
- **Enterprise controls** — add authentication, rate limiting, or billing to your MCP endpoints using standard Kong plugins
- **Observability** — the `Log statistics` setting gives you call counts and latency data for every tool invocation
- **Multi-client compatibility** — a single Kong route can serve any MCP-compatible client (Cursor, Insomnia, Claude Desktop, etc.)

## What to Explore Next

- **Add authentication** — apply the Key Authentication or OpenID Connect plugin to your MCP route to secure tool access
- **Rate limiting** — use the Rate Limiting Advanced plugin to set per-consumer quotas on tool calls
- **Additional tools** — extend the MCP Proxy Plugin with `POST` and `DELETE` tools to cover write operations
- **Multiple MCP Servers** — create separate routes (e.g., `/supply-server`) each with their own MCP Proxy Plugin configuration
- **Passthrough mode** — if your upstream already speaks MCP, try `passthrough-listener` mode to forward protocol messages directly

## Resources

- [Kong AI MCP Proxy Plugin Docs](https://docs.konghq.com/hub/kong-inc/ai-mcp-proxy/)
- [Model Context Protocol Specification](https://modelcontextprotocol.io/)
- [Kong Konnect](https://cloud.konghq.com)
- [Educates Training Platform](https://educates.dev)

---

> **Feedback:** Let your instructor know what you found most useful — or what you'd like to see covered in a follow-up session!
