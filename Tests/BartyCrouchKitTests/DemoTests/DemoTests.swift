// Created by Cihat Gündüz on 18.01.19.

@testable import BartyCrouchKit
import XCTest
import Toml

@available(OSX 10.12, *)
class DemoTests: XCTestCase {
    static let testDemoDirectoryUrl: URL = FileManager.default.temporaryDirectory.appendingPathComponent("Demo")

    // NOTE: Uncomment and run to update demo directory data – also comment out setUp() and tearDown() to prevent issues
//    func testSnapshotDemoData() {
//        DemoData.record(directoryPath: "/absolute/path/to/BartyCrouch/Demo/Untouched")
//    }

    override func setUp() {
        super.setUp()

        TestHelper.shared.reset()
        TestHelper.shared.isStartedByUnitTests = true
        try! FileManager.default.removeContentsOfDirectory(at: DemoTests.testDemoDirectoryUrl)

        let jsonData = DemoData.untouchedDemoDirectoryJson.data(using: .utf8)!
        let directory = try! JSONDecoder().decode(Directory.self, from: jsonData)
        directory.files.forEach { try! $0.write(into: DemoTests.testDemoDirectoryUrl) }

        FileManager.default.changeCurrentDirectoryPath(DemoTests.testDemoDirectoryUrl.path)
    }

    override func tearDown() {
        super.tearDown()

        try! FileManager.default.removeContentsOfDirectory(at: DemoTests.testDemoDirectoryUrl)
    }

    func testInitTaskHandler() {
        XCTAssertFalse(FileManager.default.fileExists(atPath: Configuration.fileName))

        InitTaskHandler().perform()

        XCTAssertTrue(FileManager.default.fileExists(atPath: Configuration.fileName))
        XCTAssertEqual(TestHelper.shared.printOutputs.count, 1)
        XCTAssertEqual(TestHelper.shared.printOutputs[0].level, .success)
        XCTAssertEqual(TestHelper.shared.printOutputs[0].message, "Successfully created file \(Configuration.fileName)")
    }

    func testLintTaskHandlerWithDefaultConfig() {
        LintTaskHandler(options: try! LintOptions.make(toml: Toml())).perform()

        XCTAssertEqual(TestHelper.shared.printOutputs.count, 10)

        for printOutput in TestHelper.shared.printOutputs.dropLast() {
            XCTAssertEqual(printOutput.level, .warning)
        }

        for (indices, langCode) in [([0, 1, 2], "de"), ([3, 4, 5], "en"), ([6, 7, 8], "tr")] {
            XCTAssertEqual(TestHelper.shared.printOutputs[indices[0]].message, "Found 2 translations for key 'Existing Duplicate Key'. Other entries at: [13]")
            XCTAssertEqual(TestHelper.shared.printOutputs[indices[0]].line, 11)

            XCTAssertEqual(TestHelper.shared.printOutputs[indices[1]].message, "Found 2 translations for key 'Existing Duplicate Key'. Other entries at: [11]")
            XCTAssertEqual(TestHelper.shared.printOutputs[indices[1]].line, 13)

            XCTAssertEqual(TestHelper.shared.printOutputs[indices[2]].message, "Found empty value for key 'Existing Empty Value Key'.")
            XCTAssertEqual(TestHelper.shared.printOutputs[indices[2]].line, 15)

            indices.forEach { index in
                XCTAssertEqual(
                    String(TestHelper.shared.printOutputs[index].file!.suffix(from: "/private".endIndex)),
                    DemoTests.testDemoDirectoryUrl.appendingPathComponent("Demo/\(langCode).lproj/Localizable.strings").path
                )
            }
        }

        XCTAssertEqual(TestHelper.shared.printOutputs.last!.level, .warning)
        XCTAssertEqual(TestHelper.shared.printOutputs.last!.message, "6 issue(s) found in 3 file(s). Executed 2 checks in 8 Strings file(s) in total.")
    }

    func testCodeTaskHandlerWithDefaultConfig() {
        CodeTaskHandler(options: try! CodeOptions.make(toml: Toml())).perform()

        XCTAssertEqual(TestHelper.shared.printOutputs.map { $0.message }, ["Successfully updated strings file(s) of Code files."])
        XCTAssertEqual(TestHelper.shared.printOutputs.map { $0.level }, [.success])

        // TODO: check if files were actually changed correctly
    }

