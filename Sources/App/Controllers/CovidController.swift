import Fluent
import Vapor
import Leaf

struct CovidController: RouteCollection {
    
    struct TempoData : Content {
        
        var geoid : String?
        var from : String?
        var to : String?
        var acumulat : Bool
        var filter : String?
    }
    
    struct ResumContent : Content {
        var list : [ResumModel]
    }
    
    struct CountryId : Content {
        var geoId : String
        var descripcio : String
    }
    
    struct DetailContent : Content {
        var geoid : String
        var descripcio : String
        var list : [Covid19Model]
        var adjusted : [Double]
        var alfa : Double
        var beta : Double
        var countries : [CountryId]
        var forecast : [Double]
        var alfaForecast: Double
        var betaForecast: Double
        var movingBeta : [Double?]
        var adjustEnd : [Double?]           // 10 últims dies
    }
    
    func boot(routes: RoutesBuilder) throws {
        let covid = routes.grouped("covid")
        covid.get(use: index)
        covid.get("resum", use: self.resum)
        covid.post("tempo",  use: self.tempo)
        //covid.get("detail", ":geoid", use: self.detail)
        covid.get("detail", use: self.detail)
        
    }
    
    func index(req: Request) throws -> EventLoopFuture<View> {
        return req.view.render("chart")
    }
    
    func detail(req: Request) -> EventLoopFuture<View>{
        return CountriesModel.query(on: req.db)
            .filter(\.$population > 1000000.0)
            .sort(\.$description)
            .all()
            .flatMap{ countries in
                
                
                let codedCountries : [CountryId] = countries.reduce([]){
                    var aux = $0
                    aux.append(CountryId(geoId: $1.geoid, descripcio: $1.description.replacingOccurrences(of: "_", with: " ")))
                    return aux
                }
                
                return req.view.render("detail", DetailContent(geoid: codedCountries[0].geoId  , descripcio: codedCountries[0].descripcio.replacingOccurrences(of: "_", with: " "), list: [], adjusted: [], alfa: 0.0, beta:0.0, countries: codedCountries, forecast: [], alfaForecast: 0.0, betaForecast: 0.0, movingBeta: [],adjustEnd: []))
        }
    }
    
    
    
    func resum(req: Request) -> EventLoopFuture<ResumContent> {
        
        ResumModel.query(on: req.db)
            .filter(\.$population > 1000000.0)
            .sort(\.$cases, .descending)
            .all()
            .flatMap{ countries in
                
                for country in countries {
                    country.description = country.description.replacingOccurrences(of: "_", with: " ")
                }
                
                let co = countries.sorted { (c1, c2) -> Bool in
                    (c1.deaths/c1.population) > (c2.deaths / c2.population)
                }
                
                return req.eventLoop.makeSucceededFuture(ResumContent(list: co))
        }
    }
    
