//
//  Config.swift
//  
//
//  Created by Kazuki Yamamoto on 2023/05/07.
//

import Foundation

struct Config: Decodable {
    let project: String?
    let workspace: String?
    let scheme: String?
    let configuration: String?
    let destination: String?

    init(project: String? = nil, workspace: String? = nil, scheme: String? = nil, configuration: String? = nil, destination: String? = nil) {
        self.project = project
        self.workspace = workspace
        self.scheme = scheme
        self.configuration = configuration
        self.destination = destination
    }
}
