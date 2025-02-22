//
//  NewsService.swift
//  swift-jobs-poc
//
//  Created by Stevenson Michel on 2/22/25.
//

import Logging

struct NewsService {
    private let logger: Logger = Logger(label: "com.example.swift-jobs-poc.NewsService")
    
    func fetchNews() -> [String] {
        logger.info("Fetching news...")
        return ["News 1", "News 2", "News 3"]
    }
    
    func perfom(_ input: NewsIngestionJobParameters) {
        switch input.kind {
            case .bbc:
                logger.info("Processing BBC news...")
            case .techCrunch:
                logger.info("Processing TechCrunch news...")
            case .bloomberg:
                logger.info("Processing Bloomberg news...")
        }
    }
}
