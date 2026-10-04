AGENTRELAY_MANAGED_ORIGIN <- "https://relay.web-tasarimci.com"

.agentrelay_or <- function(x, y) if (is.null(x)) y else x

.agentrelay_scalar <- function(value, name) {
  if (!is.character(value) || length(value) != 1L || is.na(value) || !nzchar(value)) {
    stop(name, " must be a non-empty scalar string", call. = FALSE)
  }
  value
}

.agentrelay_validate_origin <- function(origin, allow_custom_origin, allow_insecure_loopback) {
  origin <- sub("/+$", "", .agentrelay_scalar(origin, "origin"))
  https <- grepl("^https://[^/?#]+$", origin, perl = TRUE)
  loopback <- grepl("^http://(127\\.0\\.0\\.1|localhost|\\[::1\\])(?::[0-9]+)?$", origin, perl = TRUE)
  if (!https && !(allow_insecure_loopback && loopback)) {
    stop("origin must be an HTTPS origin", call. = FALSE)
  }
  if (!identical(origin, AGENTRELAY_MANAGED_ORIGIN) && !isTRUE(allow_custom_origin)) {
    stop("custom origin requires allow_custom_origin = TRUE", call. = FALSE)
  }
  origin
}

.agentrelay_safe_path <- function(path) {
  path <- .agentrelay_scalar(path, "path")
  if (!startsWith(path, "/v1/") || grepl("^[A-Za-z][A-Za-z0-9+.-]*://|[?#]", path, perl = TRUE)) {
    stop("only public v1 paths are allowed", call. = FALSE)
  }
  if (grepl("%(?:2f|5c|2e|25)", path, ignore.case = TRUE, perl = TRUE)) {
    stop("encoded path separators and traversal are forbidden", call. = FALSE)
  }
  decoded <- utils::URLdecode(path)
  parts <- strsplit(decoded, "/", fixed = TRUE)[[1]]
  if (grepl("\\\\|//", decoded, perl = TRUE) || any(parts[-1] %in% c("", ".", ".."))) {
    stop("invalid path", call. = FALSE)
  }
  public <- identical(decoded, "/v1/service") ||
    identical(decoded, "/v1/workspaces") ||
    startsWith(decoded, "/v1/workspaces/")
  if (!public || any(parts %in% c("admin", "saas-admin", "internal", "webhooks", "payments", "checkout"))) {
    stop("private paths are not available through the hosted client", call. = FALSE)
  }
  path
}

.agentrelay_idempotency_key <- function() {
  hex <- c(as.character(0:9), letters[1:6])
  paste(sample(hex, 32L, replace = TRUE), collapse = "")
}

.agentrelay_redact <- function(value, credential) {
  if (is.null(value)) return(NULL)
  gsub(credential, "[REDACTED]", as.character(value), fixed = TRUE)
}

.agentrelay_condition <- function(status, detail, credential) {
  code <- .agentrelay_redact(.agentrelay_or(detail$code, "HTTP_ERROR"), credential)
  msg <- .agentrelay_redact(.agentrelay_or(detail$message, "request failed"), credential)
  classes <- c(
    if (identical(code, "QUOTA_EXCEEDED")) "agentrelay_quota_error",
    if (code %in% c("UNAUTHORIZED", "FORBIDDEN", "AUTH_REQUIRED", "INVALID_API_KEY")) "agentrelay_auth_error",
    if (grepl("^DELIVERY", code)) "agentrelay_delivery_error",
    "agentrelay_error", "error", "condition"
  )
  structure(
    list(
      message = sprintf("AgentRelay %s (%s): %s", code, status, msg),
      call = NULL,
      status = as.integer(status),
      code = code,
      request_id = .agentrelay_redact(detail$requestId, credential),
      retry_after_seconds = .agentrelay_or(detail$retryAfterSeconds, NULL),
      upgrade_url = .agentrelay_redact(detail$upgradeUrl, credential),
      account_url = .agentrelay_redact(detail$accountUrl, credential)
    ),
    class = unique(classes)
  )
}

.agentrelay_headers <- function(raw_headers) {
  tryCatch(curl::parse_headers_list(raw_headers), error = function(...) list())
}

