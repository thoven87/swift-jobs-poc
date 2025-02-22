//
//  JobsParameters.swift
//  swift-jobs-poc
//
//  Created by Stevenson Michel on 10/22/24.
//

import Jobs

enum StationKind: Codable {
    case bbc
    case bloomberg
    case techCrunch
}

protocol NewsIngestionJobParameters: Codable, Sendable {
    var kind: StationKind { get set }
}

struct BBCNewsIngestionJobParameters: JobParameters, NewsIngestionJobParameters {
    static let jobName: String = "BBCNewsIngestionJob"
    var kind: StationKind = .bbc
}

struct BloombergNewsIngestionJobParameters: JobParameters, NewsIngestionJobParameters {
    static let jobName: String = "BloombergNewsIngestionJob"
    var kind: StationKind = .bloomberg
}

struct BirthdayRemindersJobParameters: JobParameters {
    static let jobName: String = "BirthdayRemindersJob"
}

struct WeeklyDigestJobParameters: JobParameters {
    static let jobName: String = "WeeklyDigestJob"
}

struct ActivityRemindersJobParameters: JobParameters {
    static let jobName: String = "ActivityRemindersJob"
}
