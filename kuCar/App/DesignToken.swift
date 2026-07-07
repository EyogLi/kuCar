import SwiftUI

// MARK: - Design Tokens

/// App-wide semantic design tokens for colors, typography, and spacing.
enum DesignToken {

    // MARK: - Colors

    enum Colors {
        static let accent = Color.blue
        static let accentGradient = LinearGradient(
            colors: [Color.blue, Color.purple],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        static let background = Color(.systemGroupedBackground)
        static let surface = Color(.systemBackground)
        static let textPrimary = Color(.label)
        static let textSecondary = Color(.secondaryLabel)
        static let destructive = Color.red

        // Semantic colors
        static let carPaintSelected = Color.blue.opacity(0.15)
        static let wheelSelected = Color.blue.opacity(0.15)
        static let panelSelected = Color.blue
        static let panelDeselected = Color(.systemGray5)
    }

    // MARK: - Spacing

    enum Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 16
        static let lg: CGFloat = 24
        static let xl: CGFloat = 32
    }

    // MARK: - Corner Radius

    enum Radius {
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 20
        static let full: CGFloat = 9999
    }

    // MARK: - Shadows

    enum Shadow {
        static let card = (color: Color.black.opacity(0.05), radius: 8.0, y: 2.0)
        static let cardSmall = (color: Color.black.opacity(0.05), radius: 4.0, y: 1.0)
        static let elevated = (color: Color.black.opacity(0.1), radius: 16.0, y: 4.0)
    }
}
