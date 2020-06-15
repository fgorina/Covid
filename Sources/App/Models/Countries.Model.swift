import Fluent
import Vapor

final class CountriesModel: Model, Content {
    static let schema = "countries"
    
    @ID(custom: .id) var id: Int?
    @Field(key: "geoid") var geoid: String
    @Field(key: "countrycode") var countryCode: String?
    @Field(key: "description") var description: String
    @Field(key: "population") var population: Double?
    @Field(key: "continent") var continent: Int

    init() { }

    init(id: Int? = nil,
         geoid: String,
         countryCode: String?,
         description: String,
         population : Double?,
         continent : Int
         ) {
        self.id = id
        self.geoid = geoid
        self.countryCode = countryCode
        self.description = description
        self.population = population
        self.continent = continent

    }
}

