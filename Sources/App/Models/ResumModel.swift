import Fluent
import Vapor

final class ResumModel: Model, Content {
    static let schema = "resum"
    
    @ID(custom: .id) var id: Int?
    @Field(key: "geoid") var geoid: String
    @Field(key: "description") var description: String
    @Field(key: "population") var population: Double
    @Field(key: "cases") var cases: Double
    @Field(key: "deaths") var deaths: Double

    init() { }

    init(id: Int? = nil,
         geoid: String,
         description: String,
         population : Double,
         cases : Double,
         deaths: Double
         ) {
        self.id = id
        self.geoid = geoid
        self.description = description
        self.population = population
        self.cases = cases
        self.deaths = deaths
    }
}