.agentrelay_decode <- function(response) {
  headers <- .agentrelay_headers(response$headers)
  media <- tolower(.agentrelay_or(headers[["content-type"]], ""))
  if (grepl("json", media, fixed = TRUE) && length(response$content)) {
    return(jsonlite::fromJSON(rawToChar(response$content), simplifyVector = FALSE))
  }
  response$content
}

.agentrelay_scope_check <- function(path, workspace_id = NULL, agent_id = NULL) {
  decoded <- utils::URLdecode(path)
  parts <- strsplit(decoded, "/", fixed = TRUE)[[1]]
  if (length(parts) >= 4L && is.null(workspace_id)) stop("workspace scope is required", call. = FALSE)
  if (length(parts) >= 6L && identical(parts[[5]], "agents") && is.null(agent_id)) {
    stop("agent scope is required", call. = FALSE)
  }
  if (!is.null(workspace_id) && (length(parts) < 4L || !identical(parts[[4]], workspace_id))) {
    stop("workspace scope mismatch", call. = FALSE)
  }
  if (!is.null(agent_id) && (length(parts) < 6L || !identical(parts[[5]], "agents") || !identical(parts[[6]], agent_id))) {
    stop("agent scope mismatch", call. = FALSE)
  }
}

agentrelay_client <- function(api_key = NULL, bearer_token = NULL,
                              origin = "https://relay.web-tasarimci.com",
                              allow_custom_origin = FALSE,
                              allow_insecure_loopback = FALSE,
                              timeout = 15, retries = 1L,
                              package_version = "0.1.0") {
  if (is.null(api_key) == is.null(bearer_token)) {
    stop("provide exactly one API key or Bearer token", call. = FALSE)
  }
  credential <- .agentrelay_scalar(.agentrelay_or(api_key, bearer_token), "credential")
  if (!is.numeric(timeout) || length(timeout) != 1L || timeout <= 0) {
    stop("timeout must be positive", call. = FALSE)
  }
  if (!is.numeric(retries) || length(retries) != 1L || retries < 0 || retries != as.integer(retries)) {
    stop("retries must be a nonnegative integer", call. = FALSE)
  }
  structure(
    list(
      credential = credential,
      origin = .agentrelay_validate_origin(origin, allow_custom_origin, allow_insecure_loopback),
      timeout = as.numeric(timeout),
      retries = as.integer(retries),
      user_agent = paste0("agentrelay/", package_version, " R")
    ),
    class = "agentrelay_client"
  )
}

.agentrelay_encode_query <- function(query) {
  if (is.null(query) || !length(query)) return("")
  pairs <- unlist(lapply(names(query), function(name) {
    value <- query[[name]]
    if (is.null(value)) return(character())
    vapply(value, function(item) {
      paste0(utils::URLencode(name, reserved = TRUE), "=", utils::URLencode(as.character(item), reserved = TRUE))
    }, character(1))
  }), use.names = FALSE)
  if (!length(pairs)) "" else paste0("?", paste(pairs, collapse = "&"))
}

.agentrelay_fetch <- function(client, method, url, payload = NULL, content_type = NULL,
                              form = NULL, idempotency_key = NULL) {
  handle <- curl::new_handle()
  headers <- list(paste("Bearer", client$credential), client$user_agent, "application/json, application/octet-stream")
  names(headers) <- c("Authorization", "User-Agent", "Accept")
  if (is.null(form) && !is.null(content_type)) headers[["Content-Type"]] <- content_type
  if (!is.null(idempotency_key)) headers[["Idempotency-Key"]] <- idempotency_key
  curl::handle_setheaders(handle, .list = headers)
  curl::handle_setopt(handle, customrequest = method, timeout = client$timeout)
  if (!is.null(form)) {
    curl::handle_setform(handle, .list = form)
  } else if (!is.null(payload)) {
    curl::handle_setopt(handle, postfields = payload)
  }
  curl::curl_fetch_memory(url, handle = handle)
}

