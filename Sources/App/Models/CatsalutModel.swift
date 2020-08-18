import Fluent
import Vapor

final class CatsalutModel: Model, Content {
    static let schema = "catsalut"
    
    @ID(custom: .id) var id: Int?
    @Field(key: "data") var reportingDate: Date
    @Field(key: "codi_comarca") var country: Int
    @Field(key: "descripcio_comarca") var comarca: String
    @Field(key: "casos") var cases: Double
    //var deaths: Double = 0.0

    
    init() { }
    
    init(id: Int? = nil,
         reportingDate: Date,
         country: Int,
         comarca: String,
         cases: Double
    ) {
        self.reportingDate = reportingDate
        self.country = country
        self.comarca = comarca
        self.cases = cases
        //self.deaths = 0.0

    }
    
    init(grouped : GroupedCatsalutModel, codiComarca: Int, descComarca : String){
        
        self.id = -1
        self.reportingDate = grouped.data
        self.country = codiComarca
        self.comarca = descComarca
        self.cases = grouped.casos
        
        
        
    }
}

final class GroupedCatsalutModel : Content {
    
    static let schema = "catsalut"
    
    var data: Date
    var casos: Double
    //var deaths: Double = 0.0

     
    init(
         data: Date,
         casos: Double
    ) {
        self.data = data
        self.casos = casos
        //self.deaths = 0.0

    }

    
    
    
    
}

