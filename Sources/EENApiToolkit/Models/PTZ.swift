import Foundation

public struct PtzPosition: Codable, Sendable {
    public let x: Double?
    public let y: Double?
    public let z: Double?
}

public struct PtzPositionResponse: Codable, Sendable {
    public let x: Double
    public let y: Double
    public let z: Double
}

public enum PtzMoveType: String, Codable, Sendable {
    case position
    case direction
    case centerOn
}

public enum PtzDirection: String, Codable, Sendable {
    case up, down, left, right
    case `in` = "in"
    case out
}

public enum PtzStepSize: String, Codable, Sendable {
    case small, medium, large
}

/// Discriminated union for PTZ move commands.
public enum PtzMove: Codable, Sendable {
    case position(x: Double?, y: Double?, z: Double?)
    case direction(directions: [PtzDirection], stepSize: PtzStepSize?)
    case centerOn(relativeX: Double, relativeY: Double)

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .position(let x, let y, let z):
            try container.encode("position", forKey: .moveType)
            try container.encodeIfPresent(x, forKey: .x)
            try container.encodeIfPresent(y, forKey: .y)
            try container.encodeIfPresent(z, forKey: .z)
        case .direction(let directions, let stepSize):
            try container.encode("direction", forKey: .moveType)
            try container.encode(directions, forKey: .direction)
            try container.encodeIfPresent(stepSize, forKey: .stepSize)
        case .centerOn(let relativeX, let relativeY):
            try container.encode("centerOn", forKey: .moveType)
            try container.encode(relativeX, forKey: .relativeX)
            try container.encode(relativeY, forKey: .relativeY)
        }
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let moveType = try container.decode(String.self, forKey: .moveType)
        switch moveType {
        case "position":
            self = .position(
                x: try container.decodeIfPresent(Double.self, forKey: .x),
                y: try container.decodeIfPresent(Double.self, forKey: .y),
                z: try container.decodeIfPresent(Double.self, forKey: .z)
            )
        case "direction":
            self = .direction(
                directions: try container.decode([PtzDirection].self, forKey: .direction),
                stepSize: try container.decodeIfPresent(PtzStepSize.self, forKey: .stepSize)
            )
        case "centerOn":
            self = .centerOn(
                relativeX: try container.decode(Double.self, forKey: .relativeX),
                relativeY: try container.decode(Double.self, forKey: .relativeY)
            )
        default:
            throw DecodingError.dataCorruptedError(forKey: .moveType, in: container, debugDescription: "Unknown moveType: \(moveType)")
        }
    }

    private enum CodingKeys: String, CodingKey {
        case moveType, x, y, z, direction, stepSize, relativeX, relativeY
    }
}

public struct PtzPreset: Codable, Sendable {
    public let name: String
    public let position: PtzPositionResponse
    public let timeAtPreset: Int

    public init(name: String, position: PtzPositionResponse, timeAtPreset: Int) {
        self.name = name
        self.position = position
        self.timeAtPreset = timeAtPreset
    }
}

public enum PtzMode: String, Codable, Sendable {
    case homeReturn
    case tour
    case manualOnly
}

public struct PtzSettings: Codable, Sendable {
    public let presets: [PtzPreset]
    public let homePreset: String?
    public let mode: PtzMode
    public let autoStartDelay: Int
}

public struct PtzSettingsUpdate: Codable, Sendable {
    public let presets: [PtzPreset]?
    public let homePreset: String?
    public let mode: PtzMode?
    public let autoStartDelay: Int?

    public init(presets: [PtzPreset]? = nil, homePreset: String? = nil,
                mode: PtzMode? = nil, autoStartDelay: Int? = nil) {
        self.presets = presets
        self.homePreset = homePreset
        self.mode = mode
        self.autoStartDelay = autoStartDelay
    }
}
