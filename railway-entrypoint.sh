#!/bin/sh
# Cloud deploy entrypoint: generates config.yaml from environment variables
# Always regenerates when FORCE_CONFIG_GEN is set or no valid config exists

CONFIG_FILE="${CONFIG_PATH:-/CLIProxyAPI/config.yaml}"
FORCE_GEN="${FORCE_CONFIG_GEN:-true}"

# Always regenerate config in cloud deploy mode to ensure env vars are applied
if [ "$FORCE_GEN" = "true" ] || [ ! -s "$CONFIG_FILE" ]; then
    echo "Generating config.yaml from environment variables..."

    cat > "$CONFIG_FILE" << YAML
host: ""
port: ${PORT:-8317}
tls:
  enable: false
  cert: ""
  key: ""
remote-management:
  allow-remote: true
  secret-key: "${MANAGEMENT_KEY:-admin123}"
  disable-control-panel: false
  panel-github-repository: "https://github.com/router-for-me/Cli-Proxy-API-Management-Center"
auth-dir: "${AUTH_DIR:-/root/.cli-proxy-api}"
api-keys:
$(for key in ${API_KEYS//,/ }; do echo "  - \"$key\""; done)
debug: ${DEBUG:-false}
commercial-mode: ${COMMERCIAL_MODE:-false}
logging-to-file: false
proxy-url: "${PROXY_URL:-}"
request-retry: ${REQUEST_RETRY:-3}
disable-cooling: false
disable-image-generation: false
quota-exceeded:
  switch-project: true
  switch-preview-model: true
  antigravity-credits: true
routing:
  strategy: "round-robin"
  session-affinity: false
  session-affinity-ttl: "1h"
ws-auth: false
enable-gemini-cli-endpoint: false
nonstream-keepalive-interval: 0
YAML

    # Append optional provider configs if env vars are set
    if [ -n "$GEMINI_API_KEYS" ]; then
        echo "gemini-api-key:" >> "$CONFIG_FILE"
        for key in ${GEMINI_API_KEYS//,/ }; do
            echo "  - api-key: \"$key\"" >> "$CONFIG_FILE"
        done
    fi

    if [ -n "$CLAUDE_API_KEYS" ]; then
        echo "claude-api-key:" >> "$CONFIG_FILE"
        for key in ${CLAUDE_API_KEYS//,/ }; do
            echo "  - api-key: \"$key\"" >> "$CONFIG_FILE"
        done
    fi

    if [ -n "$CODEX_API_KEYS" ]; then
        echo "codex-api-key:" >> "$CONFIG_FILE"
        for key in ${CODEX_API_KEYS//,/ }; do
            echo "  - api-key: \"$key\"" >> "$CONFIG_FILE"
        done
    fi

    if [ -n "$OPENAI_COMPAT_KEY" ] && [ -n "$OPENAI_COMPAT_URL" ]; then
        cat >> "$CONFIG_FILE" << YAML
openai-compatibility:
  - name: "custom"
    base-url: "$OPENAI_COMPAT_URL"
    api-key-entries:
      - api-key: "$OPENAI_COMPAT_KEY"
YAML
    fi

    echo "Config generated at $CONFIG_FILE"
else
    echo "Using existing config at $CONFIG_FILE"
fi

# Start the application
exec ./CLIProxyAPI --config "$CONFIG_FILE"
