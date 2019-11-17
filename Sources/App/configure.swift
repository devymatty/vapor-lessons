import FluentPostgreSQL
import Vapor
import Leaf
import Authentication

/// Called before your application initializes.
public func configure(_ config: inout Config, _ env: inout Environment, _ services: inout Services) throws {
    // Register providers first
    try services.register(FluentPostgreSQLProvider())
    try services.register(LeafProvider())
    try services.register(AuthenticationProvider())

    // Register routes to the router
    let router = EngineRouter.default()
    try routes(router)
    services.register(router, as: Router.self)

    // Use Leaf for rendering views
    config.prefer(LeafRenderer.self, for: ViewRenderer.self)
    
    // Register middleware
    var middlewares = MiddlewareConfig() // Create _empty_ middleware config
    middlewares.use(FileMiddleware.self) // Serves files from `Public/` directory
    middlewares.use(ErrorMiddleware.self) // Catches errors and converts to HTTP response
    middlewares.use(SessionsMiddleware.self)
    services.register(middlewares)
    
    // Configure a database
    var databases = DatabasesConfig()
    let hostname: String
    let databaseName: String
    let databasePort: Int
    let databaseUsername: String
    let databasePassword: String
    let transportConfig: PostgreSQLConnection.TransportConfig
    
    let tls = TLSConfiguration.forClient(certificateVerification: .none)
    
    if (env == .testing) {
        hostname = Environment.get("DATABASE_HOSTNAME") ?? "localhost"
        databaseName = "vapor-test"
        databaseUsername = "vapor"
        databasePassword = "password"
        transportConfig = .cleartext
        if let testPort = Environment.get("DATABASE_PORT") {
            databasePort = Int(testPort) ?? 5433
        } else {
            databasePort = 5433
        }
    } else {
        hostname = "rc1a-h5aqlve8skbpj6es.mdb.yandexcloud.net"
        databaseName = "server-side-swift-with-vapor"
        databasePort = 6432
        databaseUsername = "user_admin"
        databasePassword = "1q2w3e4r"
        transportConfig = .customTLS(tls) //.unverifiedTLS
    }
    
    let databaseConfig = PostgreSQLDatabaseConfig(
        hostname: hostname,
        port: databasePort,
        username: databaseUsername,
        database: databaseName,
        password: databasePassword,
        transport: transportConfig)
    
    let database = PostgreSQLDatabase(config: databaseConfig)
    databases.add(database: database, as: .psql)
    services.register(databases)
    
    // Configure migrations
    var migrations = MigrationConfig()
    migrations.add(model: User.self, database: .psql)
    migrations.add(model: Acronym.self, database: .psql)
    migrations.add(model: Category.self, database: .psql)
    migrations.add(model: AcronymCategoryPivot.self, database: .psql)
    migrations.add(model: Token.self, database: .psql)
    migrations.add(migration: AdminUser.self, database: .psql)
    services.register(migrations)
    
    var commandConfig = CommandConfig.default()
    commandConfig.useFluentCommands()
    services.register(commandConfig)
    
    
    config.prefer(MemoryKeyedCache.self, for: KeyedCache.self)
}
