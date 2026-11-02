import Foundation
import SwiftUI

/// A color stored as plain RGBA components so it round-trips through
/// Codable/JSON, since SwiftUI's Color does not.
public struct TileColor: Codable, Hashable, Sendable {
    public var red: Double
    public var green: Double
    public var blue: Double
    public var opacity: Double

    public init(red: Double, green: Double, blue: Double, opacity: Double = 1) {
        self.red = red
        self.green = green
        self.blue = blue
        self.opacity = opacity
    }

    public init(_ color: Color) {
        let resolved = color.resolve(in: EnvironmentValues())
        red = Double(resolved.red)
        green = Double(resolved.green)
        blue = Double(resolved.blue)
        opacity = Double(resolved.opacity)
    }

    public var color: Color {
        Color(red: red, green: green, blue: blue, opacity: opacity)
    }
}

/// How one deck tile looks. Glass is Apple's own Liquid Glass chrome and
/// only takes a tint; it draws its own background, so a custom color or
/// image would just be hidden behind it. Solid is a plain custom-drawn
/// tile that can carry either.
public struct TileStyle: Codable, Hashable, Sendable {
    public enum Material: String, Codable, Sendable {
        case glass
        case solid
    }

    public enum Background: Codable, Hashable, Sendable {
        case none
        case color(TileColor)
        case image(Data)
    }

    public var material: Material
    public var tintColor: TileColor?
    public var background: Background

    public init(material: Material = .glass, tintColor: TileColor? = nil, background: Background = .none) {
        self.material = material
        self.tintColor = tintColor
        self.background = background
    }

    public static let `default` = TileStyle()
}
