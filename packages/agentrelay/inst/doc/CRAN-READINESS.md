# CRAN readiness

agentrelay is published through AgentForge Labs r-universe first. The canonical
development source remains in the private project monorepo under sdk/r; a
package-specific GitHub source repository is not required.

## Public distribution boundary

R-universe requires each packages.json URL to be a public Git URL and clones it
directly. Because the canonical project monorepo is private, release automation
exports only the R package allowlist into the existing central registry
repository AgentForge-Labs/agentforge-labs.r-universe.dev under
packages/agentrelay. That mirror is a distribution input, not the canonical
development source. It contains no gateway backend, server code, tenant data,
credentials, or unrelated monorepo files.

Required gates:
- Generated-operation and pinned OpenAPI snapshot checks.
- Build the sanitized R-universe mirror from an explicit allowlist.
- R CMD build and R CMD check --no-manual from that mirror.
- Verify the source tarball contains only allowed R package files.
- Install and load the tarball in a clean R container without the monorepo.
- Linux, macOS, and Windows package checks in r-client CI.
- Hosted conformance tests and package-boundary/public-readiness checks.
- Artifact-specific releases: compatible server/API changes do not force an R release.

## R-universe activation

The central registry repository is AgentForge-Labs/agentforge-labs.r-universe.dev.
Its packages.json entry for agentrelay points back to that same public registry
repository with subdir packages/agentrelay. This avoids one GitHub repository per
SDK while satisfying the public-Git requirement of r-universe.

The organization still needs the r-universe GitHub App installed before live
r-universe builds can start. Automatic future mirror updates additionally need a
repository secret named R_UNIVERSE_REGISTRY_TOKEN with write access to the
central registry repository. Publication credentials must never ship in the R
package.

CRAN submission remains deferred until public build history and documentation
are stable and maintainers choose a submission window.
