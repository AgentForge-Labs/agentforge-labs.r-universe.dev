library(agentrelay)

x <- agentrelay_client(api_key = "example-only")
stopifnot(inherits(x, "agentrelay_client"))
stopifnot(identical(x$origin, "https://relay.web-tasarimci.com"))

bad <- try(agentrelay_client(api_key = "x", bearer_token = "y"), silent = TRUE)
stopifnot(inherits(bad, "try-error"))

bad_origin <- try(agentrelay_client(api_key = "x", origin = "http://example.test", allow_custom_origin = TRUE), silent = TRUE)
stopifnot(inherits(bad_origin, "try-error"))
