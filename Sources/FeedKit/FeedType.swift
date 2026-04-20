//
// FeedType.swift
//
// Copyright (c) 2016 - 2026 Nuno Dias
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

import Foundation

/// Types of feed: RSS, Atom, and JSON.
///
/// The `FeedType` enum helps detect the feed format based on raw data
/// and provides accessors to determine if the feed is XML-based or JSON-based.
///
/// **Note:** FeedKit handles the automatic determination of the feed type during
/// parsing, so you generally don't need to manually detect the feed type. However,
/// using `FeedType` can be helpful when you want to identify the feed type without
/// parsing and decoding the entire feed.
///
/// Example using `switch`:
/// ```swift
/// if let feed = FeedType(data: feedData) {
///   switch feed {
///   case .rss:
///     print("RSS feed detected")
///   case .atom:
///     print("Atom feed detected")
///   case .json:
///     print("JSON feed detected")
///   }
/// }
/// ```
///
/// Example using `if`:
/// ```swift
/// if let feed = FeedType(data: feedData) {
///   if feed.isXML {
///     print("XML-based feed detected")
///   } else if feed.isJson {
///     print("JSON feed detected")
///   }
/// }
/// ```
public enum FeedType {
  /// Represents the RSS 2.0 feed format.
  case rss
  /// Represents the Atom Syndication Format feed.
  case atom
  /// Represents a JSON-formatted feed, commonly used in web APIs.
  case json
}

public extension FeedType {
  /// Returns `true` if the feed type is XML-based (RSS or Atom).
  var isXML: Bool {
    self == .rss || self == .atom
  }

  /// Returns `true` if the feed type is JSON-based.
  var isJson: Bool {
    self == .json
  }
}

// MARK: - FeedInitializable

extension FeedType: FeedInitializable {
  /// Initializes a `FeedType` based on the provided `Data` object.
  ///
  /// - Parameter data: A `Data` object representing a feed to be inspected.
  /// - Returns: A `FeedType` if the data matches a known feed format, otherwise `nil`.
  public init(data: Data) throws {
    let string: String = .init(decoding: data, as: UTF8.self)

    // Determine the feed type
    guard let feedType = FeedType.detectFeedType(from: string) else {
      throw FeedError.unknownFeedFormat
    }
    self = feedType
  }
}

// MARK: -

public extension FeedType {
  /// Detects the feed type from a given string.
  ///
  /// - Parameter string: A string representation of the feed to be inspected.
  /// - Returns: A `FeedType` if the string matches a known feed format, otherwise `nil`.
  private static func detectFeedType(from string: String) -> FeedType? {
    let trimmedString = string.trimmingCharacters(in: .whitespacesAndNewlines)
    guard let firstCharacter = trimmedString.first else {
      return nil
    }

    switch firstCharacter {
    case "<":
      return detectXMLFeedType(in: trimmedString)
    case "{":
      return .json
    default:
      return nil
    }
  }

  /// Detects XML-based feed types from a string.
  ///
  /// - Parameter string: A string representation of the feed to be inspected.
  /// - Returns: A `FeedType` if the string matches a known XML feed format, otherwise `nil`.
  private static func detectXMLFeedType(in string: String) -> FeedType? {
    guard let rootElementName = firstXMLElementName(in: string)?.lowercased() else {
      return nil
    }

    switch rootElementName {
    case "rss", "rdf:rdf":
      return .rss
    case "feed":
      return .atom
    default:
      return nil
    }
  }

  private static func firstXMLElementName(in string: String) -> String? {
    var currentIndex = string.startIndex

    while currentIndex < string.endIndex {
      guard let openIndex = string[currentIndex...].firstIndex(of: "<") else {
        return nil
      }

      let contentStartIndex = string.index(after: openIndex)
      guard contentStartIndex < string.endIndex else {
        return nil
      }

      if string[contentStartIndex] == "?" {
        guard let endIndex = string[contentStartIndex...].range(of: "?>")?.upperBound else {
          return nil
        }
        currentIndex = endIndex
        continue
      }

      if string[contentStartIndex] == "!" {
        if string[contentStartIndex...].hasPrefix("!--") {
          guard let endIndex = string[contentStartIndex...].range(of: "-->")?.upperBound else {
            return nil
          }
          currentIndex = endIndex
          continue
        }

        guard let endIndex = string[contentStartIndex...].firstIndex(of: ">") else {
          return nil
        }
        currentIndex = string.index(after: endIndex)
        continue
      }

      if string[contentStartIndex] == "/" {
        currentIndex = string.index(after: contentStartIndex)
        continue
      }

      let nameStartIndex = contentStartIndex
      var nameEndIndex = nameStartIndex

      while nameEndIndex < string.endIndex {
        let character = string[nameEndIndex]
        if character.isWhitespace || character == ">" || character == "/" {
          break
        }
        nameEndIndex = string.index(after: nameEndIndex)
      }

      guard nameStartIndex < nameEndIndex else {
        return nil
      }

      return String(string[nameStartIndex..<nameEndIndex])
    }

    return nil
  }
}
