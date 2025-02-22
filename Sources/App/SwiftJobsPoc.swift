import Hummingbird
import HummingbirdPostgres
import HummingbirdRouter
import Jobs
import JobsPostgres
import Logging
import Metrics
import NIOCore
import NIOPosix
import PostgresMigrations
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
        logger.logLevel = .debug
        return logger
    }()

    let postgresConfig =
        if env.get("APP_ENV") == "production" {
            PostgresClient.Configuration(
                unixSocketPath: env.get("INSTANCE_UNIX_SOCKET") ?? "",
                username: env.get("POSTGRES_USERNAME") ?? "",
                password: env.get("POSTGRES_PASSWORD"),
                database: env.get("POSTGRES_DATABASE")
            )
        } else {
            PostgresClient.Configuration(
                host: env.get("POSTGRES_HOST") ?? "localhost",
                port: env.get("POSTGRES_PORT", as: Int.self) ?? 5432,
                username: env.get("POSTGRES_USERNAME") ?? "swift_jobs",
                password: env.get("POSTGRES_PASSWORD") ?? "swift_jobs",
                database: env.get("POSTGRES_DATABASE") ?? "swift_jobs",
                tls: .prefer(.clientDefault)
            )
        }

    let postgresClient = PostgresClient(
        configuration: postgresConfig,
        backgroundLogger: logger
    )

    let postgresMigrations = DatabaseMigrations()

    let jobQueueService = await JobQueue(
        .postgres(
            client: postgresClient,
            migrations: postgresMigrations,
            logger: logger
        ),
        numWorkers: env.get("JOB_QUEUE_WORKERS", as: Int.self) ?? 20,
        logger: logger
    )

    var jobScheduleService = JobSchedule()
    
    jobScheduleService.addJob(
        ScheduledJobController.StatsParameters(count: 20),
        schedule: .everyMinute()
    )
    
    jobScheduleService.addJob(
        BBCNewsIngestionJobParameters(),
        schedule: .onMinutes([0, 5, 10, 15, 20, 25, 30, 35, 40, 45, 50, 55])
    )
    
    jobScheduleService.addJob(
        BloombergNewsIngestionJobParameters(),
        schedule: .onMinutes([0, 5, 10, 15, 20, 25, 30, 35, 40, 45, 50, 55])
    )

    _ = ScheduledJobController(queue: jobQueueService, statsService: .init(), newsService: NewsService(), logger: logger)

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
        logger: logger
    )

    app.logger.logLevel = arguments.logLevel

    await app.addServices(
        postgresClient, jobQueueService,
        jobScheduleService.scheduler(on: jobQueueService)
    )

    app.beforeServerStarts {
        try await postgresMigrations.apply(client: postgresClient, logger: logger, dryRun: false)
    }

    return app
}
