# agentrelay for R

Official R client for hosted AgentRelay. It defaults to the managed AgentRelay service,
requires an AgentRelay API key or Bearer token, and never asks for Telegram bot tokens
or chat IDs. It is separate from the self-hosted agentforge-telegram-gateway Community
Edition.

## Install from AgentForge Labs r-universe

~~~r
options(repos = c(
  agentforge = "https://agentforge-labs.r-universe.dev",
  CRAN = "https://cloud.r-project.org"
))
install.packages("agentrelay")
~~~

## Quick start

~~~r
library(agentrelay)
client <- agentrelay_client(api_key = Sys.getenv("AGENTRELAY_API_KEY"))
agentrelay_send_message(client, "workspace-id", "agent-id", "Build finished")
events <- agentrelay_list_inbox(client, "workspace-id", "agent-id")
~~~

Billable writes automatically get an idempotency key and retries reuse the same key.
Supply idempotency_key yourself when retry identity must survive process restarts.

Errors inherit from agentrelay_error. Quota, authentication, and delivery failures also
inherit from agentrelay_quota_error, agentrelay_auth_error, and
agentrelay_delivery_error. Safe metadata includes status, code, request_id,
retry_after_seconds, upgrade_url, and account_url.

See inst/doc/hosted-vs-self-hosted.md and inst/doc/CRAN-READINESS.md.

## Source and distribution

The canonical development source is maintained in the project monorepo under
`sdk/r`. R-universe is only a public distribution surface. Its build input is a
sanitized mirror in the single organization registry repository
`AgentForge-Labs/agentforge-labs.r-universe.dev` under `packages/agentrelay`;
there is no package-specific AgentRelay R source repository.
