import Foundation
import Kitura
import LoggerAPI
import Configuration
import CloudEnvironment
import KituraContracts
import Health
import SwiftKueryORM
import SwiftKueryPostgreSQL

public let projectPath = ConfigurationManager.BasePath.project.path
public let health = Health()

extension User: Model {
    static var idColumnName = "userId"
}

class Persistence {
    static func setUp() {
        let pool = PostgreSQLConnection.createPool(host: "localhost", port: 5432, options: [.databaseName("KituraMicroservices"), .userName("postgres")], poolOptions: ConnectionPoolOptions(initialCapacity: 10, maxCapacity: 50, timeout: 10000))
        Database.default = Database(pool)
    }
}

let getUserFromDB: RouterHandler = { request, response, next in
    guard let userId = request.parameters["userId"] else {
        next()
        return
    }
    User.find(id: userId) { result, error in
        if let user = result {
            response.headers["Content-Type"] = "application/json"
            response.send(user).status(.OK)
        }
    }
}

let updateUserSteps: RouterHandler = { request, response, next in
    guard let userId = request.parameters["userId"] else {
        next()
        return
    }
    guard let jsonBody = request.body?.asJSON else {
        next()
        return
    }
    guard let newSteps = jsonBody["steps"] as? Int else {
        next()
        return
    }
    User.find(id: userId) { result, error in
        if let user = result {
            var currentUser = user
            currentUser.steps = newSteps
            currentUser.update(id: userId) { user, error in
                response.headers["Content-Type"] = "application/json"
                response.send(UserCompact(user!)).status(.OK)
            }
        }
    }
}

public class App {
    let router = Router()
    let cloudEnv = CloudEnv()

    public init() throws {
        // Run the metrics initializer
        initializeMetrics(router: router)
    }

    func postInit() throws {
        // Endpoints
        initializeHealthRoutes(app: self)
        router.get("/users/generate", handler: generateNewAvatar)
        router.post("/users", handler: registerNewUser)
        router.get("/users/complete", handler: getUsersFromDB)
        router.get("/users", handler: getUsersCompact)
        router.get("/users/:userId", handler: getUserFromDB)
        router.put("/users/:userId", middleware: BodyParser())
        router.put("/users/:userId", handler: updateUserSteps)
        
        // set up the database
        Persistence.setUp()
        do {
            try User.createTableSync()
        } catch let error {
            print(error)
        }
    }
    
    func generateNewAvatar(completion: @escaping (AvatarGenerated?, RequestError?) -> Void) {
        let urlString = "http://avatar-rainbow.mybluemix.net/new"
        guard let url = URL(string: urlString) else {
            print("url error")
            return
        }
        
        URLSession.shared.dataTask(with: url) { (data, response, error) in
            if error != nil {
                print(error!.localizedDescription)
                print("No connection")
            }
            
            guard let data = data else { return }
            
            do {
                let avatar = try JSONDecoder().decode(AvatarGenerated.self, from: data)
                completion(avatar, nil)
            } catch let jsonError {
                print(jsonError)
            }
        }.resume()
    }
    
    func registerNewUser(avatar: AvatarGenerated, completion: @escaping (User?, RequestError?) -> Void) {
        let imageData = Data(base64Encoded: avatar.image, options: .ignoreUnknownCharacters)
        let user = User(userId: UUID.init().uuidString, name: avatar.name, image: imageData!, steps: 0, stepsConvertedToFitcoin: 0, fitcoin: 0)
        
        user?.save { user, error in
            completion(user, error)
        }
    }
    
    func getUsersFromDB(completion: @escaping ([User]?, RequestError?) -> Void) {
        User.findAll(completion)
    }
    
    func getUsersCompact(completion: @escaping ([UserCompact]?, RequestError?) -> Void) {
        var users: [UserCompact] = []
        User.findAll { (result: [User]?, error: RequestError?) in
            for user in result! {
                users.append(UserCompact(user))
            }
            completion(users, error)
        }
    }

    public func run() throws {
        try postInit()
        Kitura.addHTTPServer(onPort: cloudEnv.port, with: router)
        Kitura.run()
    }
}
