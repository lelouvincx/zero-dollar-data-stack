# The anfra dashboard as one image, served on Proto. Build from the repo root:
#   docker buildx build --platform linux/amd64 -f deploy/Dockerfile -t <image> .
# No credentials go in: start.sh writes the MotherDuck data source from
# $MOTHERDUCK_TOKEN when the container starts.
FROM ghcr.io/holistics/anfra:0.20.0@sha256:9aa3c604edb0ace35937b81a6852907a3996bdb85debf4634cc2cc63a6ee5829
# Caddy listens on 7878 and redirects / to the dashboard; anfra listens on 7879.
COPY --from=caddy:2.11.9-alpine@sha256:003a97808e781aa9f7e75cc2f43d34d461099031faf5e20faefb9f61126836f0 /usr/bin/caddy /usr/local/bin/caddy
COPY deploy/Caddyfile deploy/hide-sidebar.css /etc/caddy/
COPY --chown=anfra:anfra anfra /repo
COPY --chmod=755 deploy/start.sh /usr/local/bin/start.sh
# Serving other people: hide SQL and database errors from them.
ENV ANFRA_HIDE_ERROR_CAUSES=1
EXPOSE 7878
ENTRYPOINT ["/usr/bin/tini", "--", "/usr/local/bin/start.sh"]
