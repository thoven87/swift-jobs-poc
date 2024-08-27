//
//  ScheduledJobController.swift
//  swift-jobs-postgres
//
//  Created by Stevenson Michel on 8/27/24.
//

import Jobs
import Logging

struct ScheduledJobController {
    struct StatsParameters: JobParameters {
        static let jobName: String = "scheduled-jobs"
        let count: Int
    }
    
    init(queue: borrowing JobQueue<some JobQueueDriver>, statsService: StatsService, logger: Logger) {
        queue.registerJob(
            parameters: StatsParameters.self,
            maxRetryCount: 10)
        { (parameters: StatsParameters, _) in
            await statsService.increment()
        }
    }
}
