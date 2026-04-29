---
title: "Step 3: Configure OAuth2 Validation"
---

# Step 3: Configure the AI MCP OAuth2 Plugin

The final plugin in the security stack is **AI MCP OAuth2**. It validates the Bearer JWT that IDE clients present, enforces scopes, and publishes the OAuth Protected Resource Metadata discovery document that tells clients which authorization server to use.

This workshop uses **Kong Identity** — the OIDC authorization server provisioned alongside your Konnect organization. The auth server and the public client application are already set up; you just need to point the plugin at them.

---

## Steps

**1. Open the Plugin Catalog**

From the `konnect-mcp-server` Route → **Plugins** tab → **+ New plugin**.

**2. Find the Plugin**

Type `mcp oauth` in the filter. Click the **AI MCP OAuth2** tile.

![Plugin Catalog filtered by "mcp" — AI MCP OAuth2 tile highlighted]({{<baseurl>}}/images/konnect-new-plugin-oauth.png)

**3. Configure Authorization Server**

In the **Authorization Servers** field, add:

```
$KONG_IDENTITY_ISSUER
```

Replace `$KONG_IDENTITY_ISSUER` with the issuer URL provided by your instructor (e.g., `https://your-cp.us.auth.konghq.com/oauth2/default`).

**4. Configure the JWKS Endpoint**

In the **JWKS Endpoint** field, enter:

```
$KONG_IDENTITY_ISSUER/.well-known/jwks.json
```

Again replacing `$KONG_IDENTITY_ISSUER` with your actual issuer URL.

| Field | Value |
|---|---|
| **JWKS Cache TTL** | `60` (seconds) |
| **Insecure Relaxed Audience Validation** | ✅ Checked |

> **Audience validation:** Kong Identity issues tokens where the `aud` claim is the client ID, not a resource URI. Enabling relaxed audience validation bypasses strict `aud` matching, which is appropriate here since token identity comes from the `sub` claim.

**5. Configure Scopes**

In the **Scopes Supported** field, add:

```
openid
```

**6. Configure the Metadata Endpoint**

In the **Metadata Endpoint** field, enter:

```
/.well-known/oauth-protected-resource/konnect-mcp-server
```

This is the path on your route where Kong will serve the OAuth Protected Resource Metadata document. IDE clients fetch this after receiving a `401` to discover which authorization server to use.

**7. Set the Resource Identifier**

In the **Resource** field, enter the full public URL of your MCP endpoint:

```
$PROXY/konnect-mcp-server
```

This value appears in the resource metadata document and tells clients the canonical identifier for this protected resource.

**8. Additional Settings**

Expand **Show additional settings** and set:

| Field | Value |
|---|---|
| **Instance Name** | `konnect-mcp-oauth2` |
| **Tags** | `mcp` |

**9. Save**

Click **Save**.

---

## What Happens When a Client Connects

With all three plugins in place, the end-to-end flow is:

```
1. IDE sends: POST $PROXY/konnect-mcp-server (no token)
2. Kong replies: 401 WWW-Authenticate: Bearer resource_metadata="$PROXY/.well-known/..."
3. IDE fetches: GET $PROXY/.well-known/oauth-protected-resource/konnect-mcp-server
4. Kong replies: { "authorization_servers": ["$KONG_IDENTITY_ISSUER"], "resource": "...", ... }
5. IDE starts PKCE flow with Kong Identity
6. User authenticates in browser → gets JWT
7. IDE sends: POST $PROXY/konnect-mcp-server  Authorization: Bearer <jwt>
8. ai-mcp-oauth2 validates JWT signature via JWKS → passes
9. request-transformer replaces Authorization header with {vault://ai/konnect-mcp-spat}
10. ai-mcp-proxy relays MCP traffic to us.mcp.konghq.com
11. Konnect MCP Server authenticates the PAT → returns MCP tools
```

---

## Verify the Discovery Endpoint

```bash
curl -s $PROXY/.well-known/oauth-protected-resource/konnect-mcp-server | python3 -m json.tool
```

Expected response:
```json
{
  "resource": "$PROXY/konnect-mcp-server",
  "authorization_servers": ["$KONG_IDENTITY_ISSUER"],
  "scopes_supported": ["openid"],
  "bearer_methods_supported": ["header"]
}
```

If you see this JSON, the OAuth discovery chain is fully wired.

---

## Checkpoint ✅

The `konnect-mcp-server` route should now have three plugins:

| Plugin | Instance Name | Mode/Config |
|---|---|---|
| AI MCP Proxy | `konnect-mcp-proxy` | `passthrough-listener` |
| Request Transformer Advanced | `konnect-mcp-transformer` | Injects `{vault://ai/konnect-mcp-spat}` |
| AI MCP OAuth2 | `konnect-mcp-oauth2` | Kong Identity JWKS validation |

Click **Continue** to connect an IDE client using OAuth2.
