# syntax=docker/dockerfile:1
# Compatibility-first template for biopet.
# Installs package from Bioconda and copies the full conda runtime to avoid missing libs/interpreters.

FROM mambaorg/micromamba:2.0.5-debian12-slim AS builder

RUN micromamba install -y -n base -c conda-forge -c bioconda \
    biopet \
    && micromamba clean --all --yes

# Resolve a runnable command for this package.
# Prefer exact match, then underscore variant, then prefix match.
RUN set -eux; \
    BIN=""; \
    if [ -x "/opt/conda/bin/biopet" ]; then BIN="/opt/conda/bin/biopet"; fi; \
    if [ -z "$BIN" ]; then CAND="/opt/conda/bin/$(echo biopet | tr '-' '_')"; [ -x "$CAND" ] && BIN="$CAND" || true; fi; \
    if [ -z "$BIN" ]; then BIN="$(find /opt/conda/bin -maxdepth 1 -type f -perm -111 -name 'biopet*' | head -n1 || true)"; fi; \
    test -n "$BIN"; \
    printf '%s\n' "$BIN" > /tmp/tool-entry-path

FROM mambaorg/micromamba:2.0.5-debian12-slim

COPY --from=builder /opt/conda /opt/conda
COPY --from=builder /tmp/tool-entry-path /tmp/tool-entry-path

USER root
ENV PATH="/opt/conda/bin:${PATH}"
ENV LD_LIBRARY_PATH="/opt/conda/lib:/opt/conda/lib64"
RUN set -eux; \
    BIN="$(cat /tmp/tool-entry-path)"; \
    printf '#!/usr/bin/env bash\nexec "%s" "$@"\n' "$BIN" > /usr/local/bin/biopet
RUN chmod +x /usr/local/bin/biopet && rm -f /tmp/tool-entry-path
WORKDIR /data
ENTRYPOINT ["/usr/local/bin/biopet"]
