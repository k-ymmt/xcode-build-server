//
//  Logger.swift
//  
//
//  Created by Kazuki Yamamoto on 2023/05/02.
//

import Foundation
import os
import TSCBasic

private let formatter = ISO8601DateFormatter()
enum Logger {
    private static let fileName: String = "xcode-build-server-\(formatter.string(from: .now)).log"

    static func debug(_ items: Any?...) {
        log(level: .debug, items)
    }

    static func info(_ items: Any?...) {
        log(level: .info, items)
    }
    static func error(_ items: Any?...) {
        log(level: .error, items)
    }
    static func fault(_ items: Any?...) {
        log(level: .fault, items)
    }

    private static func log(level: os.OSLogType, _ items: Any?...) {
#if DEBUG
        guard
            let cache = localFileSystem.cachesDirectory,
            let output = OutputStream(url: cache.appending(components: ["xcode-build-server", fileName]).asURL, append: true)
        else {
            return
        }
        let message = "\(level.symbol)[\(formatter.string(from: .now))] \(items.map { $0 ?? "nil" }.map(String.init(describing:)).joined(separator: " "))\n"
        output.open()
        defer { output.close() }
        output.write(message, maxLength: message.utf8.count)
#else
#endif
    }
}

extension os.OSLogType {
    var symbol: String {
        switch self {
        case .debug:
            return "🐛"
        case .info, .default:
            return "ℹ️"
        case .error:
            return "🛑"
        case .fault:
            return "💥"
        default:
            return "⚠️"
        }
    }
}
