import Fluent
import Vapor

final class VDeathsNYTModel: Model, Content {
    static let schema = "v_deaths_nyt"
    
    @ID(custom: .id) var id: Int?
    @Field(key: "center_date") var reportingDate: Date
    @Field(key: "week") var week: Int?
    @Field(key: "month") var month: Int
    @Field(key: "year") var year: Int
    @Field(key: "expected_deaths") var expectedDeaths: Double
    @Field(key: "deaths") var deaths: Double
    @Field(key: "excess_deaths") var excessDeaths: Double
    @Field(key: "country") var country: Int
    @Field(key: "frequency") var frequency: String
    @Field(key: "placename") var placename: String?

    
    
    init() { }
    
    init(id: Int? = nil,
         reportingDate: Date,
         week: Int?,
         month: Int,
         year: Int,
         expectedDeaths : Double,
         deaths: Double,
         excessDeaths: Double,
         country: Int,
         frequency : String,
         placename : String?
    ) {
        self.reportingDate = reportingDate
        self.week = week
        self.month = month
        self.year = year
        self.expectedDeaths = expectedDeaths
        self.deaths = deaths
        self.excessDeaths = excessDeaths
        self.country = country
        self.frequency = frequency
        self.placename = placename
    }
}

