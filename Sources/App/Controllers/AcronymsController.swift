import Vapor
import Fluent
import Authentication

struct AcronymsController: RouteCollection {
    func boot(router: Router) throws {
        let acronymsRoutes = router.grouped("api", "acronyms")
        
//        let basicAuthMiddleware = User.basicAuthMiddleware(using: BCryptDigest())
//        let guardAuthMiddleware = User.guardAuthMiddleware()
//        let protected = acronymsRoutes.grouped(basicAuthMiddleware, guardAuthMiddleware)
//        protected.post(Acronym.self, use: createHandler)
        
        let tokenAuthMiddleware = User.tokenAuthMiddleware()
        let guardAuthMiddleware = User.guardAuthMiddleware()
        let tokenAuthGroup = acronymsRoutes.grouped(tokenAuthMiddleware, guardAuthMiddleware)
        
        tokenAuthGroup.post(AcronymCreateData.self, use: createHandler)
    
        tokenAuthGroup.put(Acronym.parameter, use: updateHandler)
        tokenAuthGroup.delete(Acronym.parameter, use: deleteHandler)
        tokenAuthGroup.post(Acronym.parameter, "categories", Category.parameter, use:addCategoriesHandler)
        tokenAuthGroup.delete(Acronym.parameter, "categories", Category.parameter, use: removeCategoriesHandler)
        
        
        acronymsRoutes.get(use: getAllHandler)
        acronymsRoutes.get(Acronym.parameter, use: getHandler)
        acronymsRoutes.get("search", use: searchHandler)
        acronymsRoutes.get("first", use: getFirstHandler)
        acronymsRoutes.get("sorted", use: sortedHandler)
        acronymsRoutes.get(Acronym.parameter, "user", use: getUserHandler)
        acronymsRoutes.get(Acronym.parameter, "categories", use: getCategoriesHandler)

    }
    
    // all acronyms
    func getAllHandler(_ req: Request) throws -> Future<[Acronym]> {
        return Acronym.query(on: req).all()
    }
    
    // Add Acronym
//    func createHandler(_ req: Request) throws -> Future<Acronym> {
//        return try req .content .decode(Acronym.self) .flatMap(to: Acronym.self) { acronym in
//            return acronym.save(on: req)
//        }
//    }

    // Add Acronym 2.0
//    func createHandler(_ req: Request, acronym: Acronym) throws -> Future<Acronym> {
//        return acronym.save(on: req)
//    }

    // Add Acronym 3.0
    func createHandler(_ req: Request, data: AcronymCreateData) throws -> Future<Acronym> {
        let user = try req.requireAuthenticated(User.self)
        let acronym = try Acronym(short: data.short, long: data.long, userID: user.requireID())
        return acronym.save(on: req)
    }
    
     // single acronym
    func getHandler(_ req: Request) throws -> Future<Acronym> {
        return try req.parameters.next(Acronym.self)
    }

    // update acronym
//    func updateHandler(_ req: Request) throws -> Future<Acronym> {
//        return try flatMap(to: Acronym.self,
//                           req.parameters.next(Acronym.self),
//                           req.content.decode(Acronym.self) ) { acronym, updatedAcronym in
//                            acronym.short = updatedAcronym.short
//                            acronym.long = updatedAcronym.long
//                            return acronym.save(on: req)
//        }
//    }
    
// update 2.0
//    func updateHandler(_ req: Request) throws -> Future<Acronym> {
//        return try flatMap(to: Acronym.self,
//                           req.parameters.next(Acronym.self),
//                           req.content.decode(Acronym.self) ) { acronym, updatedAcronym in
//                            acronym.short = updatedAcronym.short
//                            acronym.long = updatedAcronym.long
//                            acronym.userID = updatedAcronym.userID
//                            return acronym.save(on: req)
//        }
//    }
    
 // update 3.0
    func updateHandler(_ req: Request) throws -> Future<Acronym> {

        return try flatMap(
            to: Acronym.self,
            req.parameters.next(Acronym.self),
            req.content.decode(AcronymCreateData.self)
        ) { acronym, updateData in
            acronym.short = updateData.short
            acronym.long = updateData.long
            
            let user = try req.requireAuthenticated(User.self)
            acronym.userID = try user.requireID()
            return acronym.save(on: req)
        }
    }
    
    

    // delete acronym
    func deleteHandler(_ req: Request) throws -> Future<HTTPStatus> {
        return try req.parameters.next(Acronym.self).delete(on: req).transform(to: .noContent)
    }

    // search acronyms
    func searchHandler(_ req: Request) throws -> Future<[Acronym]> {
        guard let searchTerm = req.query[String.self, at: "term"] else {
            throw Abort(.badRequest)
        }
        
        return Acronym.query(on: req).group(.or) { or in
            or.filter(\.short == searchTerm)
            or.filter(\.long == searchTerm)
        }.all()
    }
    
    // first acronym
    func getFirstHandler(_ req: Request) throws -> Future<Acronym> {
        return Acronym.query(on: req).first().unwrap(or: Abort(.notFound))
    }

    // sorted acronyms
    func sortedHandler(_ req: Request) throws -> Future<[Acronym]> {
        return Acronym.query(on: req).sort(\.short, .ascending).all()
    }

    func getUserHandler(_ req: Request) throws -> Future<User.Public> {
        return try req.parameters.next(Acronym.self).flatMap(to: User.Public.self) { acronym in
            acronym.user.get(on: req).convertToPublic()
        }
    }
    
    func addCategoriesHandler(_ req: Request) throws -> Future<HTTPStatus> {
        return try flatMap(to: HTTPStatus.self,
                           req.parameters.next(Acronym.self),
                           req.parameters.next(Category.self)) { acronym, category in
            return acronym.categories.attach(category, on: req).transform(to: .created)
        }
    }
    
    func getCategoriesHandler(_ req: Request) throws -> Future<[Category]> {
        return try req.parameters.next(Acronym.self).flatMap(to: [Category].self) { acronym in
            try acronym.categories.query(on: req).all()
        }
    }
    
    func removeCategoriesHandler(_ req: Request) throws -> Future<HTTPStatus> {
        return try flatMap(to: HTTPStatus.self, req.parameters.next(Acronym.self), req.parameters.next(Category.self)) { acronym, category  in
            return acronym.categories.detach(category, on: req).transform(to: .noContent)
        }
    }
}

struct AcronymCreateData: Content {
    let short: String
    let long: String
}
