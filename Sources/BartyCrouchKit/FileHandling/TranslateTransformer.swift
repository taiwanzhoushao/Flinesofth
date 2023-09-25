// Created by Cihat Gündüz on 24.01.19.

import Foundation
import SwiftSyntax

class TranslateTransformer: SyntaxRewriter {
    let transformer: Transformer
    let typeName: String
    let translateMethodName: String
    let caseToLangCode: [String: String]

    var translateEntries: [CodeFileUpdater.TranslateEntry] = []

    init(transformer: Transformer, typeName: String, translateMethodName: String, caseToLangCode: [String: String]) {
        self.transformer = transformer
        self.typeName = typeName
        self.translateMethodName = translateMethodName
        self.caseToLangCode = caseToLangCode
    }

    override func visit(_ functionCallExpression: FunctionCallExprSyntax) -> ExprSyntax {
        guard
            let memberAccessExpression = functionCallExpression.child(at: 0) as? MemberAccessExprSyntax,
            memberAccessExpression.description == "\(typeName).\(translateMethodName)",
            let functionCallArgumentList = functionCallExpression.child(at: 2) as? FunctionCallArgumentListSyntax,
            let keyFunctionCallArgument = functionCallArgumentList.child(at: 0) as? FunctionCallArgumentSyntax,
            keyFunctionCallArgument.label?.text == "key",
            let keyStringLiteralExpression = keyFunctionCallArgument.child(at: 2) as? StringLiteralExprSyntax,
            let translationsFunctionCallArgument = functionCallArgumentList.child(at: 1) as? FunctionCallArgumentSyntax,
            translationsFunctionCallArgument.label?.text == "translations",
            let translationsDictionaryExpression = translationsFunctionCallArgument.child(at: 2) as? DictionaryExprSyntax,
            let translationsDictionaryElementList = translationsDictionaryExpression.child(at: 1) as? DictionaryElementListSyntax
        else {
            return functionCallExpression
        }

        let key = keyStringLiteralExpression.text

        guard !key.isEmpty else {
            print("Found empty key in translate entry '\(functionCallExpression)'.", level: .warning)
            return functionCallExpression
        }

        var translations: [CodeFileUpdater.TranslationElement] = []

        for dictionaryElement in translationsDictionaryElementList {
            guard
                let keyExpression = dictionaryElement.child(at: 0) as? ImplicitMemberExprSyntax,
                let langCaseToken = keyExpression.child(at: 1) as? TokenSyntax,
                let translationLiteralExpression = dictionaryElement.child(at: 2) as? StringLiteralExprSyntax
            else {
                return functionCallExpression
            }

            let langCase = langCaseToken.text
            let translation = translationLiteralExpression.text

            guard !translation.isEmpty else {
                print("Translation for langCase '\(langCase)' was empty.", level: .warning)
                continue
            }

            guard let langCode = caseToLangCode[langCase] else {
                print("Could not find a langCode for langCase '\(langCase)' when transforming translation.", level: .warning)
                continue
            }

            translations.append((langCode: langCode, translation: translation))
        }

        let comment: String? = nil // TODO: get comment argument if available

        let translateEntry: CodeFileUpdater.TranslateEntry = (key: key, translations: translations, comment: comment)
        translateEntries.append(translateEntry)

        print("Found translate entry with key '\(key)' and \(translations.count) translations.", level: .info)

        let transformedExpression: ExprSyntax = {
            switch transformer {
            case .foundation:
                return buildFoundationExpression(key: key, comment: comment)

            case .swiftgenStructured:
                return buildSwiftgenStructuredExpression(key: key)
            }
        }()

        print("Transformed '\(functionCallExpression)' to '\(transformedExpression)'.", level: .info)

        return transformedExpression
    }

    private func buildSwiftgenStructuredExpression(key: String) -> ExprSyntax {
        // e.g. the key could be something like 'ONBOARDING.FIRST_PAGE.HEADER_TITLE' or 'onboarding.first-page.header-title'
        let keywordSeparators: CharacterSet = CharacterSet(charactersIn: ".")
        let casingSeparators: CharacterSet = CharacterSet(charactersIn: "-_")

        // e.g. ["ONBOARDING", "FIRST_PAGE", "HEADER_TITLE"]
        let keywords: [String] = key.components(separatedBy: keywordSeparators)

        // e.g. [["ONBOARDING"], ["FIRST", "PAGE"], ["HEADER", "TITLE"]]
        let keywordsCasingComponents: [[String]] = keywords.map { $0.components(separatedBy: casingSeparators) }

        // e.g. ["Onboarding", "FirstPage", "HeaderTitle"]
        var swiftgenKeyComponents: [String] = keywordsCasingComponents.map { $0.map { $0.capitalized }.joined() }

        // e.g. ["Onboarding", "FirstPage", "headerTitle"]
        let lastKeyComponentIndex: Int = swiftgenKeyComponents.endIndex - 1
        swiftgenKeyComponents[lastKeyComponentIndex] = swiftgenKeyComponents[lastKeyComponentIndex].firstCharacterLowercased()

        // e.g. ["L10n", "Onboarding", "FirstPage", "headerTitle"]
        swiftgenKeyComponents.insert("L10n", at: 0)

        return buildMemberAccessExpression(components: swiftgenKeyComponents)
    }

    private func buildMemberAccessExpression(components: [String]) -> ExprSyntax {
        let identifierToken = SyntaxFactory.makeIdentifier(components.last!)
        guard components.count > 1 else { return SyntaxFactory.makeIdentifierExpr(identifier: identifierToken, declNameArguments: nil) }

        return SyntaxFactory.makeMemberAccessExpr(
            base: buildMemberAccessExpression(components: Array(components.dropLast())),
            dot: SyntaxFactory.makePeriodToken(),
            name: identifierToken,
            declNameArguments: nil
        )
    }

    private func buildFoundationExpression(key: String, comment: String?) -> ExprSyntax {
        let keyArgument = SyntaxFactory.makeFunctionCallArgument(
            label: nil,
            colon: nil,
            expression: SyntaxFactory.makeStringLiteralExpr(key),
            trailingComma: SyntaxFactory.makeCommaToken(leadingTrivia: .zero, trailingTrivia: .spaces(1))
        )

        let commentArgument = SyntaxFactory.makeFunctionCallArgument(
            label: SyntaxFactory.makeIdentifier("comment"),
            colon: SyntaxFactory.makeColonToken(leadingTrivia: .zero, trailingTrivia: .spaces(1)),
            expression: SyntaxFactory.makeStringLiteralExpr(comment ?? ""),
            trailingComma: nil
        )

        return SyntaxFactory.makeFunctionCallExpr(
            calledExpression: SyntaxFactory.makeIdentifierExpr(identifier: SyntaxFactory.makeIdentifier("NSLocalizedString"), declNameArguments: nil),
            leftParen: SyntaxFactory.makeLeftParenToken(),
            argumentList: SyntaxFactory.makeFunctionCallArgumentList([keyArgument, commentArgument]),
            rightParen: SyntaxFactory.makeRightParenToken(),
            trailingClosure: nil
        )
    }
}

extension StringLiteralExprSyntax {
    var text: String {
        let description: String = self.description
        guard description.count > 2 else { return "" }

        let textRange = description.index(description.startIndex, offsetBy: 1) ..< description.index(description.endIndex, offsetBy: -1)
        return String(description[textRange])
    }
}
