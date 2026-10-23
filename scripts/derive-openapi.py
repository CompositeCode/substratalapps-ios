#!/usr/bin/env python3
"""Derives the copy of openapi.yaml that swift-openapi-generator reads from the untouched upstream file.

    scripts/derive-openapi.py api-contract/openapi.yaml Packages/SubstratalKit/Sources/SubstratalAPI/openapi.yaml

Three changes, each so the generated client honours the API's contract rather than breaking on it:

1. The per-operation `ApiVersion` header parameter is removed. APIVersionMiddleware sends
   `Substratal-Version` on every request (CLIENT-ARCHITECTURE §4.1), so no call site passes it.
2. `enum` constraints are removed from string schemas. The generator emits frozen Swift enums, and one
   unknown value would fail the whole response, but the API may add enum values without a version bump
   (NFR → Versioning: "treat an unrecognized enum value as handle generically"). The domain layer maps the
   strings, with an explicit unknown case.
3. Nullable shapes (`oneOf: [X, {type: "null"}]`, `type: [T, "null"]`) become plain X / T, and such properties
   are dropped from `required`, so an explicit `null` decodes as nil. The generator can't express them otherwise.
"""
import sys
import yaml

source, target = sys.argv[1], sys.argv[2]
doc = yaml.safe_load(open(source, encoding="utf-8"))

def is_null(schema):
    return isinstance(schema, dict) and schema.get("type") == "null" and len(schema) == 1

def unwrap_nullable(schema):
    """Returns (schema without null, was_nullable)."""
    if not isinstance(schema, dict):
        return schema, False
    for key in ("oneOf", "anyOf"):
        options = schema.get(key)
        if isinstance(options, list) and any(is_null(o) for o in options):
            rest = [o for o in options if not is_null(o)]
            merged = {k: v for k, v in schema.items() if k != key}
            if len(rest) == 1:
                merged.update(rest[0] if "$ref" not in rest[0] else {"allOf": [rest[0]]} if merged else rest[0])
            else:
                merged[key] = rest
            return merged, True
    t = schema.get("type")
    if isinstance(t, list) and "null" in t:
        rest = [x for x in t if x != "null"]
        schema = dict(schema)
        schema["type"] = rest[0] if len(rest) == 1 else rest
        return schema, True
    return schema, False

def walk(node):
    if isinstance(node, dict):
        # Rule 2: open enums.
        if "enum" in node and node.get("type", "string") == "string":
            node.pop("enum")
        # Rule 3: nullable properties.
        props = node.get("properties")
        if isinstance(props, dict):
            nullable = set()
            for name, prop in list(props.items()):
                unwrapped, was = unwrap_nullable(prop)
                if was:
                    props[name] = unwrapped
                    nullable.add(name)
            if nullable and isinstance(node.get("required"), list):
                node["required"] = [r for r in node["required"] if r not in nullable] or None
                if node["required"] is None:
                    node.pop("required")
        for key, value in list(node.items()):
            node[key] = walk(value)
        return node
    if isinstance(node, list):
        # Rule 1: drop the version header parameter reference wherever it's listed.
        return [walk(x) for x in node if not (isinstance(x, dict) and x.get("$ref") == "#/components/parameters/ApiVersion")]
    return node

walk(doc)
header = ("# DERIVED by scripts/derive-openapi.py from api-contract/openapi.yaml. Do not edit; run scripts/sync-openapi.sh.\n")
with open(target, "w", encoding="utf-8") as out:
    out.write(header)
    yaml.safe_dump(doc, out, sort_keys=False, allow_unicode=True, width=120)
