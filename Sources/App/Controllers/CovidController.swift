import Fluent
import Vapor
import Leaf
import SQLKit

struct CovidController: RouteCollection {
    
    struct TempoData : Content {
        
        var geoid : String?
        var from : String?
        var to : String?
        var acumulat : Bool
        var filter : String?
        var comparar : String?
        var escalar : Bool
        var serie : String
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
        var adjusted : [Double?]
        var alfa : Double
        var beta : Double
        var countries : [CountryId]
        var forecast : [Double?]
        var alfaForecast: Double
        var betaForecast: Double
        var movingBeta : [Double?]
        var comparar : [Double?]
        var compararName : String?// 10 últims dies
        var excessDeaths : [Double?]
    }
    struct DetailContentCatsalut : Content {
        var geoid : String
        var descripcio : String
        var list : [CatsalutModel]
        var adjusted : [Double?]
        var alfa : Double
        var beta : Double
        var countries : [CountryId]
        var forecast : [Double?]
        var alfaForecast: Double
        var betaForecast: Double
        var movingBeta : [Double?]
        var comparar : [Double?]
        var compararName : String?// 10 últims dies
        var excessDeaths : [Double?]
    }

    
    func boot(routes: RoutesBuilder) throws {
        let covid = routes.grouped("covid")
        covid.get(use: index)
        covid.get("resum", use: self.resum)
        covid.post("tempo",  use: self.tempo)
        //covid.get("detail", ":geoid", use: self.detail)
        covid.get("detail", use: self.detail)
        covid.post("tempoCat",  use: self.tempoCat)
        //covid.get("detail", ":geoid", use: self.detail)
        covid.get("catsalut", use: self.detailCatsalut)

    }
    
    func index(req: Request) throws -> EventLoopFuture<View> {
        return req.view.render("chart")
    }
    
    func detail(req: Request) -> EventLoopFuture<View>{
        return CountriesModel.query(on: req.db)
            .filter(\.$population > 500000.0)
            .sort(\.$description)
            .all()
            .flatMap{ countries in
                
                
                let codedCountries : [CountryId] = countries.reduce([]){
                    var aux = $0
                    aux.append(CountryId(geoId: $1.geoid, descripcio: $1.description.replacingOccurrences(of: "_", with: " ")) )
                    return aux
                }
        
                
                return req.view.render("detail", DetailContent(geoid: "CS"  , descripcio: "Catalunya".replacingOccurrences(of: "_", with: " "), list: [], adjusted: [], alfa: 0.0, beta:0.0, countries: codedCountries, forecast: [], alfaForecast: 0.0, betaForecast: 0.0, movingBeta: [], comparar: [], excessDeaths: []))
        }
    }
    
    func detailCatsalut(req: Request) -> EventLoopFuture<View>{
        return ComarquesModel.query(on: req.db)
            .sort(\.$description)
            .all()
            .flatMap{ countries in
                
                
                let codedCountries : [CountryId] = countries.reduce([]){
                    var aux = $0
                    aux.append(CountryId(geoId: "\($1.id!)", descripcio: $1.description.replacingOccurrences(of: "_", with: " ")))
                    return aux
                }
        
                
                return req.view.render("comarques", DetailContent(geoid: "15"  , descripcio: "Cerdanya".replacingOccurrences(of: "_", with: " "), list: [], adjusted: [], alfa: 0.0, beta:0.0, countries: codedCountries, forecast: [], alfaForecast: 0.0, betaForecast: 0.0, movingBeta: [], comparar: [], excessDeaths: []))
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
        
        guard let compararId = data.comparar else {
            return req.eventLoop.makeFailedFuture(Abort(.badRequest))
        }
        
        var from = Date.from(string: data.from ?? "") ?? Date.from(string: "01/02/20")!
        var to = Date.from(string: data.to ?? "") ?? Date()
        
        if to < from {
            let aux = to
            to = from
            from = aux
        }
        
        
        var filter = 0
        
        if let fil = data.filter{
            if let file = Int(fil){
                filter = Int(file)
            }
            
        }
        
        filter = max(filter, 0)
        filter = min(filter, 8)
        
        let serie = Int(data.serie)
        
        
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
                    .sort(\.$year)
                    .sort(\.$month)
                    .sort(\.$day)
                    .all()
                    .flatMap{ records in
                        
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
                                    
                                    records[i].cases = cases / ((2.0 * Double(filter)) )
                                    records[i].deaths = deaths / ((2.0 * Double(filter)))
                                    
                                }
                            }
                        }
                        
                        
                        var iMax = 0
                        var i400 = 0
                        
