#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
repository_root="$(cd -- "$script_dir/.." && pwd)"
backend_dir="${1:-$(dirname -- "$repository_root")/TSP-backend}"
backend_dir="$(cd -- "$backend_dir" && pwd)"
qa_dir="$repository_root/.tmp/qa"
address="127.0.0.1:3100"
base_url="http://$address"

command -v rustup >/dev/null || { echo "rustup is required." >&2; exit 1; }
command -v curl >/dev/null || { echo "curl is required." >&2; exit 1; }
command -v jq >/dev/null || { echo "jq is required." >&2; exit 1; }

mkdir -p "$qa_dir"
rustup run 1.98.1 cargo build --locked --manifest-path "$backend_dir/Cargo.toml"

binary="$backend_dir/target/debug/tsp-backend"
if [[ -x "$binary.exe" ]]; then
  binary="$binary.exe"
fi

TSP_BIND_ADDRESS="$address" TSP_LOG_FORMAT="human" \
  "$binary" >"$qa_dir/backend.stdout.log" 2>"$qa_dir/backend.stderr.log" &
backend_pid=$!

cleanup() {
  if kill -0 "$backend_pid" 2>/dev/null; then
    kill "$backend_pid" 2>/dev/null || true
    wait "$backend_pid" 2>/dev/null || true
  fi
}
trap cleanup EXIT INT TERM

health=""
for _ in {1..30}; do
  if health="$(curl --fail --silent --show-error "$base_url/api/v1/health/ready" 2>/dev/null)"; then
    break
  fi
  if ! kill -0 "$backend_pid" 2>/dev/null; then
    echo "Backend exited before becoming ready. See $qa_dir/backend.stderr.log" >&2
    exit 1
  fi
  sleep 1
done

jq -e '
  .service == "tsp-backend" and
  .status == "ok" and
  (.version | type == "string" and length > 0)
' <<<"$health" >/dev/null

echo_response="$(curl --fail --silent --show-error \
  -H "content-type: application/json" \
  --data '{"message":"platform-integration"}' \
  "$base_url/api/v1/echo")"
jq -e '.message == "platform-integration"' <<<"$echo_response" >/dev/null

echo "TSP-backend readiness and echo contracts passed."
