import Foundation

public enum FormConciergeMetadataValue: Codable, Sendable {
  case string(String)
  case number(Double)
  case bool(Bool)
  case object([String: FormConciergeMetadataValue])
  case array([FormConciergeMetadataValue])
  case null

  public init(from decoder: Decoder) throws {
    let container = try decoder.singleValueContainer()
    if container.decodeNil() {
      self = .null
    } else if let value = try? container.decode(Bool.self) {
      self = .bool(value)
    } else if let value = try? container.decode(Double.self) {
      self = .number(value)
    } else if let value = try? container.decode(String.self) {
      self = .string(value)
    } else if let value = try? container.decode([FormConciergeMetadataValue].self) {
      self = .array(value)
    } else {
      self = .object(try container.decode([String: FormConciergeMetadataValue].self))
    }
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.singleValueContainer()
    switch self {
    case .string(let value):
      try container.encode(value)
    case .number(let value):
      try container.encode(value)
    case .bool(let value):
      try container.encode(value)
    case .object(let value):
      try container.encode(value)
    case .array(let value):
      try container.encode(value)
    case .null:
      try container.encodeNil()
    }
  }
}

extension FormConciergeMetadataValue: ExpressibleByStringLiteral {
  public init(stringLiteral value: String) {
    self = .string(value)
  }
}

extension FormConciergeMetadataValue: ExpressibleByIntegerLiteral {
  public init(integerLiteral value: Int) {
    self = .number(Double(value))
  }
}

extension FormConciergeMetadataValue: ExpressibleByFloatLiteral {
  public init(floatLiteral value: Double) {
    self = .number(value)
  }
}

extension FormConciergeMetadataValue: ExpressibleByBooleanLiteral {
  public init(booleanLiteral value: Bool) {
    self = .bool(value)
  }
}

extension FormConciergeMetadataValue: ExpressibleByArrayLiteral {
  public init(arrayLiteral elements: FormConciergeMetadataValue...) {
    self = .array(elements)
  }
}

extension FormConciergeMetadataValue: ExpressibleByDictionaryLiteral {
  public init(dictionaryLiteral elements: (String, FormConciergeMetadataValue)...) {
    self = .object(Dictionary(uniqueKeysWithValues: elements))
  }
}
