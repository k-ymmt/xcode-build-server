//
//  Server.swift
//  
//
//  Created by Kazuki Yamamoto on 2023/04/30.
//

import Foundation
import TSCBasic

func send(data: Data) {
    guard let string = String(data: data, encoding: .utf8) else {
        return
    }
    print("Content-Length: \(string.utf8.count)\r\n\r\n\(string)", terminator: "")
    fflush(stdout)
    Logger.debug("send: ", string)
}

func send<Object: Encodable>(_ value: Object) {
    guard
        let data = try? jsonEncoder.encode(value)
    else {
        return
    }
    send(data: data)
}

protocol BuildServerProtocolRequest: Decodable {
    var method: String { get }
}

protocol BuildServerProtocolWithIDRequest: BuildServerProtocolRequest {
    var id: Int { get }
}

protocol BuildServerProtocolResponse: Encodable {
    var jsonrpc: String { get }
}

protocol BuildServerProtocolWithIDResponse: BuildServerProtocolResponse {
}

struct EmptyRequest: BuildServerProtocolRequest {
    let method: String
}

struct EmptyResponse: BuildServerProtocolResponse {
    let jsonrpc: String = "2.0"
}

protocol DispatchHandler {
    associatedtype Request: BuildServerProtocolRequest = EmptyRequest
    associatedtype Response: BuildServerProtocolResponse = EmptyResponse
    func receive(request: Request, cache: inout Cache) throws -> Response
}

let jsonEncoder = JSONEncoder()
extension DispatchHandler {
    func receive(request: Data, cache: inout Cache) throws -> Response {
        let request = try JSONDecoder.default.decode(Request.self, from: request)
        return try receive(request: request, cache: &cache)
    }
}

final class Server {
    struct Notification: Encodable {
        struct Params: Encodable {
            struct UpdatedOptions: Encodable {
                let options: [String]
                let workingDirectory: String
            }
            let uri: String
            let updatedOptions: UpdatedOptions
        }
        let jsonrpc: String = "2.0"
        let method: String
        let params: Params
    }

    func serve() {
        struct Request: Decodable {
            let method: String
            let id: Int?
        }

        struct ErrorResponse: BuildServerProtocolResponse {
            struct Error: Encodable {
                let code: Int = 123
                let message: String

                init(method: String) {
                    self.message = "unhandled method \(method)"
                }

                init(error: Swift.Error) {
                    self.message = "error: \(error)"
                }
            }
            let jsonrpc: String = "2.0"
            let id: Int?
            let error: Error
        }

        let stdin = FileHandle.standardInput
        var cache: Cache = .init()
        stdin.waitForDataInBackgroundAndNotify()
        stdin.readabilityHandler = { handle in
            do {
                let data = handle.availableData
                guard
                    !data.isEmpty,
                    let received = String(data: data, encoding: .utf8)?.split(separator: "\r\n", omittingEmptySubsequences: true),
                    received.count >= 2
                else {
                    return
                }
                let content = received[1].replacing("\\/", with: "/")
                Logger.debug("received", content)
                guard let raw = content.data(using: .utf8) else {
                    return
                }
                let request = try JSONDecoder.default.decode(Request.self, from: raw)
                let method = Server.Method(rawValue: request.method)
                if method == .build(.exit) {
                    exit(0)
                }
                let response: Encodable
                if let method {
                    do {
                        response = try method.handler.receive(request: raw, cache: &cache)
                    } catch {
                        response = ErrorResponse(id: request.id, error: .init(error: error))
                    }
                } else {
                    response = ErrorResponse(id: request.id, error: .init(method: request.method))
                }

                guard !(response is EmptyResponse) else {
                    return
                }
                send(response)
            } catch {
                Logger.error(error)
            }
        }
        RunLoop.current.run()
    }
}

extension Server.Notification.Params.UpdatedOptions {
    init?(uri: String, cache: inout Cache) throws {
        guard
            let xcodebuild = cache.xcodebuild,
            let indexStorePath = cache.indexStorePath
        else {
            return nil
        }

        var flags: [String]
        let uri = try AbsolutePath(erasingFileScheme: uri)
        if let _flags = cache.indexes.commandArguments(file: uri.pathString) {
            flags = _flags
        } else {
            let indexes = try BuildIndexes(indexes: xcodebuild.buildSettingsForIndex())
            cache.indexes = indexes
            guard let _flags = indexes.commandArguments(file: uri.pathString) else {
                return nil
            }
            flags = _flags
        }

        let workDir: String
        if let index = flags.firstIndex(of: "-working-directory"), flags.count < index + 1 {
            workDir = flags[index + 1]
        } else {
            workDir = URL.currentDirectory().path(percentEncoded: false)
        }

        if !flags.contains("-index-store-path") {
            flags.append(contentsOf: ["-index-store-path", indexStorePath.pathString])
        }
        self.init(options: flags, workingDirectory: workDir)
    }
}
