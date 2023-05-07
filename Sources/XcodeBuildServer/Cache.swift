//
//  Cache.swift
//  
//
//  Created by Kazuki Yamamoto on 2023/05/07.
//

import Foundation
import TSCBasic

struct Cache {
    var xcodebuild: XcodeBuild?
    var indexes: BuildIndexes = .init()
    var settings: [BuildSettings] = []
    var indexStorePath: AbsolutePath?
    var config: Config = .init()
}