agentrelay_request <- function(client, method, path, workspace_id = NULL,
                               agent_id = NULL, query = NULL, body = NULL,
                               content_type = NULL, idempotency_key = NULL,
                               billable = FALSE, retry = FALSE, form = NULL) {
  if (!inherits(client, "agentrelay_client")) stop("invalid AgentRelay client", call. = FALSE)
  method <- toupper(.agentrelay_scalar(method, "method"))
  if (!(method %in% c("GET", "POST", "PUT", "PATCH", "DELETE"))) stop("unsupported HTTP method", call. = FALSE)
  path <- .agentrelay_safe_path(path)
  .agentrelay_scope_check(path, workspace_id, agent_id)
  if (!identical(method, "GET") && !isTRUE(billable)) stop("extension writes must declare billable = TRUE", call. = FALSE)
  if (identical(method, "GET") && isTRUE(billable)) stop("GET cannot be billable", call. = FALSE)
  if (isTRUE(billable)) {
    idempotency_key <- .agentrelay_or(idempotency_key, .agentrelay_idempotency_key())
    if (!is.character(idempotency_key) || length(idempotency_key) != 1L ||
        nchar(idempotency_key, type = "bytes") < 8L || nchar(idempotency_key, type = "bytes") > 200L) {
      stop("invalid idempotency key length", call. = FALSE)
    }
  }

  payload <- NULL
  if (!is.null(body) && is.null(form)) {
    payload <- jsonlite::toJSON(body, auto_unbox = TRUE, null = "null", digits = NA)
    content_type <- .agentrelay_or(content_type, "application/json")
  }
  url <- paste0(client$origin, path, .agentrelay_encode_query(query))
  attempts <- if (isTRUE(retry) && (identical(method, "GET") || !is.null(idempotency_key))) client$retries + 1L else 1L

  for (attempt in seq_len(attempts)) {
    response <- tryCatch(
      .agentrelay_fetch(client, method, url, payload, content_type, form, idempotency_key),
      error = function(e) e
    )
    if (inherits(response, "error")) {
      if (attempt == attempts) {
        stop(structure(
          list(message = "AgentRelay NETWORK_ERROR (0): network request failed", call = NULL,
               status = 0L, code = "NETWORK_ERROR", request_id = NULL,
               retry_after_seconds = NULL, upgrade_url = NULL, account_url = NULL),
          class = c("agentrelay_error", "error", "condition")
        ))
      }
      Sys.sleep(min(0.25 * 2^(attempt - 1L), 2))
      next
    }
    if (response$status_code >= 200L && response$status_code < 300L) return(.agentrelay_decode(response))

    detail <- list()
    parsed <- tryCatch(jsonlite::fromJSON(rawToChar(response$content), simplifyVector = FALSE), error = function(...) NULL)
    if (is.list(parsed) && is.list(parsed$error)) detail <- parsed$error
    condition <- .agentrelay_condition(response$status_code, detail, client$credential)
    retryable <- response$status_code %in% c(429L, 502L, 503L, 504L) && !identical(condition$code, "QUOTA_EXCEEDED")
    if (attempt == attempts || !retryable) stop(condition)
    Sys.sleep(min(0.25 * 2^(attempt - 1L), 2))
  }
  stop("unreachable", call. = FALSE)
}

.agentrelay_escape_path <- function(value) {
  value <- .agentrelay_scalar(value, "path parameter")
  if (grepl("/", value, fixed = TRUE)) stop("invalid path parameter", call. = FALSE)
  utils::URLencode(value, reserved = TRUE)
}

.agentrelay_form <- function(body) {
  if (!is.list(body)) stop("multipart body must be a list", call. = FALSE)
  result <- list()
  for (name in names(body)) {
    value <- body[[name]]
    if (is.null(value)) next
    if (identical(name, "file")) {
      path <- .agentrelay_scalar(value, "file")
      if (!file.exists(path)) stop("file does not exist", call. = FALSE)
      filename <- .agentrelay_or(body$filename, basename(path))
      result[[name]] <- curl::form_file(path, name = filename)
    } else if (!identical(name, "filename")) {
      result[[name]] <- as.character(value)
    }
  }
  result
}