                        var i = 0
                        
                        _ = records.reduce(0.0){
                            if $1.cases > $0 {
                                iMax = i
                            }
                            
                            if $1.cases > 400.0 && i400 == 0{
                                i400 = i
                            }
                            i += 1
                            return max($0, $1.cases)
                        }
                        
                        if i400 == 0{
                            i400 = records.count-1
                        }
                        
                        if data.escalar && ((country.population ?? 0.0) > 0.0){
                            for i in 0..<records.count {
                                
                                records[i].cases = records[i].cases / (country.population ?? 0.0) * 1000000.0
                                records[i].deaths = records[i].deaths / (country.population ?? 0.0) * 1000000.0
                            }
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
                        
                        var acc = 0
                        var start = 0
                        
                        for record in records {
                            if record.cases > 0.0{
                                acc += 1
                                if acc > 3{
                                    break
                                }
                            }else{
                                acc = 0
                            }
                            start += 1
                        }
                        
                        if start == records.count {
                            start = 0
                        }
                        
                        if i400 < start {
                            i400 = min(start + 10, records.count-1)
                        }
                        if iMax < start {
                            iMax = records.count-1
                        }
                        
                        
                        let adjustableRecords : [Covid19Model] = Array(records[start..<iMax])
                        var (alfa, beta) = self.regression(adjustableRecords)
                        
                        var adjusted : [Double?] = []
                        if records.count > 0{
                            for i in 0..<records.count {
                                if i < start {
                                    adjusted.append(nil)
                                }else {
                                    let fi = Double(i-start)
                                    let v  = alfa * exp(beta * fi)
                                    adjusted.append(v)
                                }
                            }
                        }
                        
                        // Remove origining records till first 3 consecutive non zero values
                        
                        
                        let gouvRecords : [Covid19Model] = Array(records[start..<i400])
                        var (alfaForecast, betaForecast) = self.regression(gouvRecords)
                        
                        var forecast : [Double?] = []
                        if records.count > 0{
                            for i in 1...records.count {
                                if i < start {
                                    forecast.append(nil)
                                }else{
                                    let fi = Double(i - start)
                                    let v  = alfaForecast * exp(betaForecast * fi)
                                    forecast.append(v)
                                }
                                
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
                                
                                let (_, mbeta) = self.regression(Array(records[(ix-delta)..<(ix+delta)]))
                                
                                if mbeta.isNaN {
                                    movingBeta.append(nil)
                                }else {
                                    movingBeta.append(mbeta)
                                }
                            }
                        }
                        
                        return VDeathsNYTModel.query(on: req.db)
                            .filter(\.$country == country.id!)
                            .filter(\.$reportingDate >= from)
                            .filter(\.$reportingDate <= to)
                            .filter(\.$excessDeaths >= 0.0)
                            .filter(\.$placename == nil)
                            .sort(\.$year)
                            .sort(\.$month)
                            .sort(\.$week)
                            .all()
                            .flatMap { excess in
                                
                                
                                var acumDeaths = 0.0
                                var excessDeaths : [Double?] = []
                                
                                for record in excess {
                                    
                                    acumDeaths += record.excessDeaths
                                    if data.acumulat {
                                        if data.escalar {
                                            record.excessDeaths = acumDeaths / (country.population ?? 0.0) * 1000000.0
                                        }else {
                                            record.excessDeaths = acumDeaths
                                        }
                                        
                                    } else {
                                        if data.escalar{
                                            record.excessDeaths = record.excessDeaths / (record.frequency == "weekly" ? 7.0 : 30.0) / (country.population ?? 0.0) * 1000000.0
                                        }else {
                                            record.excessDeaths = record.excessDeaths / (record.frequency == "weekly" ? 7.0 : 30.0)
                                        }
                                        
                                    }
                                }
                                
                                // Now we must generate correct values for all interpolated points.
                                
                                for record in records {
                                    
                                    let items =  excess.filter {
                                        record.reportingDate == $0.reportingDate
                                    }
                                    if let item = items.first{
                                        excessDeaths.append(item.excessDeaths)
                                    }else {
                                        excessDeaths.append(nil)
                                    }                                      
                                }
                                
                                
                                return CountriesModel.query(on: req.db)
                                    .filter(\.$geoid == compararId)
                                    .first()
                                    .unwrap(or: Abort(.notFound))
                                    .flatMap{ country1 in
                                        
                                        return Covid19Model.query(on: req.db)
                                            .filter(\.$country == country1.id!)
                                            .filter(\.$reportingDate >= from)
                                            .filter(\.$reportingDate <= to)
                                            .filter(\.$cases >= 0.0)
                                            .sort(\.$year)
                                            .sort(\.$month)
                                            .sort(\.$day)
                                            .all()
                                            .flatMap{ compararRecords in
                                                
                                                
                                                if filter > 0 {
                                                    for i in 0..<compararRecords.count {
                                                        
                                                        if !(i < filter || i >= (compararRecords.count - filter)){
                                                            
                                                            var cases = 0.0
                                                            var deaths = 0.0
                                                            for j in i-filter..<i+filter {
                                                                cases += compararRecords[j].cases
                                                                deaths += compararRecords[j].deaths
                                                            }
                                                            
                                                            compararRecords[i].cases = cases / ((2.0 * Double(filter)) )
                                                            compararRecords[i].deaths = deaths / ((2.0 * Double(filter)))
                                                            
                                                        }
                                                    }
                                                }
                                                
                                                if data.escalar && ((country1.population ?? 0.0) > 0.0){
                                                    for i in 0..<compararRecords.count {
                                                        
                                                        compararRecords[i].cases = compararRecords[i].cases / (country1.population ?? 0.0) * 1000000.0
                                                        compararRecords[i].deaths = compararRecords[i].deaths / (country1.population ?? 0.0) * 1000000.0
                                                    }
                                                }
                                                
                                                
                                                var comparar = compararRecords.map{ (serie == 1) ? $0.deaths : $0.cases }
                                                
                                                var acum = 0.0
                                                if data.acumulat {
                                                    for i in 0..<comparar.count {
                                                        acum += comparar[i]
                                                        comparar[i] = acum
                                                    }
                                                }
                                                
                                                return req.eventLoop.makeSucceededFuture(DetailContent(geoid: geoId, descripcio: country.description.replacingOccurrences(of: "_", with: " "), list: records, adjusted: adjusted, alfa: alfa, beta: beta, countries: [], forecast: forecast, alfaForecast: alfaForecast, betaForecast: betaForecast, movingBeta: movingBeta, comparar: comparar, compararName : country1.description, excessDeaths: excessDeaths))
                                        }
                                }
                        }
                }
        }
    }
    
    /// Retorna dades de la taula catsalut (catalunya per comarques). De moment tan sols Positius PCR per no complicar
    
    func buildQuery(serie: Int, comarca: Int, from: Date, to: Date) -> SQLQueryString {
        
        var tipus = "%"
        switch(serie) {
        
        case 1:
            tipus = "Positiu PCR"
            
        case 2:
            tipus = "Positiu%"
        
        default:
            tipus = "%"
            
        }

        let queryString = """

            with dates as (
                select * from generate_series('\(from.dateString)'::date, '\(to.dateString)'::date, '1 day')  as data
            )
            select d.data, sum(coalesce(c.num_casos, 0)) as casos from dates d
            left join catsalut c on (c.data = d.data
                    and c.codi_comarca = \(comarca)
                    and c.tipus ilike '\(tipus)' )
            group by d.data
            order by d.data
        """
        
        return SQLQueryString(queryString)

        
    }
    
    func tempoCat(req: Request )-> EventLoopFuture<DetailContentCatsalut> {
        
        guard let data = try? req.content.decode(TempoData.self)
            else {
                return req.eventLoop.makeFailedFuture(Abort(.badRequest))
        }
        guard let val = data.geoid, let geoId = Int(val) else {
            return req.eventLoop.makeFailedFuture(Abort(.badRequest))
        }
        
        guard let val1 = data.comparar, let compararId = Int(val1) else {
            return req.eventLoop.makeFailedFuture(Abort(.badRequest))
        }
        
        var from = Date.from(string: data.from ?? "") ?? Date.from(string: "01/02/20")!
        var to = Date.from(string: data.to ?? "") ?? Date()
        
        if to < from {
            let aux = to
            to = from
            from = aux
        }
        
        
        var filter = 0
        
        if let fil = data.filter{
            if let file = Int(fil){
                filter = Int(file)
            }
        }
        
        filter = max(filter, 0)
        filter = min(filter, 8)
        
        let serie = Int(data.serie)!
        

        
        return ComarquesModel.query(on: req.db)
            .filter(\.$id == geoId)
            .first()
            .unwrap(or: Abort(.notFound))
            .flatMap{ country in
                
                let query = self.buildQuery(serie: serie, comarca: country.id!, from: from, to: to)

                return (req.db as! SQLDatabase).raw(query)
                    .all()
                    .mapEach{
                        CatsalutModel(grouped: try! $0.decode(model: GroupedCatsalutModel.self), codiComarca: country.id!, descComarca: country.description )
                    }
                    .flatMap{ records in
                        
                        // filtering (computes moving average)
                        if filter > 0 {
                            for i in 0..<records.count {
                                
                                if !(i < filter || i >= (records.count - filter)){
                                    
                                    var cases = 0.0
                                    var deaths = 0.0
                                    for j in i-filter..<i+filter {
                                        cases += records[j].cases
                                        deaths += 0 //records[j].deaths
                                    }
                                    
                                    records[i].cases = cases / ((2.0 * Double(filter)) )
                                    //records[i].deaths = deaths / ((2.0 * Double(filter)))
                                    
                                }
                            }
                        }
                        
                        
                        var iMax = 0
                        var i400 = 0
                        
                        var i = 0
                        
                        _ = records.reduce(0.0){
                            if $1.cases > $0 {
                                iMax = i
                            }
                            
                            if $1.cases > 400.0 && i400 == 0{
                                i400 = i
                            }
                            i += 1
                            return max($0, $1.cases)
                        }
                        
                        if i400 == 0{
                            i400 = records.count-1
                        }
                        
                        if data.escalar && ((country.population ?? 0.0) > 0.0){
                            for i in 0..<records.count {
                                
                                records[i].cases = records[i].cases / (country.population ?? 0.0) * 1000000.0
                                //records[i].deaths = records[i].deaths / (country.population ?? 0.0) * 1000000.0
                            }
                        }
                        
                        
                        if data.acumulat {
                            
                            var acumCases = 0.0
                            //var acumDeaths = 0.0
                            
                            for record in records {
                                acumCases += record.cases
                                //acumDeaths += record.deaths
                                
                                record.cases = acumCases
                                //record.deaths = acumDeaths
                            }
                        }
                        
                        var acc = 0
                        var start = 0
                        
                        for record in records {
                            if record.cases > 0.0{
                                acc += 1
                                if acc > 3{
                                    break
                                }
                            }else{
                                acc = 0
                            }
                            start += 1
                        }
                        
                        if start == records.count {
                            start = 0
                        }
                        
                        if i400 < start {
                            i400 = min(start + 10, records.count-1)
                        }
                        if iMax < start {
                            iMax = records.count-1
                        }
                        
                        
                        let adjustableRecords : [CatsalutModel] = Array(records[start..<iMax])
                        var (alfa, beta) = self.regressionCatsalut(adjustableRecords)
                        
                        var adjusted : [Double?] = []
                        if records.count > 0{
                            for i in 0..<records.count {
                                if i < start {
                                    adjusted.append(nil)
                                }else {
                                    let fi = Double(i-start)
                                    let v  = alfa * exp(beta * fi)
                                    adjusted.append(v)
                                }
                            }
                        }
                        
                        // Remove origining records till first 3 consecutive non zero values
                        
                        
                        let gouvRecords : [CatsalutModel] = Array(records[start..<i400])
                        var (alfaForecast, betaForecast) = self.regressionCatsalut(gouvRecords)
                        
                        var forecast : [Double?] = []
                        if records.count > 0{
                            for i in 1...records.count {
                                if i < start {
                                    forecast.append(nil)
                                }else{
                                    let fi = Double(i - start)
                                    let v  = alfaForecast * exp(betaForecast * fi)
                                    forecast.append(v)
                                }
                                
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
                                
                                let (_, mbeta) = self.regressionCatsalut(Array(records[(ix-delta)..<(ix+delta)]))
                                
                                if mbeta.isNaN {
                                    movingBeta.append(nil)
                                }else {
                                    movingBeta.append(mbeta)
                                }
                            }
                        }
                        
                        return VDeathsNYTModel.query(on: req.db)
                            .filter(\.$country == -1)
                            .filter(\.$reportingDate >= from)
                            .filter(\.$reportingDate <= to)
                            .filter(\.$excessDeaths >= 0.0)
                            .filter(\.$placename == nil)
                            .sort(\.$year)
                            .sort(\.$month)
                            .sort(\.$week)
                            .all()
                            .flatMap { excess in
                                
                                
                                var acumDeaths = 0.0
                                var excessDeaths : [Double?] = []
                                
                                for record in excess {
                                    
                                    acumDeaths += record.excessDeaths
                                    if data.acumulat {
                                        if data.escalar {
                                            record.excessDeaths = acumDeaths / (country.population ?? 0.0) * 1000000.0
                                        }else {
                                            record.excessDeaths = acumDeaths
                                        }
                                        
                                    } else {
                                        if data.escalar{
                                            record.excessDeaths = record.excessDeaths / (record.frequency == "weekly" ? 7.0 : 30.0) / (country.population ?? 0.0) * 1000000.0
                                        }else {
                                            record.excessDeaths = record.excessDeaths / (record.frequency == "weekly" ? 7.0 : 30.0)
                                        }
                                        
                                    }
                                }
                                
                                // Now we must generate correct values for all interpolated points.
                                
                                for record in records {
                                    
                                    let items =  excess.filter {
                                        record.reportingDate == $0.reportingDate
                                    }
                                    if let item = items.first{
                                        excessDeaths.append(item.excessDeaths)
                                    }else {
                                        excessDeaths.append(nil)
                                    }
                                }
                                
                                
                                return ComarquesModel.query(on: req.db)
                                    .filter(\.$id == compararId)
                                    .first()
                                    .unwrap(or: Abort(.notFound))
                                    .flatMap{ country1 in
                                        let query = self.buildQuery(serie: serie, comarca: country1.id!, from: from, to: to)
                                        return (req.db as! SQLDatabase).raw(query)
                                             .all()
                                            .mapEach{
                                                CatsalutModel(grouped: try! $0.decode(model: GroupedCatsalutModel.self), codiComarca: country1.id!, descComarca: country1.description )
                                            }

                                            .flatMap{ compararRecords in
                                                
                                                if filter > 0 {
                                                    for i in 0..<compararRecords.count {
                                                        
                                                        if !(i < filter || i >= (compararRecords.count - filter)){
                                                            
                                                            var cases = 0.0
                                                            //var deaths = 0.0
                                                            for j in i-filter..<i+filter {
                                                                cases += compararRecords[j].cases
                                                                //deaths += compararRecords[j].deaths
                                                            }
                                                            
                                                            compararRecords[i].cases = cases / ((2.0 * Double(filter)) )
                                                            //compararRecords[i].deaths = deaths / ((2.0 * Double(filter)))
                                                        }
                                                    }
                                                }
                                                
                                                if data.escalar && ((country1.population ?? 0.0) > 0.0){
                                                    for i in 0..<compararRecords.count {
                                                        
                                                        compararRecords[i].cases = compararRecords[i].cases / (country1.population ?? 0.0) * 1000000.0
                                                        //compararRecords[i].deaths = compararRecords[i].deaths / (country1.population ?? 0.0) * 1000000.0
                                                    }
                                                }
                                                
                                                var comparar : [Double] = []
                                                
                                                for r in records {
                                                    
                                                    let target = r.reportingDate
                                                    
                                                    if let cr = compararRecords.first(where: {$0.reportingDate == target}){
                                                        comparar.append(cr.cases)
                                                    }else {
                                                        comparar.append(0.0)
                                                    }
                                                    
                                                    
                                                    
                                                }
                                                
                                                //var comparar = compararRecords.map{ (serie == 1) ? $0.deaths : $0.cases }
                                                
                                                var acum = 0.0
                                                if data.acumulat {
                                                    for i in 0..<comparar.count {
                                                        acum += comparar[i]
                                                        comparar[i] = acum
                                                    }
                                                }
                                                
                                                return req.eventLoop.makeSucceededFuture(DetailContentCatsalut(geoid: "\(geoId)", descripcio: country.description.replacingOccurrences(of: "_", with: " "), list: records, adjusted: adjusted, alfa: alfa, beta: beta, countries: [], forecast: forecast, alfaForecast: alfaForecast, betaForecast: betaForecast, movingBeta: movingBeta, comparar: comparar, compararName : country1.description, excessDeaths: excessDeaths))
                                        }
                                }
                        }
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
        
        let n = Double(lnCases.count)
        
        let Σxy = lnCases.reduce(0.0){$0 + ($1.x * $1.y)}
        let Σx = lnCases.reduce(0.0){$0 + ($1.x)}
        let Σy = lnCases.reduce(0.0){$0 + ($1.y)}
        let Σx2 = lnCases.reduce(0.0){$0 + ($1.x * $1.x)}
        //        let Σy2 = lnCases.reduce(0.0){$0 + ($1.y * $1.y)}
        
        let β = (n * Σxy -  Σx * Σy) / (n * Σx2 - Σx * Σx)
        let 𝛼 = (Σy - β * Σx) / n
        //let β =  (Σxy - Σx * yAvg - Σy * xAvg + n * xAvg * yAvg) / (Σx2 + n * xAvg * xAvg - xAvg * 2 * Σx)
        //let  yAvg - β * xAvg
        
        // Beta es exactament la mateixa integrat que sense integrar!!!
        // alfa sense integrar es alfa integrat * beta
        return (exp(𝛼), β)
    }
    
    
    func regressionCatsalut(_ data : [CatsalutModel]) -> (Double, Double){
        
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
        
        let n = Double(lnCases.count)
        
        let Σxy = lnCases.reduce(0.0){$0 + ($1.x * $1.y)}
        let Σx = lnCases.reduce(0.0){$0 + ($1.x)}
        let Σy = lnCases.reduce(0.0){$0 + ($1.y)}
        let Σx2 = lnCases.reduce(0.0){$0 + ($1.x * $1.x)}
        //        let Σy2 = lnCases.reduce(0.0){$0 + ($1.y * $1.y)}
        
        let β = (n * Σxy -  Σx * Σy) / (n * Σx2 - Σx * Σx)
        let 𝛼 = (Σy - β * Σx) / n
        //let β =  (Σxy - Σx * yAvg - Σy * xAvg + n * xAvg * yAvg) / (Σx2 + n * xAvg * xAvg - xAvg * 2 * Σx)
        //let  yAvg - β * xAvg
        
        // Beta es exactament la mateixa integrat que sense integrar!!!
        // alfa sense integrar es alfa integrat * beta
        return (exp(𝛼), β)
    }

    
}
