# lab-kong-mcp-workshop

A hands-on [Educates](https://educates.dev) workshop that walks developers through Kong Gateway's **AI MCP Proxy Plugin** — turning existing HTTP APIs into MCP servers consumable by AI agents and LLM-powered clients.

## What Attendees Learn

1. Use the MCP Proxy Plugin to auto-generate an MCP server at the data plane
2. Understand the available plugin modes (`conversion-listener`, `passthrough-listener`, etc.)
3. Configure typed MCP tools that map to upstream API endpoints
4. Connect MCP clients (Insomnia, Cursor, Google Antigravity) to the generated server

## Workshop Structure

| Module | Topic |
|---|---|
| 00 | Workshop Overview & Architecture |
| 01 | Create a Kong Gateway Service |
| 02 | Add a Marketplace Route |
| 03 | Configure the Mocking Plugin |
| 04 | Install & Configure the AI MCP Proxy Plugin |
| 05 | Connect an MCP Client & Test Tools |
| 06 | Summary & Next Steps |

## Prerequisites (Instructor)

- A Kong Konnect organisation with one Control Plane per student (or a shared one for small groups)
- The AI MCP Proxy Plugin must be available in the Control Plane's plugin catalogue
- Students need Konnect credentials and the Proxy URL for their assigned Control Plane

## Running Locally with Educates

```bash
# Install the Educates CLI
# https://docs.educates.dev/en/stable/getting-started/local-environment.html

educates create-cluster
educates publish-workshop
educates deploy-workshop
educates browse-workshops
```

## Publishing to GitHub

Tag a release to trigger the automated publish workflow:

```bash
git tag 1.0
git push origin 1.0
```

The GitHub Action will build and push the workshop OCI image and create a GitHub Release with the deployable `workshop.yaml` asset.

## License

Copyright © Kong Inc. All rights reserved.
