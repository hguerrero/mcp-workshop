---
title: "Workshop Overview"
---

# Kong MCP Workshop — Registry & Governance

Welcome to the third Kong MCP workshop! In this lab you will solve the distribution problem: how do you get the right MCP servers to every developer in your organisation without asking them to manage `mcp.json` files manually?

The answer is the **Konnect MCP Registry** — a centrally managed catalogue of approved MCP servers that IDEs auto-consume.

## The Problem

After setting up one or more Kong-fronted MCP endpoints, every developer who wants to use them must:

- Know the endpoint URL exists
- Copy it into their `mcp.json` manually
- Update it when it changes
- Remove it if it's deprecated

At two servers this is manageable. At ten, across an engineering org, it becomes an untracked governance problem. Shadow MCP usage — developers wiring up unapproved external servers — is impossible to detect or block without a registry.

## What You Will Build

```
┌──────────────────────────────────────────────────────────┐
│  Konnect MCP Registry  (klabs.us.api.konghq.com)          │
│  se-registry                                             │
│  └── io.kong/konnect-mcp  v1.0.0  ← you publish this    │
└────────────────────┬─────────────────────────────────────┘
                     │  read-only PAT (Vault-injected)
                     ▼
           Kong Gateway — /se-registry
                     │
                     ▼
             IDEs auto-discover approved servers
        (VSCode gallery field, Copilot, future clients)
```

| Step | What You Will Do |
|---|---|
| **Create registry** | Call the Konnect Labs API to create `se-registry` |
| **Publish server entry** | Publish the Konnect MCP endpoint from Workshop 2 into the registry |
| **Expose via Kong** | Create a read-only Kong route that proxies registry reads with PAT injection |
| **Point IDEs at registry** | Update VSCode config with the `gallery` field for auto-discovery |

## Prerequisites

Before you begin, make sure you have:

- Access to your assigned **Konnect Control Plane** — URL and credentials provided by your instructor
- The following values from your instructor:

| Variable | Description |
|---|---|
| `$PROXY` | Your Konnect Gateway Proxy URL |
| `$KONNECT_TOKEN` | Token for creating and querying the registry |
| `$KONNECT_PUBLISH_TOKEN` | Token with MCP Registry Admin role for publishing entries |

- The following resource is **pre-provisioned** in your control plane:
  - Konnect Vault `ai` with secret `konnect-mcp-registry-pat` (read-only registry viewer PAT)

> **Background:** This workshop uses the `$PROXY/konnect-mcp-server` endpoint built in Workshop 2 as the server entry to publish. If you haven't done Workshop 2, your instructor will provide the URL to use instead.

> **Tech preview:** The Konnect MCP Registry feature is currently in Labs / tech preview. Confirm with your instructor that it is enabled on your Konnect organization.

## Workshop Series

This is **Workshop 3 of 3** in the Kong MCP series:

| Workshop | Pattern | What you build |
|---|---|---|
| 1 — Conversion Listener | REST → MCP | Marketplace mock API as MCP tools |
| 2 — Passthrough + Auth | Proxy an MCP server + OAuth2 | Konnect MCP Server behind Kong Identity |
| **3 — Registry & Governance** *(this one)* | Centralized discovery | MCP Registry served via Kong for IDE auto-consume |

Click **Continue** to create the registry.
