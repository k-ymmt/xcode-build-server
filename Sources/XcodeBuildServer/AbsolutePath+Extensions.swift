//
//  AbsolutePath+Extensions.swift
//  
//
//  Created by Kazuki Yamamoto on 2023/05/02.
//

import Foundation
import TSCBasic

private func eraseFileScheme(uri: String) -> String {
    guard uri.hasPrefix("file:") else {
        return uri
    }

    return String(uri.trimmingPrefix("file:"))
}

extension AbsolutePath {
    init(erasingFileScheme uri: String) throws {
        try self.init(validating: eraseFileScheme(uri: uri))
    }
}
