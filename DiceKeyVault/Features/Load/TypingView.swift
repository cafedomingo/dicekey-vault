//
//  TypingView.swift
//  DiceKeyVault
//

import DiceKeySpecification
import SwiftUI

/// Each die in three steps, its letter, its digit, then which way is up, so no die is left
/// upright by default. A letter already on another die can't be typed. Once every die is in,
/// Open DiceKey takes the keypad's place; tap a die to redo it. A hardware keyboard types the
/// same way, with an arrow for where the top of the letter points. The keys keep their size, so
/// on a short window the grid shrinks to the height the keypad leaves. In a compact-height window,
/// such as a phone in landscape, the grid sits beside the keypad, whose letters run in rows of seven
/// so the keys keep their height, shrinking only to the height left.
struct TypingView: View {
    private static let keyHeight: CGFloat = 54
    private static let keySpacing: CGFloat = 6
    private static let keyFontSize: CGFloat = 22
    private static let letterColumns = 5
    private static let compactHeightLetterColumns = 7
    /// The six digits as a phone-style pad filling the letters' space.
    private static let digitColumns = 3
    private static let digitFontSize: CGFloat = 34
    private static let orientationDieSize: CGFloat = 64

    /// The letters' rows at full height, which the digits fill too.
    private static func keypadHeight(letterColumns: Int) -> CGFloat {
        let rows = CGFloat((FaceLetters.count + letterColumns - 1) / letterColumns)
        return rows * keyHeight + (rows - 1) * keySpacing
    }

    let typed: TypedDiceKey
    let onDone: (DiceKey) -> Void
    @Environment(\.isSceneCaptured) private var isSceneCaptured
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    @FocusState private var isFocused: Bool

    private var isCompactHeight: Bool { verticalSizeClass == .compact }
    private var letterColumns: Int { isCompactHeight ? Self.compactHeightLetterColumns : Self.letterColumns }

