//
//  Method.swift
//  
//
//  Created by Kazuki Yamamoto on 2023/05/04.
//

import Foundation

extension Server {
    enum Method: Equatable {
        enum Build: String {
            case initialize
            case initialized
            case shutdown
            case exit

            var handler: any DispatchHandler {
                switch self {
                case .initialize:
                    return BuildInitialize()
                case .initialized:
                    return BuildInitialized()
                case .shutdown:
                    return BuildShutdown()
                case .exit:
                    return BuildExit()
                }
            }
        }
        enum Workspace: String {
            case buildTargets

            var handler: any DispatchHandler {
                switch self {
                case .buildTargets:
                    return WorkspaceBuildTargets()
                }
            }
        }
        enum BuildTarget: String {
            case sources

            var handler: any DispatchHandler {
                switch self {
                case .sources:
                    return BuildTargetSources()
                }
            }
        }
        enum TextDocument: String {
            case registerForChanges
            case sourceKitOptions

            var handler: any DispatchHandler {
                switch self {
                case .registerForChanges:
                    return TextDocumentRegisterForChanges()
                case .sourceKitOptions:
                    return TextDocumentSourceKitOptions()
                }
            }
        }

        case build(Build)
        case workspace(Workspace)
        case buildTarget(BuildTarget)
        case textDocument(TextDocument)

        init?(rawValue: String) {
            let path = rawValue.split(separator: "/").map(String.init)
            guard path.count >= 2 else {
                return nil
            }

            switch path[0] {
            case "build":
                guard let build = Build(rawValue: path[1]) else {
                    return nil
                }
                self = .build(build)
            case "workspace":
                guard let workspace = Workspace(rawValue: path[1]) else {
                    return nil
                }
                self = .workspace(workspace)
            case "buildTarget":
                guard let buildTarget = BuildTarget(rawValue: path[1]) else {
                    return nil
                }
                self = .buildTarget(buildTarget)
            case "textDocument":
                guard let textDocument = TextDocument(rawValue: path[1]) else {
                    return nil
                }
                self = .textDocument(textDocument)
            default:
                return nil
            }
        }

        var handler: any DispatchHandler {
            switch self {
            case .build(let build):
                return build.handler
            case .workspace(let workspace):
                return workspace.handler
            case .buildTarget(let buildTarget):
                return buildTarget.handler
            case .textDocument(let textDocument):
                return textDocument.handler
            }
        }
    }
}
