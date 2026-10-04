# Hosted AgentRelay vs self-hosted Telegram Gateway

The agentrelay R package is a thin client for the AgentForge-managed AgentRelay service.
It uses an AgentRelay API key or Bearer token, defaults to the managed HTTPS origin,
and uses workspace/agent identifiers. Quota, delivery, retry, and idempotency
enforcement remain server-side. Normal hosted calls never require Telegram bot tokens
or Telegram chat IDs.

agentforge-telegram-gateway is a separate self-hosted Community Edition. It defaults
to a local gateway, uses infrastructure owned by the operator, requires no AgentForge
cloud account, and consumes no hosted AgentRelay quota.

Choose the self-hosted package when you operate the Telegram gateway yourself. Choose
agentrelay when you want the managed hosted service.
