\name{agentrelay}
\alias{agentrelay_client}
\alias{agentrelay_call}
\alias{agentrelay_request}
\alias{agentrelay_send_message}
\alias{agentrelay_reply}
\alias{agentrelay_send_file}
\alias{agentrelay_reply_file}
\alias{agentrelay_list_inbox}
\alias{agentrelay_get_inbox}
\alias{agentrelay_download_file}
\alias{agentrelay_list_workspaces}
\alias{agentrelay_pages}
\title{Hosted AgentRelay client}
\description{Credential-safe helpers for the managed AgentRelay public API.}
\usage{
agentrelay_client(api_key = NULL, bearer_token = NULL,
  origin = "https://relay.web-tasarimci.com", allow_custom_origin = FALSE,
  allow_insecure_loopback = FALSE, timeout = 15, retries = 1L,
  package_version = "0.1.0")
agentrelay_call(client, operation_id, path = list(), query = NULL,
  body = NULL, content_type = NULL, idempotency_key = NULL)
agentrelay_request(client, method, path, workspace_id = NULL, agent_id = NULL,
  query = NULL, body = NULL, content_type = NULL, idempotency_key = NULL,
  billable = FALSE, retry = FALSE, form = NULL)
agentrelay_send_message(client, workspace_id, agent_id, text, idempotency_key = NULL)
agentrelay_reply(client, workspace_id, agent_id, event_id, text, idempotency_key = NULL)
agentrelay_send_file(client, workspace_id, agent_id, file, kind = "document",
  caption = NULL, filename = basename(file), idempotency_key = NULL)
agentrelay_reply_file(client, workspace_id, agent_id, event_id, file,
  kind = "document", caption = NULL, filename = basename(file),
  idempotency_key = NULL)
agentrelay_list_inbox(client, workspace_id, agent_id, cursor = NULL, limit = 50L)
agentrelay_get_inbox(client, workspace_id, agent_id, event_id)
agentrelay_download_file(client, workspace_id, agent_id, file_id)
agentrelay_list_workspaces(client, cursor = NULL, limit = 50L)
agentrelay_pages(client, operation_id, path = list(), limit = 50L)
}
\arguments{
\item{api_key, bearer_token}{Exactly one AgentRelay credential.}
\item{origin}{Managed HTTPS origin by default.}
\item{allow_custom_origin, allow_insecure_loopback}{Explicit transport opt-ins.}
\item{timeout, retries, package_version}{Transport settings.}
\item{client}{An agentrelay client.}
\item{operation_id}{Generated OpenAPI operation identifier.}
\item{path, query, body, content_type, form}{Request inputs.}
\item{method}{HTTP method.}
\item{workspace_id, agent_id, event_id, file_id}{Hosted resource identifiers.}
\item{idempotency_key}{Stable identity for a billable write.}
\item{billable, retry}{Raw extension write and retry controls.}
\item{text}{Message or reply text.}
\item{file}{Local path to upload.}
\item{kind, caption, filename}{File metadata.}
\item{cursor, limit}{Pagination controls.}
}
\value{Clients return an agentrelay client; API helpers return decoded JSON lists or raw bytes.}
\details{Hosted calls use AgentRelay account credentials and never require Telegram bot tokens or chat IDs.}
\keyword{utilities}
