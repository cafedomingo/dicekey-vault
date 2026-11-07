//
//  CenteredContent.swift
//  DiceKeyVault
//

import SwiftUI

extension View {
    /// Centers a list's or form's content at `contentWidth` in the column beside any sidebar.
    /// The scroll view still spans the column, so its margins scroll, and its scroll indicator
    /// and top edge effect reach the column's edges.
    func centeredContent() -> some View {
        modifier(CenteredContent())
    }
}

/// The scroll view reaches under the safe area, such as under a floating sidebar, and a content
/// margin replaces that side's safe-area inset instead of adding to it. So each margin is the
/// inset plus half the width beyond `contentWidth`. Until that half is at least the system's own
/// margin, the margins stay the system's, so a column just wider than `contentWidth` doesn't
/// squeeze them.
private struct CenteredContent: ViewModifier {
    @State private var margins: EdgeInsets?

    func body(content: Content) -> some View {
        content
            .contentMargins(.leading, margins?.leading, for: .scrollContent)
            .contentMargins(.trailing, margins?.trailing, for: .scrollContent)
            .onGeometryChange(for: EdgeInsets?.self) { proxy in
                let side = (proxy.size.width - .contentWidth) / 2
                guard side >= .space4 else { return nil }
                let insets = proxy.safeAreaInsets
                return EdgeInsets(top: 0, leading: insets.leading + side, bottom: 0, trailing: insets.trailing + side)
            } action: {
                margins = $0
            }
    }
}
