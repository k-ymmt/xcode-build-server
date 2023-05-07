//
//  BuildTargets.swift
//  
//
//  Created by Kazuki Yamamoto on 2023/05/04.
//

import Foundation

extension Server {
    struct WorkspaceBuildTargets: DispatchHandler {
        struct Request: BuildServerProtocolRequest {
            let id: Int
            let method: String
        }

        struct Response: BuildServerProtocolResponse {
            struct Result: Encodable {
                struct Target: Encodable {
                }
                let targets: [Target]
            }
            let jsonrpc: String = "2.0"
            let id: Int
            let result: Result
        }

        func receive(request: Request, cache: inout Cache) -> Response {
            .init(id: request.id, result: .init(targets: []))
        }
    }
}
