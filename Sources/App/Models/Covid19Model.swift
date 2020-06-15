import Fluent
import Vapor

final class Covid19Model: Model, Content {
    static let schema = "covid19"
    
    @ID(custom: .id) var id: Int?
    @Field(key: "reportingdate") var reportingDate: Date
    @Field(key: "day") var day: Int
    @Field(key: "month") var month: Int
    @Field(key: "year") var year: Int
    @Field(key: "cases") var cases: Double
    @Field(key: "deaths") var deaths: Double
    @Field(key: "country") var country: Int
    
    
    init() { }
    
    init(id: Int? = nil,
         reportingDate: Date,
         day: Int,
         month: Int,
         year: Int,
         cases : Double,
         deaths: Double,
         country: Int
    ) {
        self.reportingDate = reportingDate
        self.day = day
        self.month = month
        self.year = year
        self.cases = cases
        self.deaths = deaths
        self.country = country
    }
}

