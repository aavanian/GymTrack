import SwiftUI

extension Color {
    static var secondaryGroupedBackground: Color {
        #if os(iOS)
        Color(.secondarySystemGroupedBackground)
        #elseif os(macOS)
        Color(.windowBackgroundColor)
        #else
        Color.gray.opacity(0.2)
        #endif
    }
}
