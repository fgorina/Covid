import Fluent
import Vapor

final class ComarquesModel: Model, Content {
    static let schema = "comarques"
    
    @ID(custom: .id) var id: Int?
    @Field(key: "nom") var description: String
    @Field(key: "poblacio") var population: Double?


    init() { }

    init(id: Int? = nil,
         description: String,
         population : Double?
         ) {
        self.id = id
         self.description = description
        self.population = population

    }
}

