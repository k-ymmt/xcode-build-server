//
//  RegisterForChanges.swift
//
//
//  Created by Kazuki Yamamoto on 2023/05/04.
//

import Foundation
import TSCBasic

extension Server {
    struct TextDocumentRegisterForChanges: DispatchHandler {
        struct Request: BuildServerProtocolRequest {
            struct Params: Decodable {
                let action: String
                let uri: String
            }
            let id: Int
            let method: String
            let params: Params
        }

        typealias Response = EmptyResponse

        func receive(request: Request, cache: inout Cache) throws -> EmptyResponse {
            struct EmptyResponse: Encodable {
                struct Result: Encodable {
                }
                let jsonrpc: String = "2.0"
                let id: Int
                let result: Result = .init()
            }
            send(EmptyResponse(id: request.id))
            guard
                request.params.action == "register",
                let options = try Server.Notification.Params.UpdatedOptions(uri: request.params.uri, cache: &cache)
            else {
                return .init()
            }

            let notification = Notification(
                method: "build/sourceKitOptionsChanged",
                params: .init(
                    uri: request.params.uri,
                    updatedOptions: options
                )
            )
            send(notification)
            return .init()
        }
    }
}
