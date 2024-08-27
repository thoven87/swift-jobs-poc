
import Hummingbird
import HummingbirdPostgres
import HummingbirdRouter
import Jobs
import JobsPostgres
import Logging
import Metrics
import NIOPosix
import NIOCore
import PostgresNIO

protocol SwiftJobsServiceArguments {
    var hostname: String { get }
    var logLevel: Logger.Level { get }
    var port: Int { get }
}
let SERVICENAME = "SwiftJobsPostgres"


struct AppContext: RouterRequestContext, RequestContext {
    var coreContext: CoreRequestContextStorage
    
    var routerContext: RouterBuilderContext
    
    let channel: Channel?
    
    /// Connected host address
    var remoteAddress: SocketAddress? {
        guard let channel else { return nil }
        return channel.remoteAddress
    }
    
    init(source: Source) {
        self.coreContext = .init(source: source)
        self.routerContext = .init()
        self.channel = source.channel
    }
}

func buildApplication(
    _ arguments: some SwiftJobsServiceArguments
) async throws -> some ApplicationProtocol {
    let env = try await Environment().merging(with: .dotEnv(".env.local"))
    
    let logger = {
        var logger = Logger(label: SERVICENAME)
        logger.logLevel = .debug//arguments.logLevel
        return logger
    }()

    
    
    let postgressConfig = PostgresClient.Configuration(
        host: env.get("POSTGRES_HOST") ?? "localhost",
        port: env.get("POSTGRES_PORT", as: Int.self) ?? 5432,
        username: env.get("POSTGRES_USERNAME") ?? "swift_jobs",
        password: env.get("POSTGRES_PASSWORD") ?? "swift_jobs",
        database: env.get("POSTGRES_DATABASE") ?? "swift_jobs",
        tls: .prefer(.clientDefault))
    
    let postgresClient = PostgresClient(
        configuration: postgressConfig,
        backgroundLogger: logger)
    
    let postgresMigrations = PostgresMigrations()
    
    let jobQueueService = await JobQueue(
        .postgres(
            client: postgresClient,
            migrations: postgresMigrations,
            logger: logger),
        numWorkers: env.get("JOB_QUEUE_WORKERS", as: Int.self) ?? 4,
        logger: logger)
    
    var jobScheduleService = JobSchedule()
    jobScheduleService.addJob(
        ScheduledJobController.StatsParameters(count: 20),
        schedule: .everyMinute()
    )

    
    _ = ScheduledJobController(queue: jobQueueService, statsService: .init(), logger: logger)
    
    let router = RouterBuilder(context: AppContext.self) {
        Get("/health") { _, _ -> HTTPResponse.Status in
                .ok
        }
    }
    
    var app = Application(
        router: router,
        configuration: .init(
            address: .hostname(arguments.hostname, port: arguments.port),
            serverName: SERVICENAME),
        logger: logger)
    
    app.logger.logLevel = arguments.logLevel
    
    await app.addServices(
        postgresClient, jobQueueService,
        jobScheduleService.scheduler(on: jobQueueService))
    
    app.beforeServerStarts {
        try await postgresMigrations.apply(client: postgresClient, logger: logger, dryRun: false)
    }
    
    return app
}
