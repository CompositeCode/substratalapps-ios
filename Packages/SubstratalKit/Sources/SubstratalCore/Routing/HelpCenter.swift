import Foundation

/// Links into the shared Substratal Hub help center, published with the specs site so every Hub app
/// (web, iOS, Android, macOS, Windows, Linux) points at one documentation reference.
public enum HelpCenter {
    public static let base = URL(string: "https://compositecode.github.io/substratalapps-applications-specs/help/")!

    public static var home: URL { base }
    public static var faq: URL { base.appending(path: "faq.html") }
    public static var tutorials: URL { base.appending(path: "tutorials/") }
    /// The interactive API reference for the version this build sends in `Substratal-Version`.
    public static var apiReference: URL { base.appending(path: "api/v\(APIConfiguration.apiVersion)/") }
    public static var whatsNew: URL { base.appending(path: "whats-new.html") }

    /// Contextual help for one screen: what it's for, how to use it, and the related tutorials.
    public static func url(for screen: ScreenID) -> URL {
        base.appending(path: "screens/\(screen.rawValue.lowercased()).html")
    }
}
