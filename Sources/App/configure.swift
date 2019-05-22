import FluentPostgreSQL
import Vapor

/// Called before your application initializes.
public func configure(_ config: inout Config, _ env: inout Environment, _ services: inout Services) throws {
    // Register providers first
    try services.register(FluentPostgreSQLProvider())

    // Register routes to the router
    let router = EngineRouter.default()
    try routes(router)
    services.register(router, as: Router.self)

    // Register middleware
    var middlewares = MiddlewareConfig() // Create _empty_ middleware config
    // middlewares.use(FileMiddleware.self) // Serves files from `Public/` directory
    middlewares.use(ErrorMiddleware.self) // Catches errors and converts to HTTP response
    services.register(middlewares)
    
    // Configure a database
    let postgresqlConfig = PostgreSQLDatabaseConfig(hostname: "rc1a-av0q6o9infcnetau.mdb.yandexcloud.net",
                                                  port: 6432,
                                                  username: "user1",
                                                  database: "vapor-2",
                                                  password: "12345678",
                                                  transport: .unverifiedTLS)
    
    let postgresql = PostgreSQLDatabase(config: postgresqlConfig)

    // Register the configured database to the database config.
    var databases = DatabasesConfig()
    databases.add(database: postgresql, as: .psql)
    services.register(databases)
    
    // Configure migrations
    var migrations = MigrationConfig()
    migrations.add(model: User.self, database: .psql)
    migrations.add(model: Acronym.self, database: .psql)
    migrations.add(model: Category.self, database: .psql)
    services.register(migrations)
}
