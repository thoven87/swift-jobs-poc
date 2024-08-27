//
//  StatsService.swift
//  swift-jobs-postgres
//
//  Created by Stevenson Michel on 8/27/24.
//
import Logging

final actor StatsService: Sendable {
    var counter: Int = 0
    let logger: Logger = .init(label: "StatsService")
    
    func increment() {
        counter += 1
        logger.info("Counter: \(counter)")
    }
}