    func testInterfacesTaskHandlerWithDefaultConfig() {
        InterfacesTaskHandler(options: try! InterfacesOptions.make(toml: Toml())).perform()

        XCTAssertEqual(TestHelper.shared.printOutputs.count, 2)

        for printOutput in TestHelper.shared.printOutputs {
            XCTAssertEqual(printOutput.message, "Successfully updated strings file(s) of Storyboard or XIB file.")
            XCTAssertEqual(printOutput.level, .success)
        }

        XCTAssertEqual(
            String(TestHelper.shared.printOutputs[0].file!.suffix(from: "/private".endIndex)),
            DemoTests.testDemoDirectoryUrl.appendingPathComponent("Demo/Base.lproj/LaunchScreen.storyboard").path
        )

        XCTAssertEqual(
            String(TestHelper.shared.printOutputs[1].file!.suffix(from: "/private".endIndex)),
            DemoTests.testDemoDirectoryUrl.appendingPathComponent("Demo/Base.lproj/Main.storyboard").path
        )

        // TODO: check if files were actually changed correctly
    }

    func testNormalizeTaskHandlerWithDefaultConfig() {
        NormalizeTaskHandler(options: try! NormalizeOptions.make(toml: Toml())).perform()

        let expectedMessages: [String] = [
            "Adding missing keys [\"Ibu-xm-woE.text\", \"cGW-hC-L0h.text\", \"dgI-jn-hzN.text\"].",
            "Adding missing keys [\"Ibu-xm-woE.text\", \"cGW-hC-L0h.text\", \"dgI-jn-hzN.text\"].",
            "Adding missing keys [\"Existing Only in English Key\"].",
            "Adding missing keys [\"Existing Only in English Key\"]."
        ]

        let expectedPaths: [String] = [
            DemoTests.testDemoDirectoryUrl.appendingPathComponent("Demo/de.lproj/Main.strings").path,
            DemoTests.testDemoDirectoryUrl.appendingPathComponent("Demo/tr.lproj/Main.strings").path,
            DemoTests.testDemoDirectoryUrl.appendingPathComponent("Demo/de.lproj/Localizable.strings").path,
            DemoTests.testDemoDirectoryUrl.appendingPathComponent("Demo/tr.lproj/Localizable.strings").path
        ]

        for (index, printOutput) in TestHelper.shared.printOutputs.enumerated() {
            XCTAssertEqual(printOutput.message, expectedMessages[index])
            XCTAssertEqual(String(printOutput.file!.suffix(from: "/private".endIndex)), expectedPaths[index])
            XCTAssertEqual(printOutput.level, .info)
        }

        // TODO: check if files were actually changed correctly
    }

    func testTranslateTaskHandlerWithDefaultConfig() {
        XCTAssertThrowsError(try TranslateOptions.make(toml: Toml()))
    }

    func testTranslateTaskHandlerWithConfiguredSecret() {
        let microsoftSubscriptionKey = "" // TODO: load from environment variable
        guard !microsoftSubscriptionKey.isEmpty else { return }

        let translateOptions = TranslateOptions(path: ".", secret: microsoftSubscriptionKey, sourceLocale: "en")
        TranslateTaskHandler(options: translateOptions).perform()

        let expectedMessages: [String] = [
            "Successfully translated 6 values in 2 files.",
            "Value for key \'Existing Empty Value Key\' in source translations is empty.",
            "Value for key \'Existing Empty Value Key\' in source translations is empty.",
            "Successfully translated 2 values in 2 files."
        ]

        let expectedPaths: [String] = [
            DemoTests.testDemoDirectoryUrl.appendingPathComponent("Demo/en.lproj/Main.strings").path,
            DemoTests.testDemoDirectoryUrl.appendingPathComponent("Demo/en.lproj/Localizable.strings").path,
            DemoTests.testDemoDirectoryUrl.appendingPathComponent("Demo/en.lproj/Localizable.strings").path,
            DemoTests.testDemoDirectoryUrl.appendingPathComponent("Demo/en.lproj/Localizable.strings").path
        ]

        let expectedLevels: [PrintLevel] = [.success, .warning, .warning, .success]
        let expectedLines: [Int?] = [nil, 15, 15, nil]

        for (index, printOutput) in TestHelper.shared.printOutputs.enumerated() {
            XCTAssertEqual(printOutput.message, expectedMessages[index])
            XCTAssertEqual(String(printOutput.file!.suffix(from: "/private".endIndex)), expectedPaths[index])
            XCTAssertEqual(printOutput.level, expectedLevels[index])
            XCTAssertEqual(printOutput.line, expectedLines[index])
        }

        // TODO: check if files were actually changed correctly
    }
}
