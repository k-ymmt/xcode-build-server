//
//  RegisterForChanges.swift
//  
//
//  Created by Kazuki Yamamoto on 2023/05/04.
//

import Foundation

extension Server {
    struct TextDocumentSourceKitOptions: DispatchHandler {
        struct Request: BuildServerProtocolRequest {
            struct Params: Decodable {
                let uri: String
            }
            let id: Int
            let method: String
            let params: Params
        }
        struct Response: BuildServerProtocolResponse {
            let jsonrpc: String = "2.0"
            let id: Int
            let result: Notification.Params.UpdatedOptions
        }

        func receive(request: Request, cache: inout Cache) throws -> Response {
            struct Error: Swift.Error {
                let message: String
            }
            guard let options = try Server.Notification.Params.UpdatedOptions(uri: request.params.uri, cache: &cache) else {
                throw Error(message: "Build options not found.")
            }
            return .init(
                id: request.id,
                result: options
            )
        }
    }
}
