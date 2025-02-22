// The Swift Programming Language
// https://docs.swift.org/swift-book

import ArgumentParser
import Hummingbird
import Logging

@main
struct ServerCommand: AsyncParsableCommand, SwiftJobsServiceArguments {
    @Option(name: .shortAndLong)
    var logLevel: Logger.Level = .info
    
    @Option(name: .shortAndLong)
    var hostname: String = "127.0.0.1"
    
    @Option(name: .shortAndLong)
    var port: Int = 8080
    
    @Flag(name: .shortAndLong)
    var migrate: Bool = false
    
    func run() async throws {
        let app = try await buildApplication(self)
        try await app.runService()
    }
}

/// Extend `Logger.Level` so it can be used as an argument
#if compiler(>=6.0)
extension Logger.Level: @retroactive ExpressibleByArgument {}
#else
extension Logger.Level: ExpressibleByArgument {}
#endif
