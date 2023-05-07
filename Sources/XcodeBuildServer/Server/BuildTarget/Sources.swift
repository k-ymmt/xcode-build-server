//
//  Sources.swift
//  
//
//  Created by Kazuki Yamamoto on 2023/05/04.
//

import Foundation

extension Server {
    struct BuildTargetSources: DispatchHandler {
        struct Request: BuildServerProtocolRequest {
            let id: Int
            let method: String
        }

        struct Response: BuildServerProtocolResponse {
            struct Result: Encodable {
                struct Item: Encodable {
                }
                let items: [Item]
            }
            let jsonrpc: String = "2.0"
            let id: Int
            let result: Result
        }

        func receive(request: Request, cache: inout Cache) -> Response {
            .init(id: request.id, result: .init(items: []))
        }
    }
}
