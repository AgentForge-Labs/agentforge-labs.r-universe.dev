# snapforge for R

Official R client for SnapForge.

Install from the AgentForge Labs R-universe:

```r
install.packages(
  "snapforge",
  repos = c(
    "https://agentforge-labs.r-universe.dev",
    "https://cloud.r-project.org"
  )
)
```

Hosted usage requires a SnapForge account/API key and remains subject to
server-side quota and billing rules. Self-hosted mode is explicit via
`snapforge_client(base_url = ...)`.

The package exposes typed capture/context/job/download helpers plus
`snapforge_request()` for backward-compatible additive public API endpoints.
Errors use the `snapforge_http_error` condition class and redact configured
credentials.

## Source and distribution

The canonical R SDK source is `packages/sdk-r` in
`AgentForge-Labs/site-screenshot-public_commercial`. R-universe receives only a
sanitized distribution mirror from the central
`AgentForge-Labs/agentforge-labs.r-universe.dev` registry repository under
`packages/snapforge`; there is no package-specific SnapForge R source repository.
