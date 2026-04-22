//
// RSSTests.swift
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

@testable import FeedKit
import Foundation
import Testing

@Suite("RSS")
struct RSSTests: FeedKitTestable {
  @Test
  func rss() throws {
    // Given
    let data = data(resource: "RSS", withExtension: "xml")
    let expected: RSSFeed = mock

    // When
    let actual = try RSSFeed(data: data)

    // Then
    #expect(expected == actual)
  }

  @Test
  func lossyDecodingDisabledByDefault() throws {
    // Given
    let data = data(resource: "LossyRSS", withExtension: "xml")

    // When / Then
    #expect(throws: DecodingError.self) {
      try RSSFeed(data: data)
    }
  }

  @Test
  func lossyDecodingAllowsMalformedOptionalNumbers() throws {
    // Given
    let data = data(resource: "LossyRSS", withExtension: "xml")

    // When
    let actual = try RSSFeed(data: data, lossy: true)

    // Then
    #expect(actual.channel?.image?.width == nil)
    #expect(actual.channel?.image?.height == nil)
    #expect(actual.channel?.items?.first?.enclosure?.attributes?.length == nil)
    #expect(actual.channel?.items?.first?.media?.contents?.first?.attributes?.height == nil)
    #expect(actual.channel?.items?.first?.media?.contents?.first?.attributes?.width == 1280)
  }

  @Test
  func namespacedSourceExtensionDoesNotDecodeAsRSSSource() throws {
    // Given
    let data = Data(
      """
      <rss xmlns:source="http://source.scripting.com/" version="2.0">
        <channel>
          <title>Jonathan Hays</title>
          <link>https://jonhays.me/</link>
          <description></description>
          <item>
            <title></title>
            <link>https://jonhays.me/2026/04/16/finished-reading-marble-hall-murders.html</link>
            <pubDate>Thu, 16 Apr 2026 22:20:08 -0700</pubDate>
            <guid>http://cheesemaker.micro.blog/2026/04/16/finished-reading-marble-hall-murders.html</guid>
            <description>Finished reading Marble Hall Murders</description>
            <source:markdown>Finished reading: [Marble Hall Murders](https://micro.blog/books/9780063444621)</source:markdown>
          </item>
        </channel>
      </rss>
      """.utf8
    )

    // When
    let actual = try RSSFeed(data: data)

    // Then
    #expect(actual.channel?.items?.count == 1)
    #expect(actual.channel?.items?.first?.source == nil)
    #expect(actual.channel?.items?.first?.markdown == "Finished reading: [Marble Hall Murders](https://micro.blog/books/9780063444621)")
  }
}
