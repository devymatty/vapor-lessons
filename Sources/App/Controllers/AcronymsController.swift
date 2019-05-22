import Vapor
import Fluent

struct AcronymsController: RouteCollection {
    func boot(router: Router) throws {
        let acronymsRoutes = router.grouped("api", "acronyms")
        
        acronymsRoutes.get(use: getAllHandler)
//        acronymsRoutes.post(use: createHandler)
        acronymsRoutes.post(Acronym.self, use: createHandler)
        acronymsRoutes.get(Acronym.parameter, use: getHandler)
        acronymsRoutes.put(Acronym.parameter, use: updateHandler)
        acronymsRoutes.delete(Acronym.parameter, use: deleteHandler)
        acronymsRoutes.get("search", use: searchHandler)
        acronymsRoutes.get("first", use: getFirstHandler)
        acronymsRoutes.get("sorter", use: sortedHandler)
        
        acronymsRoutes.get(Acronym.parameter, "user", use: getUserHandler)
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
    func createHandler(_ req: Request, acronym: Acronym) throws -> Future<Acronym> {
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
    func updateHandler(_ req: Request) throws -> Future<Acronym> {
        return try flatMap(to: Acronym.self,
                           req.parameters.next(Acronym.self),
                           req.content.decode(Acronym.self) ) { acronym, updatedAcronym in
                            acronym.short = updatedAcronym.short
                            acronym.long = updatedAcronym.long
                            acronym.userID = updatedAcronym.userID
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

    func getUserHandler(_ req: Request) throws -> Future<User> {
        return try req.parameters.next(Acronym.self).flatMap { acronym in
            acronym.user.get(on: req)
        }
    }
    
}
