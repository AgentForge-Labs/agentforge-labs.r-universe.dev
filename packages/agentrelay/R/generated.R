# Generated from sdk/r/inst/extdata/openapi.snapshot.json (sha256 93527442e126593c6b6925213033d13c6451fa6b880d74ad5f38c98c4dab65f4).
# Run: python sdk/generate.py
.agentrelay_operations <- list(
  downloadAgentFile = list(method="GET", path="/v1/workspaces/{workspaceId}/agents/{agentId}/files/{fileId}", path_params=c("workspaceId","agentId","fileId"), query_params=character(), idempotent_write=FALSE, request_media=NULL, response_media="application/octet-stream"),
  getInboxEvent = list(method="GET", path="/v1/workspaces/{workspaceId}/agents/{agentId}/inbox/{eventId}", path_params=c("workspaceId","agentId","eventId"), query_params=character(), idempotent_write=FALSE, request_media=NULL, response_media="application/json"),
  getServiceInfo = list(method="GET", path="/v1/service", path_params=character(), query_params=character(), idempotent_write=FALSE, request_media=NULL, response_media=NULL),
  listAgents = list(method="GET", path="/v1/workspaces/{workspaceId}/agents", path_params=c("workspaceId"), query_params=c("cursor","limit"), idempotent_write=FALSE, request_media=NULL, response_media="application/json"),
  listInboxEvents = list(method="GET", path="/v1/workspaces/{workspaceId}/agents/{agentId}/inbox", path_params=c("workspaceId","agentId"), query_params=c("cursor","limit"), idempotent_write=FALSE, request_media=NULL, response_media="application/json"),
  listWorkspaces = list(method="GET", path="/v1/workspaces", path_params=character(), query_params=c("cursor","limit"), idempotent_write=FALSE, request_media=NULL, response_media="application/json"),
  replyToInboxEvent = list(method="POST", path="/v1/workspaces/{workspaceId}/agents/{agentId}/inbox/{eventId}/reply", path_params=c("workspaceId","agentId","eventId"), query_params=character(), idempotent_write=TRUE, request_media="application/json", response_media="application/json"),
  replyToInboxEventWithFile = list(method="POST", path="/v1/workspaces/{workspaceId}/agents/{agentId}/inbox/{eventId}/reply-file", path_params=c("workspaceId","agentId","eventId"), query_params=character(), idempotent_write=TRUE, request_media="multipart/form-data", response_media="application/json"),
  sendAgentFile = list(method="POST", path="/v1/workspaces/{workspaceId}/agents/{agentId}/files", path_params=c("workspaceId","agentId"), query_params=character(), idempotent_write=TRUE, request_media="multipart/form-data", response_media="application/json"),
  sendAgentMessage = list(method="POST", path="/v1/workspaces/{workspaceId}/agents/{agentId}/messages", path_params=c("workspaceId","agentId"), query_params=character(), idempotent_write=TRUE, request_media="application/json", response_media="application/json")
)
