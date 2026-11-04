#!/usr/bin/env bash
# Exchanges the GitHub Actions OIDC token for a short-lived RubyGems.org API key.
#
# rubygems/configure-rubygems-credentials v2.1.0 sends only the JWT. A pending trusted publisher
# also needs the RubyGems.org account that will own the new gem, passed as `owner`; without it
# RubyGems.org refuses to create the gem on the first push. RUBYGEMS_OWNER_ID is the numeric
# account id shown on the Pending Trusted Publishers page.
#
#   RUBYGEMS_OWNER_ID=123 bash scripts/rubygems_credentials.sh
#
# The key is written to ~/.gem/credentials and exported for `gem push`, the same way the action
# configures it. It expires after fifteen minutes.

set -euo pipefail

owner="${RUBYGEMS_OWNER_ID:-}"
if [ -z "$owner" ]; then
  echo "::error::set the RUBYGEMS_OWNER_ID repository variable to the RubyGems.org account id that owns the gems"
  exit 1
fi

if [ -z "${ACTIONS_ID_TOKEN_REQUEST_URL:-}" ] || [ -z "${ACTIONS_ID_TOKEN_REQUEST_TOKEN:-}" ]; then
  echo "::error::the job needs the id-token: write permission"
  exit 1
fi

if ! token_json="$(curl --fail-with-body --silent --show-error \
  -H "Authorization: bearer ${ACTIONS_ID_TOKEN_REQUEST_TOKEN}" \
  "${ACTIONS_ID_TOKEN_REQUEST_URL}&audience=rubygems.org")"; then
  echo "::error::GitHub did not issue an OIDC token"
  exit 1
fi
id_token="$(printf '%s' "$token_json" | ruby -rjson -e 'puts JSON.parse(STDIN.read).fetch("value")')"

payload="$(JWT="$id_token" OWNER="$owner" ruby -rjson -e 'puts JSON.generate("jwt" => ENV.fetch("JWT"), "owner" => ENV.fetch("OWNER"))')"
if ! response="$(curl --fail-with-body --silent --show-error \
  -X POST "https://rubygems.org/api/v1/oidc/trusted_publisher/exchange_token" \
  -H 'content-type: application/json' \
  -H 'accept: application/json' \
  --data "$payload")"; then
  echo "::error::RubyGems.org rejected the token exchange: $response"
  exit 1
fi

if ! api_key="$(printf '%s' "$response" | ruby -rjson -e 'puts JSON.parse(STDIN.read).fetch("rubygems_api_key")')" \
  || [ -z "$api_key" ] || [ "$api_key" = "null" ]; then
  echo "::error::RubyGems.org returned no API key"
  exit 1
fi

echo "::add-mask::$api_key"
umask 077
mkdir -p "$HOME/.gem"
printf -- "---\n:rubygems_api_key: %s\n" "$api_key" > "$HOME/.gem/credentials"
chmod 600 "$HOME/.gem/credentials"

{
  echo "RUBYGEMS_API_KEY=$api_key"
  echo "GEM_HOST_API_KEY=$api_key"
  echo "BUNDLE_GEM__PUSH_KEY=$api_key"
} >> "$GITHUB_ENV"
