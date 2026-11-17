#!/bin/bash
# Point the `github` data source at MotherDuck, which the daily refresh writes to,
# then run anfra behind Caddy, which redirects / to the dashboard.
set -euo pipefail
: "${MOTHERDUCK_TOKEN:?set MOTHERDUCK_TOKEN}"
umask 077
cat > /repo/.anfra/data_sources.yml <<EOF
data_sources:
  github:
    type: motherduck
    connection:
      token: "$MOTHERDUCK_TOKEN"
      dbname: github
EOF
umask 022
# Not loopback: on loopback anfra rejects requests addressed to any other host,
# such as the site's domain or the pod IP the platform's probe uses.
anfra serve --addr 0.0.0.0:7879 --no-watch &
anfra_pid=$!

# GET a path from anfra and print the body (HTTP/1.0, so the body isn't chunked).
fetch() {
	exec 3<>/dev/tcp/127.0.0.1/7879 || return 1
	printf 'GET %s HTTP/1.0\r\nHost: localhost\r\n\r\n' "$1" >&3
	sed '1,/^\r$/d' <&3
	exec 3<&-
}

# Copy anfra's page shell, the same for every app, with the sidebar CSS added.
for _ in $(seq 60); do fetch /health 2>/dev/null | grep -q '"ok"' && break; sleep 1; done
mkdir -p /tmp/shell
fetch /apps/zero-dollar-data-stack-github-health \
	| sed "s#</head>#<style>$(tr -d '\n' < /etc/caddy/hide-sidebar.css)</style></head>#" \
	> /tmp/shell/index.html
grep -q 'nav\[aria-label="Data Apps"\]' /tmp/shell/index.html

caddy run --config /etc/caddy/Caddyfile --adapter caddyfile &
caddy_pid=$!
# Exit when either process does, so the platform restarts the container.
while kill -0 "$anfra_pid" 2>/dev/null && kill -0 "$caddy_pid" 2>/dev/null; do sleep 5; done
exit 1
