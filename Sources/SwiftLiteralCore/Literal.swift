import Foundation
import IssueReporting
import SwiftLiteralReflection
import SwiftSyntax

/// Write a runtime value back out as Swift source.
///
/// Two entry points. ``source(of:named:header:context:)`` gives you the text.
/// ``write(_:named:file:directory:allowOverwrite:header:context:fileID:filePath:)`` puts it on disk.
///
/// ```swift
/// let user = User(id: 42, name: "Alice")
/// try Literal.write(user, named: "testUser")
/// ```
///
/// That writes `User+testUser.swift`:
///
/// ```swift
/// extension User {
///     static let testUser: User = User(id: 42, name: "Alice")
/// }
/// ```
///
/// From then on `User.testUser` is ordinary Swift. It has autocomplete. It has
/// jump-to-definition. If you rename `name`, it stops compiling, and the compiler tells
/// you where.
///
/// ## Where the file goes
///
/// First of these that is set:
///
/// 1. the `directory` argument
/// 2. ``LiteralConfig/setGlobalRoot(_:)``
/// 3. the `SWIFT_SNAPSHOT_ROOT` environment variable
/// 4. `__Snapshots__`, next to the file that called it
///
/// ## Debug builds only
///
/// In a release build, ``write(_:named:file:directory:allowOverwrite:header:context:fileID:filePath:)``
/// does nothing and reports an issue. Writing source files is something you do while
/// writing tests, not something a shipped app does.
public enum Literal {
  /// Render a value as Swift source, without touching the disk.
  ///
  /// - Parameters:
  ///   - value: The value to render.
  ///   - name: The static property name. Sanitized to a valid identifier.
  ///   - header: A comment for the top of the file. Falls back to
  ///     ``LiteralConfig/setGlobalHeader(_:)``.
  ///   - context: A doc comment for the property.
  /// - Throws: `LiteralError` if the value cannot be rendered or the source cannot be
  ///   formatted.
  public static func source<T>(
    of value: T,
    named name: String,
    header: String? = nil,
    context: String? = nil
  ) throws -> String {
    let variableName = sanitize(name)

    let formatting: FormatProfile
    if let configSource = LiteralConfig.getFormatConfigSource() {
      formatting = try FormatConfigLoader.loadProfile(from: configSource)
    } else {
      formatting = LiteralConfig.formattingProfile()
    }

    let expression = try ValueRenderer.render(
      value,
      context: RenderContext(options: LiteralConfig.renderOptions())
    )

    return CodeFormatter.formatFile(
      typeName: String(describing: T.self),
      variableName: variableName,
      expression: expression,
      header: header ?? LiteralConfig.getGlobalHeader(),
      context: context,
      profile: formatting
    )
  }

  /// Render a value as Swift source and write it to a file.
  ///
  /// - Parameters:
  ///   - value: The value to write.
  ///   - name: The static property name. Sanitized to a valid identifier.
  ///   - file: File name without the extension. Defaults to `TypeName+name`.
  ///   - directory: Where to write. Overrides the global root.
  ///   - allowOverwrite: Replace an existing file. `true` by default.
  ///   - header: A comment for the top of the file.
  ///   - context: A doc comment for the property.
  ///   - fileID: Captured automatically. Used to place the default output directory.
  ///   - filePath: Captured automatically. Used to place the default output directory.
  /// - Returns: The file that was written.
  /// - Throws: `LiteralError` if the value cannot be rendered, the file exists and
  ///   `allowOverwrite` is `false`, or the write fails.
  @discardableResult
  public static func write<T>(
    _ value: T,
    named name: String,
    file: String? = nil,
    directory: String? = nil,
    allowOverwrite: Bool = true,
    header: String? = nil,
    context: String? = nil,
    fileID: StaticString = #fileID,
    filePath: StaticString = #filePath
  ) throws -> URL {
    #if DEBUG
    let variableName = sanitize(name)
    let code = try source(of: value, named: variableName, header: header, context: context)

    let destination = PathResolver.resolveFilePath(
      typeName: String(describing: T.self),
      variableName: variableName,
      file: file,
      outputDirectory: PathResolver.resolveOutputDirectory(
        directory: directory,
        fileID: fileID,
        filePath: filePath
      )
    )

    if !allowOverwrite, FileManager.default.fileExists(atPath: destination.path) {
      throw LiteralError.overwriteDisallowed(destination)
    }

    do {
      try FileManager.default.createDirectory(
        at: destination.deletingLastPathComponent(),
        withIntermediateDirectories: true
      )
    } catch {
      throw LiteralError.io("Failed to create directory: \(error.localizedDescription)")
    }

    do {
      try code.write(to: destination, atomically: true, encoding: .utf8)
    } catch {
      throw LiteralError.io("Failed to write file: \(error.localizedDescription)")
    }

    return destination
    #else
    reportIssue("Literal.write was called in a release build. It did nothing.")
    return URL(fileURLWithPath: "/dev/null")
    #endif
  }

  /// Make a string usable as a Swift property name.
  ///
  /// Keywords get backticks. Anything that is not a letter, digit, or underscore becomes
  /// an underscore. A leading digit gets an underscore in front of it.
  static func sanitize(_ name: String) -> String {
    let keywords: Set<String> = [
      "associatedtype", "class", "deinit", "enum", "extension", "fileprivate", "func",
      "import", "init", "inout", "internal", "let", "open", "operator", "private",
      "precedencegroup", "protocol", "public", "rethrows", "static", "struct",
      "subscript", "typealias", "var", "break", "case", "catch", "continue", "default",
      "defer", "do", "else", "fallthrough", "for", "guard", "if", "in", "repeat",
      "return", "throw", "switch", "where", "while", "as", "false", "is", "nil",
      "self", "Self", "super", "throws", "true", "try", "await", "async",
    ]

    if keywords.contains(name) { return "`\(name)`" }

    var result = String(
      name.map { character in
        character.isLetter || character.isNumber || character == "_" ? character : "_"
      })

    if result.isEmpty || result.allSatisfy({ $0 == "_" }) { return "_" }
    if result.first?.isNumber == true { result = "_" + result }
    return result
  }
}