    var body: some View {
        let gridExtent = DiceKeyGrid.extent(dieSize: DieView.Size.grid)
        let keypadHeight = Self.keypadHeight(letterColumns: letterColumns)
        let layout =
            isCompactHeight ? AnyLayout(HStackLayout(spacing: .space4)) : AnyLayout(VStackLayout(spacing: .space4))
        layout {
            GeometryReader { proxy in
                DiceKeyGrid(
                    faces: typed.faces, concealed: isSceneCaptured,
                    dieSize: DiceKeyGrid.dieSize(fitting: proxy.size.height),
                    selectedIndex: typed.selectedIndex
                ) {
                    typed.select($0)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .frame(maxWidth: gridExtent, maxHeight: gridExtent)
            .aspectRatio(1, contentMode: .fit)
            VStack(spacing: .space4) {
                HStack {
                    Text(prompt).font(.headline)
                    Spacer()
                    Button("Delete", systemImage: "delete.left", action: typed.backspace)
                        .labelStyle(.iconOnly)
                        .font(.title2)
                }
                Group {
                    if isSceneCaptured {
                        Text("Paused while the screen is shared or recorded.").foregroundStyle(.secondary)
                    } else if let diceKey = finished {
                        Button {
                            onDone(diceKey)
                        } label: {
                            Label("Open DiceKey", systemImage: "checkmark").frame(maxWidth: .infinity)
                        }
                        .primaryAction()
                        .controlSize(.extraLarge)
                    } else {
                        keypad
                    }
                }
                .frame(minHeight: isCompactHeight ? 0 : keypadHeight, maxHeight: keypadHeight, alignment: .top)
            }
            .frame(maxWidth: isCompactHeight ? .infinity : nil)
        }
        .frame(maxWidth: isCompactHeight ? nil : .contentWidth)
        .focusable()
        .focused($isFocused)
        .focusEffectDisabled()
        .onAppear { isFocused = true }
        .onKeyPress(phases: .down, action: handle)
    }

    /// Every die in and none being redone.
    private var finished: DiceKey? { typed.selectedIndex == nil ? typed.diceKey : nil }

    private var prompt: String {
        guard let index = typed.selectedIndex, let step = typed.step else {
            return "All \(DiceKey.faceCount) in · tap a die to redo it"
        }
        let die = "Die \(index + 1)"
        switch step {
        case .letter: return "\(die) · its letter"
        case .digit: return "\(die) · its number"
        case .orientation: return "\(die) · which way is up?"
        }
    }

    @ViewBuilder
    private var keypad: some View {
        switch typed.step {
        case nil:
            EmptyView()
        case .letter:
            keys(FaceLetters, columns: letterColumns) { letter, height in
                if typed.usedLetters.contains(letter) {
                    usedKey(letter.rawValue, height: height)
                } else {
                    key(letter.rawValue, height: height) { typed.enter(letter: letter) }
                }
            }
        case .digit:
            keys(FaceDigits, columns: Self.digitColumns) { digit, height in
                key(digit.rawValue, height: height, fontSize: Self.digitFontSize) {
                    typed.enter(digit: digit)
                }
            }
        case .orientation:
            HStack {
                ForEach(FaceOrientationLettersTrbl, id: \.self) { orientation in
                    let face = PartialFace(
                        letter: typed.selectedFace?.letter, digit: typed.selectedFace?.digit, orientation: orientation)
                    Button {
                        typed.choose(orientation)
                    } label: {
                        DieView(face: face, size: Self.orientationDieSize).frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(face.spokenDescription)
                }
            }
        }
    }

    /// The keys in rows that share the keypad's height.
    private func keys<Value: Hashable>(
        _ values: [Value], columns: Int, @ViewBuilder content: @escaping (Value, _ height: CGFloat) -> some View
    ) -> some View {
        let rows = CGFloat((values.count + columns - 1) / columns)
        return GeometryReader { proxy in
            let height = (proxy.size.height - (rows - 1) * Self.keySpacing) / rows
            LazyVGrid(
                columns: Array(repeating: GridItem(.flexible(), spacing: Self.keySpacing), count: columns),
                spacing: Self.keySpacing
            ) {
                ForEach(values, id: \.self) { content($0, height) }
            }
        }
    }

    private func key(
        _ character: String, height: CGFloat, fontSize: CGFloat = keyFontSize, action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Text(character)
                .font(.dice(size: fontSize))
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .buttonStyle(.bordered)
        .frame(height: height)
    }

    /// A letter already on another die: struck through on no key at all, so it reads as taken
    /// rather than faint.
    private func usedKey(_ character: String, height: CGFloat) -> some View {
        Text(character)
            .font(.dice(size: Self.keyFontSize))
            .strikethrough()
            .foregroundStyle(.tertiary)
            .frame(maxWidth: .infinity, minHeight: height)
            .accessibilityLabel("\(character), on another die")
    }

    /// Return chooses upright, or finishes once every die is in. Shortcuts pass through, and
    /// nothing is typed while the screen is shared.
    private func handle(_ press: KeyPress) -> KeyPress.Result {
        guard press.modifiers.isDisjoint(with: [.command, .control, .option]), !isSceneCaptured else {
            return .ignored
        }
        switch press.key {
        case .delete: typed.backspace()
        case .upArrow: typed.choose(.Top)
        case .rightArrow: typed.choose(.Right)
        case .downArrow: typed.choose(.Bottom)
        case .leftArrow: typed.choose(.Left)
        case .return:
            if let diceKey = finished { onDone(diceKey) } else { typed.choose(.Top) }
        default:
            let character = press.characters.uppercased()
            if let letter = FaceLetter(rawValue: character) {
                typed.enter(letter: letter)
            } else if let digit = FaceDigit(rawValue: character) {
                typed.enter(digit: digit)
            } else {
                return .ignored
            }
        }
        return .handled
    }
}
