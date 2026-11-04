//
//  DiceKeyGrid.swift
//  DiceKeyVault
//
//  A DiceKey is only ever drawn as a 5×5 grid of its faces: letter and digit in the face
//  printed on the dice, turned to the die's orientation, with a bar beneath like the real die.
//

import DiceKeySpecification
import SwiftUI

extension Font {
    /// The face printed on the dice, from `DiceKeySpecification`; used for nothing else.
    static func dice(size: CGFloat) -> Font { .custom(PrintedFont.name, size: size) }
}

/// One die: its glyphs turned to its orientation, or blank when concealed or not yet entered.
struct DieView: View {
    /// Side lengths, in points, of each place a die is drawn.
    enum Size {
        static let grid: CGFloat = 44
        static let header: CGFloat = 52
        static let row: CGFloat = 28
    }

    /// Proportions of the side length.
    private enum Ratio {
        static let corner: CGFloat = 0.18
        static let glyph: CGFloat = 0.43
        static let gap: CGFloat = 0.04
        static let barWidth: CGFloat = 0.32
        static let barHeight: CGFloat = 0.045
    }
    private static let minimumBarHeight: CGFloat = 1.5
    private static let shadowRadius: CGFloat = 1
    private static let shadowOffset: CGFloat = 1
    private static let edgeWidth: CGFloat = 1

    static func spacing(for size: CGFloat) -> CGFloat { size * Ratio.corner }

    let face: PartialFace
    var concealed = false
    var size = Size.grid
    /// Whether the die sits in the box, which draws it without a rim: the box sets it off, and a rim
    /// on every die blurs the grid.
    var isInBox = false

    var body: some View {
        RoundedRectangle(cornerRadius: size * Ratio.corner)
            .fill(Color.dieFace)
            .shadow(color: .dieShadow, radius: Self.shadowRadius, y: Self.shadowOffset)
            .overlay {
                if !isInBox {
                    RoundedRectangle(cornerRadius: size * Ratio.corner).strokeBorder(
                        Color.dieEdge, lineWidth: Self.edgeWidth)
                }
            }
            .frame(width: size, height: size)
            .overlay {
                if !concealed, let letter = face.letter {
                    VStack(spacing: size * Ratio.gap) {
                        Text(letter.rawValue + (face.digit?.rawValue ?? " "))
                            .font(.dice(size: size * Ratio.glyph))
                        Capsule().frame(
                            width: size * Ratio.barWidth, height: max(Self.minimumBarHeight, size * Ratio.barHeight))
                    }
                    .foregroundStyle(Color.onDie)
                    .rotationEffect(.degrees(face.orientation?.clockwiseDegrees ?? 0))
                }
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(concealed ? "Concealed" : face.spokenDescription)
    }
}

/// The grid sits in a box, as the dice do.
struct DiceKeyGrid: View {
    private static let side = 5
    private static let selectionLineWidth: CGFloat = 3
    private static let boxPaddingRatio: CGFloat = 0.3
    private static let boxCornerRatio: CGFloat = 0.4
    /// The box's `die-edge` outline, clear in light, where the box stands out on its own.
    private static let boxEdgeWidth: CGFloat = 1
    /// About 2 pt across at the grid's usual die size: just visible, and enough.
    private static let crossingDotRatio: CGFloat = 0.045

    let faces: [PartialFace]
    var concealed = false
    var dieSize = DieView.Size.grid
    var selectedIndex: Int?
    var onSelect: ((Int) -> Void)?

    /// The grid's side, box included, in dice.
    private static var extentInDice: CGFloat {
        CGFloat(side) + CGFloat(side - 1) * DieView.spacing(for: 1) + 2 * boxPaddingRatio
    }

    static func extent(dieSize: CGFloat) -> CGFloat { dieSize * extentInDice }

    /// The die size at which the grid, box included, is `extent` on a side.
    static func dieSize(fitting extent: CGFloat) -> CGFloat { extent / extentInDice }

    var body: some View {
        let spacing = DieView.spacing(for: dieSize)
        Grid(horizontalSpacing: spacing, verticalSpacing: spacing) {
            ForEach(0..<Self.side, id: \.self) { row in
                GridRow {
                    ForEach(0..<Self.side, id: \.self) { column in
                        die(at: row * Self.side + column)
                    }
                }
            }
        }
        .padding(dieSize * Self.boxPaddingRatio)
        .background {
            let box = RoundedRectangle(cornerRadius: dieSize * Self.boxCornerRatio)
            box.fill(Color.dieBox)
            crossingDots(spacing: spacing)
            box.strokeBorder(Color.dieEdge, lineWidth: Self.boxEdgeWidth)
        }
        .accessibilityElement(children: concealed ? .ignore : .contain)
        .accessibilityLabel(concealed ? "DiceKey, concealed" : "DiceKey")
    }

    /// A dot where four dice meet. Without it, the eye fills each crossing that it isn't looking at
    /// with a gray haze (the Hermann grid illusion). The dot gives the crossing something to show.
    private func crossingDots(spacing: CGFloat) -> some View {
        Canvas { context, _ in
            let diameter = dieSize * Self.crossingDotRatio
            let step = dieSize + spacing
            let first = dieSize * Self.boxPaddingRatio + dieSize + spacing / 2
            for row in 0..<(Self.side - 1) {
                for column in 0..<(Self.side - 1) {
                    let center = CGPoint(x: first + CGFloat(column) * step, y: first + CGFloat(row) * step)
                    let dot = CGRect(
                        x: center.x - diameter / 2, y: center.y - diameter / 2, width: diameter, height: diameter)
                    context.fill(Path(ellipseIn: dot), with: .color(.dieDot))
                }
            }
        }
        .accessibilityHidden(true)
    }

    @ViewBuilder
    private func die(at index: Int) -> some View {
        let die = DieView(face: faces[index], concealed: concealed, size: dieSize, isInBox: true)
            .overlay {
                if index == selectedIndex {
                    RoundedRectangle(cornerRadius: DieView.spacing(for: dieSize)).strokeBorder(
                        Color.accent, lineWidth: Self.selectionLineWidth)
                }
            }
        if let onSelect {
            Button {
                onSelect(index)
            } label: {
                die
            }.buttonStyle(.plain)
        } else {
            die
        }
    }
}

extension DiceKeyGrid {
    init(diceKey: DiceKey, concealed: Bool = false) {
        self.init(faces: diceKey.faces.map(PartialFace.init), concealed: concealed)
    }
}

/// A DiceKey's center die: how it is recognized in lists, whatever it is named.
struct DiceAvatar: View {
    let centerFace: String
    var size = DieView.Size.row

    var body: some View {
        DieView(face: (try? Face(text: centerFace)).map(PartialFace.init) ?? PartialFace(), size: size)
    }
}

extension PartialFace {
    var spokenDescription: String {
        guard let letter else { return "empty" }
        return [letter.rawValue + (digit?.rawValue ?? ""), orientation?.spokenDirection].compactMap(\.self)
            .joined(separator: ", ")
    }
}

#Preview {
    VStack(spacing: .space6) {
        DiceKeyGrid(diceKey: .example)
        DiceKeyGrid(diceKey: .example, concealed: true)
        DiceAvatar(centerFace: DiceKey.example.centerFace.text, size: DieView.Size.header)
    }
    .padding()
}
