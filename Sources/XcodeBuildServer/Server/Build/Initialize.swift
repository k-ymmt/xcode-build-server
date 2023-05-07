//
//  Initialize.swift
//  
//
//  Created by Kazuki Yamamoto on 2023/05/04.
//

import Foundation
import TSCBasic

extension Server {
    struct BuildInitialize: DispatchHandler {
        struct Request: BuildServerProtocolRequest {
            struct Params: Decodable {
                enum CodingKeys: String, CodingKey {
                    case rootURI = "rootUri"
                }
                let rootURI: String
            }

            let method: String
            let params: Params
            let id: Int
        }

        struct Response: BuildServerProtocolResponse {
            struct Result: Encodable {
                struct Capabilities: Encodable {
                    let languageIds: [String]
                }
                struct Data: Encodable {
                    let indexDatabasePath: String
                    let indexStorePath: String
                }
                let displayName: String = "xcode build server"
                let version: String = "0.1"
                let bspVersion: String = "2.0"
                let rootUri: String
                let capabilities: Capabilities = .init(languageIds: ["c", "cpp", "objective-c", "objective-cpp", "swift"])
                let data: Data
            }
            let jsonrpc: String = "2.0"
            let id: Int
            let result: Result
        }

        func receive(request: Request, cache: inout Cache) throws -> Response {
            struct Error: Swift.Error {
                let message: String
            }
            
            let rootURI = try AbsolutePath(erasingFileScheme: request.params.rootURI)
            let xcodebuild = try XcodeBuild(projectRoot: rootURI)

            let indexes = try BuildIndexes(
                indexes: xcodebuild.buildSettingsForIndex(arguments: defaultArguments(rootURI: rootURI, cache: &cache))
            )
            cache.indexes = indexes
            cache.xcodebuild = xcodebuild

            guard let cacheDirectory = localFileSystem.xcodeBuildServerCacheDirectory else {
                throw Error(message: "cannot find cache directory")
            }
            let cachePath = cacheDirectory.appending(
                component: rootURI.pathString.split(separator: "/").joined(separator: "-").replacing("%", with: "X")
            )

            let indexStorePath: AbsolutePath
            if let path = indexes.firstCommandArgument(name: "-index-store-path"),
               let _indexStorePath = try? AbsolutePath(validating: path) {
                indexStorePath = _indexStorePath
            } else {
                indexStorePath = cachePath.appending(component: "indexStorePath")
            }
            DispatchQueue.global().async { [cache] in
                Logger.debug("build start...")
                do {
                    try build(xcodebuild: xcodebuild, rootURI: rootURI, cache: cache)
                } catch {
                    Logger.error(error)
                }
            }
            cache.indexStorePath = indexStorePath

            return .init(
                id: request.id,
                result: .init(
                    rootUri: rootURI.pathString,
                    data: .init(
                        indexDatabasePath: cachePath.appending(component: "indexDatabasePath").pathString,
                        indexStorePath: indexStorePath.pathString
                    )
                )
            )
        }
    }
}

private func build(xcodebuild: XcodeBuild, rootURI: AbsolutePath, cache: Cache) throws {
    let config = cache.config

    guard let destination = config.destination else {
        return
    }

    let workspace = config.workspace
    let project = config.project
    let configuration = config.configuration
    let scheme = config.scheme
    try xcodebuild.build(
        arguments: .init(
            destination: destination,
            defaultArguments: .init(
                workspace: workspace,
                project: project,
                scheme: scheme,
                configuration: configuration
            )
        )
    )
}

private func defaultArguments(rootURI: AbsolutePath, cache: inout Cache) throws -> DefaultXcodeBuildArguments {
    let rootContents = try localFileSystem.getDirectoryContents(rootURI)
    let serverConfig: Config?

    if let serverConfigFileName = rootContents.first(where: { $0.hasSuffix("buildServer.json") }),
       let config = try? JSONDecoder.default.decode(Config.self, from: Data(contentsOf: rootURI.appending(component: serverConfigFileName).asURL)) {
        serverConfig = config
    } else {
        serverConfig = nil
    }

    var workspace: String?
    var project: String?

    if let _workspace = serverConfig?.workspace {
        workspace = _workspace
    } else if let _project = serverConfig?.project {
        project = _project
    } else if let workspaceName = rootContents.first(where: { $0.hasSuffix(".xcworkspace") }) {
        workspace = workspaceName
    } else if let projectName = rootContents.first(where: { $0.hasSuffix(".xcodeproj") }) {
        project = projectName
    }

    let scheme = serverConfig?.scheme

    let config = Config(
        project: project,
        workspace: workspace,
        scheme: scheme,
        configuration: serverConfig?.configuration ?? "Debug",
        destination: serverConfig?.destination ?? "generic/platform=iOS Simulator"
    )
    cache.config = config
    return .init(workspace: workspace, scheme: scheme)
}
