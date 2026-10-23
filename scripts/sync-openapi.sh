#!/usr/bin/env bash
# Vendors the Platform API contract and derives the copy the Swift generator reads.
#
#   scripts/sync-openapi.sh            # latest published spec (the API's docs site, built from its main branch)
#   scripts/sync-openapi.sh <file>     # a local openapi.yaml, e.g. ../substratalapps.com/docs/openapi.yaml
#
# api-contract/openapi.yaml is the untouched upstream file, and api-contract/CONTRACT.json records where it came from.
# Packages/SubstratalKit/Sources/SubstratalAPI/openapi.yaml is derived from it by scripts/derive-openapi.py
# (version header handled by middleware, open enums, nullable fields); see that script for why.
set -euo pipefail
cd "$(dirname "$0")/.."

PUBLISHED_URL="https://compositecode.github.io/substratalapps.com/openapi.yaml"
SOURCE="${1:-$PUBLISHED_URL}"
UPSTREAM="api-contract/openapi.yaml"
DERIVED="Packages/SubstratalKit/Sources/SubstratalAPI/openapi.yaml"

if [[ -f "$SOURCE" ]]; then [[ "$SOURCE" -ef "$UPSTREAM" ]] || cp "$SOURCE" "$UPSTREAM"; else curl -fsSL "$SOURCE" -o "$UPSTREAM"; fi

python3 -c "import yaml" 2>/dev/null || python3 -m pip install --quiet --user pyyaml
python3 scripts/derive-openapi.py "$UPSTREAM" "$DERIVED"

python3 - "$UPSTREAM" "$SOURCE" <<'PY'
import hashlib, json, re, sys, datetime
path, source = sys.argv[1], sys.argv[2]
text = open(path, encoding="utf-8").read()
info_version = re.search(r'^  version: "?([^"\n]+)"?', text, re.M).group(1)
api_versions = re.search(r'ApiVersion:\n(?:.*\n)*?\s+schema: \{ type: string, enum: \[([^\]]*)\] \}', text)
operations = len(re.findall(r'^\s+operationId: ', text, re.M))
record = {
    "source": source,
    "sha256": hashlib.sha256(text.encode()).hexdigest(),
    "info_version": info_version,
    "substratal_versions": [v.strip().strip('"') for v in api_versions.group(1).split(",")] if api_versions else [],
    "operations": operations,
    "synced_at": datetime.datetime.now(datetime.timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
}
# Keep the previous timestamp when the contract is unchanged, so a no-op sync leaves no diff.
try:
    previous = json.load(open("api-contract/CONTRACT.json"))
    if previous.get("sha256") == record["sha256"]:
        record["synced_at"] = previous.get("synced_at", record["synced_at"])
except (OSError, ValueError):
    pass
json.dump(record, open("api-contract/CONTRACT.json", "w"), indent=2)
open("api-contract/CONTRACT.json", "a").write("\n")
print(f"openapi.yaml {info_version}: {operations} operations, Substratal-Version {record['substratal_versions']}")
PY
