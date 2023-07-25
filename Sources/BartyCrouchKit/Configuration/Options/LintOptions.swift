// Created by Cihat Gündüz on 06.11.18.

import Foundation
import MungoHealer
import Toml

struct LintOptions {
    let duplicateKeys: Bool
    let emptyValues: Bool
}

extension LintOptions: TomlCodable {
    static func make(toml: Toml) throws -> LintOptions {
        let lint: String = "lint"

        return LintOptions(
            duplicateKeys: toml.bool(lint, "duplicateKeys") ?? true,
            emptyValues: toml.bool(lint, "emptyValues") ?? true
        )
    }

    func tomlContents() -> String {
        var lines: [String] = ["[lint]"]

        lines.append("duplicateKeys = \(duplicateKeys)")
        lines.append("emptyValues = \(emptyValues)")

        return lines.joined(separator: "\n")
    }
}
