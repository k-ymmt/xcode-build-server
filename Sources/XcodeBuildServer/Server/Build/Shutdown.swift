//
//  Shutdown.swift
//  
//
//  Created by Kazuki Yamamoto on 2023/05/04.
//

import Foundation

extension Server {
    struct BuildShutdown: DispatchHandler {
        struct Request: BuildServerProtocolRequest {
            let id: Int
            let method: String
        }

        struct Response: BuildServerProtocolResponse {
            let jsonrpc: String = "2.0"
            let id: Int
            let result: Int?
        }

        func receive(request: Request, cache: inout Cache) -> Response {
            .init(id: request.id, result: nil)
        }
    }
}
