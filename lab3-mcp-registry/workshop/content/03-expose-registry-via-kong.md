---
title: "Expose the Registry via Kong"
---

# Expose the Registry via Kong

The Konnect MCP Registry API lives at `klabs.us.api.konghq.com` and requires a Konnect Bearer token. IDE clients cannot authenticate there directly — they only have the Kong Identity JWT from Lab 2.

The solution is to create a **read-only Kong route** that proxies registry reads and injects the pre-provisioned registry PAT from Vault. IDEs query your Kong proxy URL and never need direct access to `klabs.us.api.konghq.com`.

---

## Architecture

```
IDE client (no Konnect token)
     │  GET $PROXY/se-registry/servers
     ▼
Kong Gateway — /se-registry
  request-transformer-advanced
    → adds {vault://ai/konnect-mcp-registry-pat}
     │  Authorization: Bearer spat_... (read-only)
     ▼
klabs.us.api.konghq.com/v0/mcp-registries/se-registry
```

You will create **one Gateway Service** and **two Routes** — the second is a compatibility shim for GitHub Copilot's path pattern.

---

## Step 1 — Create the Registry Gateway Service

In your Konnect Control Plane → **Gateway Manager → Services → + New Service**.

Switch to **Advanced** configuration and fill in:

| Field | Value |
|---|---|
| **Name** | `konnect-mcp-registry-se` |
| **Protocol** | `https` |
| **Host** | `klabs.us.api.konghq.com` |
| **Port** | `443` |
| **Path** | `/v0/mcp-registries/se-registry` |
| **Tags** | `mcp`, `registry` |

Click **Save**.

> The service `path` is set here rather than on the route — this keeps both routes clean and avoids repeating the long API path on each one.

---

## Step 2 — Add a CORS Plugin on the Service

IDE clients (especially browser-based ones) require CORS headers. Add this at the **Service** level so both routes inherit it.

From the `konnect-mcp-registry-se` service → **Plugins** → **+ New plugin** → search `cors`:

| Field | Value |
|---|---|
| **Origins** | `*` |
| **Methods** | `GET`, `OPTIONS` |
| **Instance Name** | `registry-cors` |
| **Tags** | `mcp`, `registry` |

Click **Save**.

---

## Step 3 — Create the Main Registry Route

From the `konnect-mcp-registry-se` service → **Add a Route**.

| Field | Value |
|---|---|
| **Name** | `konnect-mcp-registry-se-route` |
| **Path** | `/se-registry` |
| **Methods** | `GET`, `OPTIONS` |
| **Strip Path** | ✅ Enabled |
| **Tags** | `mcp`, `registry` |

Click **Save**, then go to this route's **Plugins** tab → **+ New plugin** → search `request transformer`:

Select **Request Transformer Advanced** and configure:

**Add → Headers:**
```
{vault://ai/konnect-mcp-registry-pat}
```

> **How was the vault secret stored?** The `konnect-mcp-registry-pat` secret is pre-provisioned in the `ai` vault. If you ever need to store a new secret, navigate to **Konnect Vault → ai → Store New Secret** and fill in the key and value fields:

![Vault detail — "Store New Secret" button]({{<baseurl>}}/images/konnect-new-secret.png)

![New Secret form — key "konnect-mcp-spat", value is the full "Authorization: Bearer ..." string]({{<baseurl>}}/images/konnect-new-secret-details.png)

**Add → Query String:**
```
version:latest
```

> Adding `version=latest` automatically returns the most recent published version of each server entry, so clients always see current metadata without needing to specify a version in their requests.

**Additional settings:**

| Field | Value |
|---|---|
| **Instance Name** | `registry-pat-injector` |
| **Tags** | `mcp`, `registry` |

Click **Save**.

---

## Step 4 — Create the Copilot Compatibility Route

GitHub Copilot uses a different path pattern (`/servers` suffix) to fetch registry entries. Without this second route, Copilot's registry fetch returns `404`.

From the `konnect-mcp-registry-se` service → **Add a Route**.

| Field | Value |
|---|---|
| **Name** | `konnect-mcp-registry-se-copilot-route` |
| **Path** | `/se-registry/servers` |
| **Methods** | `GET`, `OPTIONS` |
| **Strip Path** | ☐ Disabled |
| **Tags** | `mcp`, `registry` |

Click **Save**, then add **Request Transformer Advanced** on this route:

**Add → Headers:**
```
{vault://ai/konnect-mcp-registry-pat}
```

**Add → Query String:**
```
version:latest
```

**Replace → URI:**
```
/v0/mcp-registries/se-registry/v0.1/servers
```

> The URI replacement rewrites the Copilot-style path to the correct Konnect Labs API path before forwarding.

**Additional settings:**

| Field | Value |
|---|---|
| **Instance Name** | `registry-copilot-injector` |
| **Tags** | `mcp`, `registry` |

Click **Save**.

---

## Step 5 — Verify the Registry Is Reachable

From your terminal, confirm both routes work:

```bash
# Main registry route — returns full registry metadata
curl -s $PROXY/se-registry | python3 -m json.tool

# Servers list — used by VSCode gallery and Copilot
curl -s "$PROXY/se-registry/servers" | python3 -m json.tool
```

The `/servers` response should contain your `io.kong/konnect-mcp` entry:

```json
{
  "servers": [
    {
      "server": {
        "name": "io.kong/konnect-mcp",
        "title": "Kong Konnect MCP",
        "version": "1.0.0",
        ...
      }
    }
  ]
}
```

---

## Checkpoint ✅

| Route | URL | Expected Response |
|---|---|---|
| Main | `GET $PROXY/se-registry` | Registry metadata JSON |
| Servers list | `GET $PROXY/se-registry/servers` | `{ "servers": [...] }` with your entry |

Click **Continue** to point IDE clients at the registry.
