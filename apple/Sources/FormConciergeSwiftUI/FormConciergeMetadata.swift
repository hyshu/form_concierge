import Foundation

/// A JSON-compatible value attached to a survey response as metadata.
public enum FormConciergeMetadataValue: Codable, Sendable {
  /// A JSON string value.
  case string(String)
  /// A JSON number value.
  case number(Double)
  /// A JSON Boolean value.
  case bool(Bool)
  /// A JSON object whose members are indexed by name.
  case object([String: FormConciergeMetadataValue])
  /// An ordered array of JSON values.
  case array([FormConciergeMetadataValue])
  /// An explicit JSON null value.
  case null

  /// Decodes this value from the supplied decoder.
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

  /// Encodes this value using the supplied encoder.
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
  /// Creates a metadata value from a string literal.
  public init(stringLiteral value: String) {
    self = .string(value)
  }
}

extension FormConciergeMetadataValue: ExpressibleByIntegerLiteral {
  /// Creates a metadata value from a integer literal.
  public init(integerLiteral value: Int) {
    self = .number(Double(value))
  }
}

extension FormConciergeMetadataValue: ExpressibleByFloatLiteral {
  /// Creates a metadata value from a float literal.
  public init(floatLiteral value: Double) {
    self = .number(value)
  }
}

extension FormConciergeMetadataValue: ExpressibleByBooleanLiteral {
  /// Creates a metadata value from a boolean literal.
  public init(booleanLiteral value: Bool) {
    self = .bool(value)
  }
}

extension FormConciergeMetadataValue: ExpressibleByArrayLiteral {
  /// Creates a metadata value from a array literal.
  public init(arrayLiteral elements: FormConciergeMetadataValue...) {
    self = .array(elements)
  }
}

extension FormConciergeMetadataValue: ExpressibleByDictionaryLiteral {
  /// Creates a metadata value from a dictionary literal.
  public init(dictionaryLiteral elements: (String, FormConciergeMetadataValue)...) {
    self = .object(Dictionary(uniqueKeysWithValues: elements))
  }
}
