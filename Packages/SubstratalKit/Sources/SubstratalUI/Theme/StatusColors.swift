import SwiftUI
import SubstratalCore

/// Status colours are deliberately not themed (THEMES.md §2): the same in every theme, light and dark sets.
/// System colours keep them correct under Increase Contrast and in both appearances.
public extension StatusKind.Role {
    var color: Color {
        switch self {
        case .success: Color(uiColorName: .systemGreen)
        case .info: Color(uiColorName: .systemBlue)
        case .warning: Color(uiColorName: .systemOrange)
        case .critical: Color(uiColorName: .systemRed)
        case .neutral: Color(uiColorName: .systemGray)
        case .accent: Color.accentColor
        }
    }
}

/// Danger red, also unthemed.
public extension Color {
    static let danger = Color(uiColorName: .systemRed)
}

extension Color {
    enum SystemName { case systemGreen, systemBlue, systemOrange, systemRed, systemGray }
    init(uiColorName: SystemName) {
        #if canImport(UIKit)
        switch uiColorName {
        case .systemGreen: self.init(uiColor: .systemGreen)
        case .systemBlue: self.init(uiColor: .systemBlue)
        case .systemOrange: self.init(uiColor: .systemOrange)
        case .systemRed: self.init(uiColor: .systemRed)
        case .systemGray: self.init(uiColor: .systemGray)
        }
        #else
        switch uiColorName {
        case .systemGreen: self = .green
        case .systemBlue: self = .blue
        case .systemOrange: self = .orange
        case .systemRed: self = .red
        case .systemGray: self = .gray
        }
        #endif
    }
}
