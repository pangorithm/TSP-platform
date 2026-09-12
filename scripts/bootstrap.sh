#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
repository_root="$(cd -- "$script_dir/.." && pwd)"
workspace_root="${1:-$(dirname -- "$repository_root")}"
manifest="$repository_root/repositories.json"

command -v git >/dev/null || { echo "git is required." >&2; exit 1; }
command -v jq >/dev/null || { echo "jq is required." >&2; exit 1; }

jq -e '
  .schemaVersion == 1 and
  (.protocols.restApiMajor | type == "string") and
  (.protocols.webSocketProtocol | type == "number") and
  (.repositories | type == "array" and length > 0)
' "$manifest" >/dev/null

while IFS= read -r repository; do
  name="$(jq -r '.name' <<<"$repository")"
  https_url="$(jq -r '.httpsUrl' <<<"$repository")"
  ssh_url="$(jq -r '.sshUrl' <<<"$repository")"
  branch="$(jq -r '.defaultBranch' <<<"$repository")"
  target="$workspace_root/$name"

  if [[ -d "$target/.git" ]]; then
    origin="$(git -C "$target" remote get-url origin)"
    if [[ "$origin" != "$https_url" && "$origin" != "$ssh_url" ]]; then
      echo "$name origin mismatch: $origin" >&2
      exit 1
    fi
    echo "$name: existing checkout verified"
    continue
  fi

  if [[ -e "$target" ]]; then
    echo "$target exists but is not a Git checkout." >&2
    exit 1
  fi

  git clone --branch "$branch" "$ssh_url" "$target"
  echo "$name: cloned"
done < <(jq -c '.repositories[]' "$manifest")
