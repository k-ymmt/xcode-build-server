//
//  BuildIndexes.swift
//  
//
//  Created by Kazuki Yamamoto on 2023/05/07.
//

import Foundation

struct BuildIndexes {
    let indexes: [String: [String: BuildSettingsForIndex]]

    init(indexes: [String: [String: BuildSettingsForIndex]] = [:]) {
        self.indexes = indexes
    }

    func find(file: String, of target: String? = nil) -> BuildSettingsForIndex? {
        if let target {
            return indexes[target]?[file]
        }

        for (_, value) in indexes {
            guard let findFile = value[file] else {
                continue
            }
            return findFile
        }
        return nil
    }

    func commandArguments(file: String, of target: String? = nil) -> [String]? {
        find(file: file, of: target)?.language.commandArguments
    }

    func firstCommandArgument(name: String, in file: String? = nil, of target: String? = nil) -> String? {
        func commandValue(name: String, arguments: [String]) -> String? {
            guard
                let index = arguments.firstIndex(of: name),
                index + 1 < arguments.count
            else {
                return nil
            }

            return arguments[index + 1]
        }

        if let file {
            guard let arguments = commandArguments(file: file, of: target) else {
                return nil
            }
            return commandValue(name: name, arguments: arguments)
        }

        if let target {
            guard let index = indexes[target] else {
                return nil
            }

            for (_, value) in index {
                guard
                    let arguments = value.language.commandArguments,
                    let value = commandValue(name: name, arguments: arguments)
                else {
                    continue
                }

                return value
            }
            return nil
        }

        for (_, value) in indexes {
            for (_, value) in value {
                guard
                    let arguments = value.language.commandArguments,
                    let value = commandValue(name: name, arguments: arguments)
                else {
                    continue
                }

                return value
            }
        }

        return nil
    }
}
