import Foundation

/// A navigable destination: one screen plus the path parameters from its route (`/admin/users/:userId` → `userId`).
/// Hashable and Codable so `NavigationStack` paths persist in `@SceneStorage`.
public struct Route: Hashable, Codable, Sendable {
    public var screen: ScreenID
    public var params: [String: String]

    public init(_ screen: ScreenID, _ params: [String: String] = [:]) {
        self.screen = screen
        self.params = params
    }

    public subscript(_ name: String) -> String? { params[name] }

    // MARK: Deep links (INFORMATION-ARCHITECTURE §4)

    /// Hosts whose paths are Hub routes. Universal Links arrive on the dashboard host.
    public static let webHosts: Set<String> = ["dashboard.substratalapps.com"]
    public static let scheme = "substratal"

    /// Parses `substratal://admin/users/usr_123`, `https://dashboard.substratalapps.com/admin/users/usr_123`,
    /// or a bare path. Returns nil for anything that isn't a Hub route (open those externally).
    public static func parse(_ url: URL) -> Route? {
        let path: String
        if url.scheme == scheme {
            path = "/" + [url.host, url.path].compactMap { $0 }.joined().trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        } else if let host = url.host, webHosts.contains(host) {
            path = url.path.isEmpty ? "/" : url.path
        } else if url.scheme == nil {
            path = url.path
        } else {
            return nil
        }
        var route = parse(path: path)
        if let items = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems {
            for item in items { route?.params[item.name] = item.value }
        }
        return route
    }

    /// Matches a path against every screen's route pattern. Literal segments win over parameters,
    /// so `/admin/users/new` resolves to USR-02, not USR-03 with `userId = "new"`.
    public static func parse(path: String) -> Route? {
        let segments = path.split(separator: "/").map(String.init)
        var best: (route: Route, literals: Int)?
        for screen in ScreenID.allCases where screen.info.route.hasPrefix("/") {
            let pattern = screen.info.route.split(separator: "/").map(String.init)
            guard pattern.count == segments.count else { continue }
            var params: [String: String] = [:]
            var literals = 0
            var matched = true
            for (p, s) in zip(pattern, segments) {
                if p.hasPrefix(":") { params[String(p.dropFirst())] = s.removingPercentEncoding ?? s }
                else if p == s { literals += 1 }
                else { matched = false; break }
            }
            if matched, literals > (best?.literals ?? -1) { best = (Route(screen, params), literals) }
        }
        return best?.route
    }

    /// The canonical path for this route, for sharing and for the web fallback.
    public var path: String {
        screen.info.route.split(separator: "/").map { segment in
            segment.hasPrefix(":") ? (params[String(segment.dropFirst())] ?? String(segment)) : String(segment)
        }.reduce("") { $0 + "/" + $1 }.ifEmpty("/")
    }
}

private extension String {
    func ifEmpty(_ fallback: String) -> String { isEmpty ? fallback : self }
}