agentrelay_call <- function(client, operation_id, path = list(), query = NULL,
                            body = NULL, content_type = NULL, idempotency_key = NULL) {
  operation_id <- .agentrelay_scalar(operation_id, "operation_id")
  op <- .agentrelay_operations[[operation_id]]
  if (is.null(op)) stop("unknown operation", call. = FALSE)
  supplied_names <- names(path)
  if (is.null(supplied_names)) supplied_names <- character()
  if (!identical(sort(supplied_names), sort(op$path_params))) stop("path parameters do not match operation", call. = FALSE)
  if (!is.null(query) && !all(names(query) %in% op$query_params)) stop("query parameters do not match operation", call. = FALSE)

  route <- op$path
  for (name in names(path)) {
    route <- sub(paste0("{", name, "}"), .agentrelay_escape_path(path[[name]]), route, fixed = TRUE)
  }
  form <- NULL
  if (identical(op$request_media, "multipart/form-data")) {
    form <- .agentrelay_form(body)
    body <- NULL
  }
  agentrelay_request(
    client, op$method, route,
    workspace_id = .agentrelay_or(path$workspaceId, NULL),
    agent_id = .agentrelay_or(path$agentId, NULL),
    query = query, body = body, content_type = .agentrelay_or(content_type, op$request_media),
    idempotency_key = idempotency_key, billable = isTRUE(op$idempotent_write),
    retry = TRUE, form = form
  )
}

agentrelay_send_message <- function(client, workspace_id, agent_id, text, idempotency_key = NULL) {
  agentrelay_call(client, "sendAgentMessage",
    path = list(workspaceId = workspace_id, agentId = agent_id),
    body = list(text = .agentrelay_scalar(text, "text")), idempotency_key = idempotency_key)
}

agentrelay_reply <- function(client, workspace_id, agent_id, event_id, text, idempotency_key = NULL) {
  agentrelay_call(client, "replyToInboxEvent",
    path = list(workspaceId = workspace_id, agentId = agent_id, eventId = event_id),
    body = list(text = .agentrelay_scalar(text, "text")), idempotency_key = idempotency_key)
}

agentrelay_send_file <- function(client, workspace_id, agent_id, file,
                                 kind = "document", caption = NULL,
                                 filename = basename(file), idempotency_key = NULL) {
  agentrelay_call(client, "sendAgentFile",
    path = list(workspaceId = workspace_id, agentId = agent_id),
    body = list(kind = kind, caption = caption, file = file, filename = filename),
    idempotency_key = idempotency_key)
}

agentrelay_reply_file <- function(client, workspace_id, agent_id, event_id, file,
                                  kind = "document", caption = NULL,
                                  filename = basename(file), idempotency_key = NULL) {
  agentrelay_call(client, "replyToInboxEventWithFile",
    path = list(workspaceId = workspace_id, agentId = agent_id, eventId = event_id),
    body = list(kind = kind, caption = caption, file = file, filename = filename),
    idempotency_key = idempotency_key)
}

agentrelay_list_inbox <- function(client, workspace_id, agent_id, cursor = NULL, limit = 50L) {
  query <- c(list(limit = as.integer(limit)), if (!is.null(cursor)) list(cursor = cursor))
  agentrelay_call(client, "listInboxEvents",
    path = list(workspaceId = workspace_id, agentId = agent_id), query = query)
}

agentrelay_get_inbox <- function(client, workspace_id, agent_id, event_id) {
  agentrelay_call(client, "getInboxEvent",
    path = list(workspaceId = workspace_id, agentId = agent_id, eventId = event_id))
}

agentrelay_download_file <- function(client, workspace_id, agent_id, file_id) {
  agentrelay_call(client, "downloadAgentFile",
    path = list(workspaceId = workspace_id, agentId = agent_id, fileId = file_id))
}

agentrelay_list_workspaces <- function(client, cursor = NULL, limit = 50L) {
  query <- c(list(limit = as.integer(limit)), if (!is.null(cursor)) list(cursor = cursor))
  agentrelay_call(client, "listWorkspaces", query = query)
}

agentrelay_pages <- function(client, operation_id, path = list(), limit = 50L) {
  items <- list()
  cursor <- NULL
  repeat {
    query <- c(list(limit = as.integer(limit)), if (!is.null(cursor)) list(cursor = cursor))
    result <- agentrelay_call(client, operation_id, path = path, query = query)
    if (!is.list(result) || !is.list(result$items)) stop("expected paginated response", call. = FALSE)
    items <- c(items, result$items)
    cursor <- .agentrelay_or(result$nextCursor, NULL)
    if (is.null(cursor) || !nzchar(cursor)) break
  }
  items
}
