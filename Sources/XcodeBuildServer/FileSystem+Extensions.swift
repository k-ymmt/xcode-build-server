//
//  FileSystem+Extensions.swift
//  
//
//  Created by Kazuki Yamamoto on 2023/05/07.
//

import Foundation
import TSCBasic

extension FileSystem {
    var xcodeBuildServerCacheDirectory: AbsolutePath? {
        guard let cacheDirectory = localFileSystem.cachesDirectory else {
            return nil
        }

        return cacheDirectory.appending(component: "xcode-build-server")
    }
}
