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
    let postgresqlConfig = PostgreSQLDatabaseConfig(hostname: "database.v2.vapor.cloud",
                                                  port: 30001,
                                                  username: "ua6fcc76295088de6229783f8a69dfb2",
                                                  database: "df7ea1b8ce2a9631",
                                                  password: "pac683f80f6dd8fda1a9af8a3120b22b")

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
