//
//  XcodeBuild.swift
//  
//
//  Created by Kazuki Yamamoto on 2023/05/04.
//

import Foundation
import TSCBasic

struct BuildSettingsForIndex: Decodable {
    enum LanguageDialect {
        case swift(Swift)
        case objectiveC(ObjectiveC)
        case other

        var commandArguments: [String]? {
            switch self {
            case .swift(let swift):
                return swift.swiftASTCommandArguments
            case .objectiveC(let objc):
                return objc.clangASTCommandArguments
            default:
                return []
            }
        }
    }

    struct Swift: Decodable {
        let outputFilePath: AbsolutePath
        let swiftASTBuiltProductsDir: AbsolutePath
        let swiftASTCommandArguments: [String]
        let swiftASTModuleName: String
        let toolchains: [String]
    }
    struct ObjectiveC: Decodable {
        let clangASTBuiltProductsDir: String
        let clangASTCommandArguments: [String]
        let clangPCHCommandArguments: [String]?
        let clangPCHFilePath: String?
        let clangPrefixFilePath: String?
        let outputFilePath: String
        let toolchains: [String]
    }
    enum CodingKeys: String, CodingKey {
        case outputFilePath, swiftASTBuiltProductsDir, swiftASTCommandArguments, swiftASTModuleName, toolchains
        case languageDialect = "LanguageDialect"
    }

    let languageDialect: String
    let language: LanguageDialect

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.languageDialect = try container.decode(String.self, forKey: .languageDialect)

        switch languageDialect {
        case "Xcode.SourceCodeLanguage.Swift":
            self.language = .swift(try Swift(from: decoder))
        case "Xcode.SourceCodeLanguage.Objective-C":
            self.language = .objectiveC(try ObjectiveC(from: decoder))
        default:
            self.language = .other
        }
    }
}

struct BuildSettings: Decodable {
    let action: String
    let target: String
    let buildSettings: [String: String]
}

struct ProjjectList: Decodable {
    struct Project: Decodable {
        let configurations: [String]
        let name: String
        let schemes: [String]
        let targets: [String]
    }

    let project: Project
}

struct WorkspaceList: Decodable {
    struct Workspace: Decodable {
        let name: String
        let schemes: [String]
    }

    let workspace: Workspace
}

struct DefaultXcodeBuildArguments {
    let workspace: String?
    let project: String?
    let target: String?
    let scheme: String?
    let configuration: String?

    init(
        workspace: String? = nil,
        project: String? = nil,
        target: String? = nil,
        scheme: String? = nil,
        configuration: String? = nil
    ) {
        self.workspace = workspace
        self.project = project
        self.target = target
        self.scheme = scheme
        self.configuration = configuration
    }

    var arguments: [String] {
        var arguments: [String] = []
        if let workspace {
            arguments.append(contentsOf: ["-workspace", workspace])
        }
        if let project {
            arguments.append(contentsOf: ["-project", project])
        }
        if let target {
            arguments.append(contentsOf: ["-target", target])
        }
        if let scheme {
            arguments.append(contentsOf: ["-scheme", scheme])
        }
        if let configuration {
            arguments.append(contentsOf: ["-configuration", configuration])
        }

        return arguments
    }
}

struct BuildArguments {
    let destination: String
    let defaultArguments: DefaultXcodeBuildArguments

    var arguments: [String] {
        defaultArguments.arguments + ["-destination", destination]
    }
}

extension XcodeBuild {
    enum Error: Swift.Error {
        case xcodebuildNotFound
    }
}

struct XcodeBuild {
    let xcodebuildPath: AbsolutePath

    init(projectRoot: AbsolutePath) throws {
        self.xcodebuildPath = try AbsolutePath(validating: "/usr/bin/xcodebuild")
        guard try Process.popen(args: xcodebuildPath.pathString, "-h").exitStatus == .terminated(code: 0) else {
            throw Error.xcodebuildNotFound
        }
        if localFileSystem.currentWorkingDirectory != projectRoot {
            try localFileSystem.changeCurrentWorkingDirectory(to: projectRoot)
        }
    }

    func buildSettingsForIndex(arguments: DefaultXcodeBuildArguments = .init()) throws -> [String: [String: BuildSettingsForIndex]] {
        return try xcodebuild(["-showBuildSettingsForIndex"] + arguments.arguments)
    }

    func buildSettings(arguments: DefaultXcodeBuildArguments = .init()) throws -> [BuildSettings] {
        return try xcodebuild(["-showBuildSettings"] + arguments.arguments)
    }

    func list(project: String? = nil) throws -> ProjjectList {
        var arguments = ["-list"]
        if let project {
            arguments.append(contentsOf: ["-project", project])
        }
        return try xcodebuild(["-list"])
    }

    func list(workspace: String) throws -> WorkspaceList {
        try xcodebuild(["-list", "-workspace", workspace])
    }

    func build(arguments: BuildArguments) throws {
        let data = try xcodebuild(arguments.arguments)
        Logger.debug("xcodebuild result:", String(data: data, encoding: .utf8))
    }
}

private extension XcodeBuild {
    func xcodebuild<Result: Decodable>(_ arguments: [String]) throws -> Result {
        let result = try xcodebuild(arguments + ["-json"])
        // -showBuildSettingsForIndex output is too large
        // ignore logging
        if !arguments.contains("-showBuildSettingsForIndex") {
            Logger.debug("xcodebuild result:", String(data: result, encoding: .utf8))
        }
        return try JSONDecoder.default.decode(Result.self, from: result)
    }

    @discardableResult
    func xcodebuild(_ arguments: [String]) throws -> Data {
        Logger.debug("xcodebiuld:", arguments)
        return try Data(Process.popen(arguments: [xcodebuildPath.pathString] + arguments).output.get())
    }
}
