//  Created by Cihat Gündüz on 12.03.18.

// swiftlint:disable leveled_print file_types_order

import Foundation
import Rainbow

/// The print level type.
enum PrintLevel {
    /// Print success information.
    case success

    /// Print (potentially) long data or less interesting information. Only printed if tool executed in vebose mode.
    case verbose

    /// Print any kind of information potentially interesting to users.
    case info

    /// Print information that might potentially be problematic.
    case warning

    /// Print information that probably is problematic.
    case error

    var color: Color {
        switch self {
        case .success:
            return Color.lightGreen

        case .verbose:
            return Color.lightCyan

        case .info:
            return Color.lightBlue

        case .warning:
            return Color.yellow

        case .error:
            return Color.red
        }
    }
}

/// The output format type.
enum OutputFormatTarget {
    /// Output is targeted to a console to be read by developers.
    case human

    /// Output is targeted to Xcode. Native support for Xcode Warnings & Errors.
    case xcode
}

/// Prints a message to command line with proper formatting based on level, source & output target.
///
/// - Parameters:
///   - message: The message to be printed. Don't include `Error!`, `Warning!` or similar information at the beginning.
///   - level: The level of the print statement.
///   - file: The file this print statement refers to. Used for showing errors/warnings within Xcode if run as script phase.
///   - line: The line within the file this print statement refers to. Used for showing errors/warnings within Xcode if run as script phase.
func print(_ message: String, level: PrintLevel, file: String? = nil, line: Int? = nil) {
    if TestHelper.shared.isStartedByUnitTests {
        TestHelper.shared.printOutputs.append((message, level, file, line))
        return
    }

    if GlobalOptions.xcodeOutput.value {
        xcodePrint(message, level: level, file: file, line: line)
    } else {
        humanPrint(message, level: level, file: file, line: line)
    }
}

private func humanPrint(_ message: String, level: PrintLevel, file: String? = nil, line: Int? = nil) {
    let location = locationInfo(file: file, line: line)
    let message = location != nil ? [location!, message].joined(separator: " ") : message

    switch level {
    case .success:
        print(currentDateTime(), "✅ ", message.lightGreen)

    case .verbose:
        if GlobalOptions.verbose.value {
            print(currentDateTime(), "🗣 ", message.lightCyan)
        }

    case .info:
        print(currentDateTime(), "ℹ️ ", message.lightBlue)

    case .warning:
        print(currentDateTime(), "⚠️ ", message.yellow)

    case .error:
        print(currentDateTime(), "❌ ", message.lightRed)
    }
}

private func currentDateTime() -> String {
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
    let dateTime = dateFormatter.string(from: Date())
    return "\(dateTime):"
}

private func xcodePrint(_ message: String, level: PrintLevel, file: String? = nil, line: Int? = nil) {
    let location = locationInfo(file: file, line: line)

    switch level {
    case .success:
        if let location = location {
            print(location, "success: sdm: ", message)
        } else {
            print("success: sdm: ", message)
        }

    case .verbose:
        if GlobalOptions.verbose.value {
            if let location = location {
                print(location, "verbose: sdm: ", message)
            } else {
                print("verbose: sdm: ", message)
            }
        }

    case .info:
        if let location = location {
            print(location, "info: sdm: ", message)
        } else {
            print("info: sdm: ", message)
        }

    case .warning:
        if let location = location {
            print(location, "warning: sdm: ", message)
        } else {
            print("warning: sdm: ", message)
        }

    case .error:
        if let location = location {
            print(location, "error: sdm: ", message)
        } else {
            print("error: sdm: ", message)
        }
    }
}

private func locationInfo(file: String?, line: Int?) -> String? {
    guard let file = file else { return nil }
    guard let line = line else { return "\(file): " }
    return "\(file):\(line): "
}

private let dispatchGroup = DispatchGroup()

func measure<ResultType>(task: String, _ closure: () throws -> ResultType) rethrows -> ResultType {
    let startDate = Date()
    let result = try closure()

    let passedTimeInterval = Date().timeIntervalSince(startDate)
    guard passedTimeInterval > 0.1 else { return result } // do not print fast enough tasks

    let passedTimeIntervalNum = NSNumber(value: passedTimeInterval)
    let measureTimeFormatter = NumberFormatter()
    measureTimeFormatter.minimumIntegerDigits = 1
    measureTimeFormatter.maximumFractionDigits = 3
    measureTimeFormatter.locale = Locale(identifier: "en")

    print("Task '\(task)' took \(measureTimeFormatter.string(from: passedTimeIntervalNum)!) seconds.")
    return result
}

