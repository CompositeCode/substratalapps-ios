#!/usr/bin/env python3
"""Regenerates Packages/SubstratalKit/Sources/SubstratalCore/Routing/ScreenID.swift from the shared screen index.

    scripts/generate-screen-ids.py [path/to/substratal-application-specs]

Defaults to ../substratalapps-applications-specs/substratal-application-specs (a sibling checkout).
Console (domain C) screens are skipped: they are web-only (PRODUCT-SPEC §2a, OPEN-QUESTIONS #27).
"""
import pathlib, re, sys

root = pathlib.Path(__file__).resolve().parent.parent
specs = pathlib.Path(sys.argv[1]) if len(sys.argv) > 1 else root.parent / "substratalapps-applications-specs" / "substratal-application-specs"
index = (specs / "00-shared" / "SCREEN-SPECS.md").read_text(encoding="utf-8")
row = re.compile(r'^\| \[([A-Z]{3,4}-\d{2})\]\(#([^)]+)\) \| (.+?) \| (\S+) \| `([^`]+)` \| (\S+) \| (.+?) \|$')
rows = [m.groups() for m in map(row.match, (l.strip() for l in index.splitlines())) if m]
hub = [r for r in rows if r[3] != "C"]

def case(sid): return sid.lower().replace("-", "")

out = [
    "// Generated from 00-shared/SCREEN-SPECS.md (spec targeting API v1.8.0) by scripts/generate-screen-ids.py. Do not edit by hand.",
    "// The 12 C · Console screens (OPS-*, SEC-01, CFG-*, RPT-01, INT-01) are web-only; iOS skips them (PRODUCT-SPEC §2a, OPEN-QUESTIONS #27).",
    "import Foundation", "",
    "/// Every Hub screen, with the canonical ID, route and archetype from the shared spec.",
    "public enum ScreenID: String, CaseIterable, Identifiable, Sendable, Codable {",
]
out += [f'    case {case(r[0])} = "{r[0]}"' for r in hub]
out += ["", "    public var id: String { rawValue }", "",
        "    public struct Info: Sendable, Hashable {",
        "        public let title: String", "        public let domain: String", "        public let route: String",
        "        public let archetype: String", "        public let phase: String",
        "        /// The heading anchor in SCREEN-SPECS.md and in the help center.",
        "        public let anchor: String", "    }", "",
        "    public var info: Info {", "        switch self {"]
for sid, anchor, title, dom, route, arch, phase in hub:
    t = title.replace('"', '\\"')
    out.append(f'        case .{case(sid)}: Info(title: "{t}", domain: "{dom}", route: "{route}", archetype: "{arch}", phase: "{phase}", anchor: "{anchor}")')
out += ["        }", "    }", "", "    public var title: String { info.title }", "}", ""]
target = root / "Packages/SubstratalKit/Sources/SubstratalCore/Routing/ScreenID.swift"
target.write_text("\n".join(out), encoding="utf-8")
print(f"{len(hub)} screens → {target.relative_to(root)}")
