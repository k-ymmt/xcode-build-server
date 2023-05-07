//
//  Initialized.swift
//  
//
//  Created by Kazuki Yamamoto on 2023/05/04.
//

import Foundation

extension Server {
    struct BuildInitialized: DispatchHandler {
        func receive(request: EmptyRequest, cache: inout Cache) -> EmptyResponse {
            .init()
        }
    }
}