    func tempo(req: Request )-> EventLoopFuture<DetailContent> {
        
        guard let data = try? req.content.decode(TempoData.self)
            else {
                return req.eventLoop.makeFailedFuture(Abort(.badRequest))
        }
        guard let geoId = data.geoid else {
            return req.eventLoop.makeFailedFuture(Abort(.badRequest))
        }
        
        let from = Date.from(string: data.from ?? "") ?? Date.from(string: "01/01/20")!
        let to = Date.from(string: data.to ?? "") ?? Date()
        
        
        var filter = 0
        
        if let fil = data.filter{
            if let file = Int(fil){
                filter = Int(file)
            }
           
        }
        
        filter = max(filter, 0)
        filter = min(filter, 8)
        
        return CountriesModel.query(on: req.db)
            .filter(\.$geoid == geoId)
            .first()
            .unwrap(or: Abort(.notFound))
            .flatMap{ country in
                
                return Covid19Model.query(on: req.db)
                    .filter(\.$country == country.id!)
                    .filter(\.$reportingDate >= from)
                    .filter(\.$reportingDate <= to)
                    .filter(\.$cases >= 0.0)
                    .filter(\.$cases >= 0.0)
                    .sort(\.$year)
                    .sort(\.$month)
                    .sort(\.$day)
                    .all()
                    .flatMap{ records in
                        
                        // Removing < 0 values
                        
                        
                        
                        
                        // filtering (computes moving average)
                        if filter > 0 {
                            for i in 0..<records.count {
                            
                                if !(i < filter || i >= (records.count - filter)){

                                    var cases = 0.0
                                    var deaths = 0.0
                                    for j in i-filter..<i+filter {
                                        cases += records[j].cases
                                        deaths += records[j].deaths
                                    }
                                    
                                    records[i].cases = cases / ((2.0 * Double(filter)) + 1.0)
                                    records[i].deaths = deaths / ((2.0 * Double(filter))  + 1.0)

                                }
                            }
                        }
                        
                        var iMax = 0
                        var i400 = 0
                        
                        var i = 0
                        
                        let maximum = records.reduce(0.0){
                            if $1.cases > $0 {
                                iMax = i
                            }
                            
                            if $1.cases > 400.0 && i400 == 0{
                                i400 = i
                            }
                            i += 1
                            return max($0, $1.cases)
                        }
                          
                        if data.acumulat {
                            
                            var acumCases = 0.0
                            var acumDeaths = 0.0
                            
                            for record in records {
                                acumCases += record.cases
                                acumDeaths += record.deaths
                                
                                record.cases = acumCases
                                record.deaths = acumDeaths
                            }
                        }
                        let adjustableRecords : [Covid19Model] = Array(records[0..<iMax])
                        var (alfa, beta) = self.regression(adjustableRecords)
                        
                        var adjusted : [Double] = []
                        if records.count > 0{
                            for i in 1...records.count {
                                let fi = Double(i-1)
                                let v  = alfa * exp(beta * fi)
                                adjusted.append(v)
                            }
                        }
                        
                        let gouvRecords : [Covid19Model] = Array(records[0..<i400])
                        var (alfaForecast, betaForecast) = self.regression(gouvRecords)
                        
                        var forecast : [Double] = []
                        if records.count > 0{
                            for i in 1...records.count {
                                let fi = Double(i)
                                let v  = alfaForecast * exp(betaForecast * fi)
                                forecast.append(v)
                                
                            }
                            
                        }
                        
                        
                        if alfaForecast.isNaN {
                            alfaForecast = 0.0
                            forecast = []
                        }
                        
                        if betaForecast.isNaN {
                            betaForecast = 0.0
                            forecast = []
                        }
                        
                        if alfa.isNaN {
                            alfa = 0.0
                            adjusted = []
                        }
                        
                        if beta.isNaN {
                            beta = 0.0
                            adjusted = []
                        }
                        
                        
                        // Compute beta moving values
                        
                        let delta = 4
                        
                        var movingBeta : [Double?] = []
                        
                        var counter = 0
                        
                        for ix in 0..<records.count {
                            
                            if records[ix].cases >= 1.0 {
                                counter += 1
                            }
                            
                            if (ix < delta || ix > records.count - delta) || counter < delta {
                                movingBeta.append(nil)
                            } else {
                                
                                var (_, mbeta) = self.regression(Array(records[(ix-delta)..<(ix+delta)]))
                                
                                if mbeta.isNaN {
                                    movingBeta.append(nil)
                                }else {
                                    movingBeta.append(mbeta)
                                }
                            }
                        }
                        
                        let (alfaEnd, betaEnd) = self.regression(Array(records[max(records.count-11, 0)..<records.count]))
                        
                        var adjEnd : [Double?] = []
                        for i in 0..<records.count {
                            
                            if i < records.count-11{
                                adjEnd.append(nil)
                            }else{
                                let fi  = Double(i - (records.count-11))
                                let v  = alfaEnd * exp(betaEnd * fi)
                                adjEnd.append(v)
                            }
                            
                        }
                        
                        
                        
                        return req.eventLoop.makeSucceededFuture(DetailContent(geoid: geoId, descripcio: country.description.replacingOccurrences(of: "_", with: " "), list: records, adjusted: adjusted, alfa: alfa, beta: beta, countries: [], forecast: forecast, alfaForecast: alfaForecast, betaForecast: betaForecast, movingBeta: movingBeta, adjustEnd: adjEnd))
                }
        }
    }
    
    //MARK: Adjusting exponential
    //      Fa una integral dels valors. Al ser una exponencial no afecta al exponent
    //      I evita els problemes de punts aillats
    
    func regression(_ data : [Covid19Model]) -> (Double, Double){
        
        // First we get a log(x) for cases
        var i = 0.0
        var acum = 0.0
        
        let lnCases = data.compactMap { (point) -> (x: Double, y: Double)? in
            if  point.cases > 0.0{// Unfortunately there are
                i+=1
                acum += point.cases
                return (x:i-1, y: log(point.cases))
            }else {
                i += 1
                return nil
            }
        }
        
        // Compute averages
        
        if lnCases[0].y > lnCases.last!.y {
            print("xx")
        }
        let n = Double(lnCases.count)
        
         let Σxy = lnCases.reduce(0.0){$0 + ($1.x * $1.y)}
        let Σx = lnCases.reduce(0.0){$0 + ($1.x)}
        let Σy = lnCases.reduce(0.0){$0 + ($1.y)}
        let Σx2 = lnCases.reduce(0.0){$0 + ($1.x * $1.x)}
        let Σy2 = lnCases.reduce(0.0){$0 + ($1.y * $1.y)}

        let β = (n * Σxy -  Σx * Σy) / (n * Σx2 - Σx * Σx)
        let 𝛼 = (Σy - β * Σx) / n
        //let β =  (Σxy - Σx * yAvg - Σy * xAvg + n * xAvg * yAvg) / (Σx2 + n * xAvg * xAvg - xAvg * 2 * Σx)
        //let  yAvg - β * xAvg
        
        // Beta es exactament la mateixa integrat que sense integrar!!!
        // alfa sense integrar es alfa integrat * beta
        return (exp(𝛼), β)
    }
    
}
