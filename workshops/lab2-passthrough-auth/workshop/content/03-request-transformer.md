---
title: "Step 2: Inject the Upstream Token"
---

# Step 2: Inject the Upstream PAT with Request Transformer Advanced

The Konnect MCP Server (`us.mcp.konghq.com`) requires a valid Konnect Personal Access Token (PAT) on every request — a system account token scoped to the tools you want to expose.

Rather than distributing this PAT to every developer, Kong retrieves it from **Konnect Vault** and injects it as an `Authorization` header before forwarding the request upstream. Clients never see or handle this token.

---

## How Vault References Work

The PAT is stored in the `ai` vault on your control plane as a secret named `konnect-mcp-spat`. The vault reference syntax in Kong plugin configs is:

```
{vault://ai/konnect-mcp-spat}
```

Kong resolves this at request time, fetching the secret value and substituting it inline. The secret value is stored as the **complete header string**:

```
Authorization: Bearer spat_xxxxxxxxxxxx...
```

> The `request-transformer-advanced` plugin injects entire header lines — so the vault secret must include both the header name (`Authorization: Bearer`) and the token value, not just the token alone.

---

## Steps

**1. Open the Plugin Catalog**

From the `konnect-mcp-server` Route → **Plugins** tab → **+ New plugin**.

**2. Find the Plugin**

Type `request transformer` in the filter. Click the **Request Transformer Advanced** tile.

![Plugin Catalog filtered by "transformer advanced"]({{<baseurl>}}/images/konnect-plugin-transformer.png)

**3. Configure the Plugin**

Expand the **Add** section and locate the **Headers** sub-section. Click **+ Add header** and enter:

```
{vault://ai/konnect-mcp-spat}
```

![Request Transformer Advanced — instance name "add-auth-header", Add.Headers set to vault reference]({{<baseurl>}}/images/konnect-add-auth-header.png)

> This single entry is the entire `Authorization: Bearer spat_...` header, resolved from Vault at request time.

Expand **Show additional settings** and set:

| Field | Value |
|---|---|
| **Instance Name** | `konnect-mcp-transformer` |
| **Tags** | `mcp` |

**4. Save**

Click **Save**.

---

## How This Works at Runtime

When a client sends a request to `$PROXY/konnect-mcp-server`:

1. The client's `Authorization: Bearer <jwt>` header arrives at Kong
2. *(After the OAuth2 plugin runs — added in the next step)* the JWT is validated and stripped
3. **Request Transformer** fetches `{vault://ai/konnect-mcp-spat}` from Konnect Vault
4. Kong adds `Authorization: Bearer spat_...` to the outbound request
5. The Konnect MCP Server receives a valid PAT and processes the MCP call

---

## Verify (Optional)

After adding the transformer, you can test that the PAT is now being injected:

```bash
curl -sI -X POST $PROXY/konnect-mcp-server
# If the vault secret is correctly configured, you should now see a 401 from
# Kong's ai-mcp-oauth2 plugin (not the upstream) — meaning the PAT reached the
# upstream and Kong is now enforcing client authentication.
# You will add the OAuth2 plugin in the next step.
```

---

## Checkpoint ✅

- Plugin `konnect-mcp-transformer` (Request Transformer Advanced) is enabled on the route
- Header injection configured: `{vault://ai/konnect-mcp-spat}`
- Vault secret `konnect-mcp-spat` in the `ai` vault is pre-provisioned

Click **Continue** to add Step 3: the AI MCP OAuth2 plugin.
