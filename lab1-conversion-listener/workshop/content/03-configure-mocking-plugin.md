---
title: "Prep: Configure the Mocking Plugin"
---

# Configure the Mocking Plugin

The **Mocking Plugin** intercepts requests and returns synthetic responses based on an OpenAPI specification. This lets you work with a realistic Marketplace API without needing a live backend.

## Step 1 — Open the Plugin Catalog

From the `Marketplace-MCP-Route` detail screen:

1. Click the **Plugins** tab
2. Click **"+ New plugin"**
3. In the filter field type `mocking`
4. Click the **"Mocking"** tile to open the plugin configuration form

## Step 2 — Paste the OpenAPI Specification

In the **API Specification** field, paste the entire contents of the `marketplace.yaml` file from the `exercises/` folder (open it in the editor panel on the left).

The specification defines two resources:
- `GET /users` — returns a list of marketplace users (optionally filtered by `id`)
- `GET /orders` — returns a list of orders for a given user (`userid` required)

<details>
<summary>View the full marketplace.yaml contents</summary>

```yaml
openapi: 3.0.0
info:
  title: Sample Users API
  version: 1.1.0
  description: A sample API for managing users and orders in a mock marketplace.
servers:
  - url: http://localhost:3000
    description: Local development server
paths:
  /users:
    get:
      summary: Get all users
      operationId: getUsers
      parameters:
        - name: id
          in: query
          required: false
          schema:
            type: string
          description: Optional user ID to filter results
      responses:
        "200":
          description: A list of users
          content:
            application/json:
              schema:
                type: array
                items:
                  $ref: "#/components/schemas/User"
              example:
                - id: "1"
                  username: alice
                  email: alice@example.com
                - id: "2"
                  username: bob
                  email: bob@example.com
  /orders:
    get:
      summary: Get orders for a user
      operationId: getOrders
      parameters:
        - name: userid
          in: query
          required: true
          schema:
            type: string
          description: User ID to filter orders
      responses:
        "200":
          description: A list of orders for the given user
          content:
            application/json:
              schema:
                type: array
                items:
                  $ref: "#/components/schemas/Order"
              example:
                - id: "101"
                  userid: "1"
                  product: Widget A
                  quantity: 2
                  status: shipped
                - id: "102"
                  userid: "1"
                  product: Widget B
                  quantity: 1
                  status: pending
components:
  schemas:
    User:
      type: object
      properties:
        id:
          type: string
        username:
          type: string
        email:
          type: string
    Order:
      type: object
      properties:
        id:
          type: string
        userid:
          type: string
        product:
          type: string
        quantity:
          type: integer
        status:
          type: string
```
</details>

## Step 3 — Additional Settings

After pasting the spec, configure these additional fields:

| Setting | Value |
|---|---|
| **Include Base Path** checkbox | ✅ Checked |
| **Instance Name** (under "Show additional settings") | `Marketplace-MCP-Mock` |
| **Tags** | `mcp` |
| **Custom Base Path** | `/marketplace` |

Click the **"Save"** button.

## Step 4 — Validate the Mock Endpoint

Open a terminal and run the following to confirm the mock is working:

```bash
http $PROXY/marketplace/users
```

You should receive a `200 OK` response with a JSON array of users. If so, your mock is ready!

> Replace `$PROXY` with the actual Proxy URL from your Gateway Service screen.

## Checkpoint ✅

- Mocking Plugin named `Marketplace-MCP-Mock` is enabled on `Marketplace-MCP-Route`
- `GET $PROXY/marketplace/users` returns mock user data
- `GET $PROXY/marketplace/orders?userid=1` returns mock order data

Click **Continue** to install and configure the MCP Proxy Plugin.
