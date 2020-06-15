//
//  Date + Format.swift
//  Conta_00
//
//  Created by Francisco Gorina Vanrell on 14/03/2020.
//  Copyright © 2020 Francisco Gorina Vanrell. All rights reserved.
//

import Foundation

extension  DateFormatter {
    
    convenience init(format : String){
        self.init()
        self.dateFormat = format
    }
    

}

extension Date {
    
    static let dateFormat = DateFormatter(format: "dd/MM/yy")
    static let timeFormat = DateFormatter(format: "HH:mm:ss")
    static let yearFormat = DateFormatter(format: "yy")
    static let pathFormat = DateFormatter(format: "dd-MM-yy")
    static let n43Format = DateFormatter(format: "yyMMdd")
    static let sepasFormat = DateFormatter(format: "yyyy-MM-dd")
    static let anotherFormat = DateFormatter(format: "dd-MM-yyyy")

    
    var dateString : String { return Date.dateFormat.string(from: self) }
    var timeString : String { return Date.timeFormat.string(from: self) }
    
    var yearString : String { return Date.yearFormat.string(from: self) }
    var pathString : String { return Date.pathFormat.string(from: self) }
    
    static func from(string: String) -> Date?{
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd/MM/yy"
        if let d =  dateFormatter.date(from:string) {
            return d
        }else if let d = sepasFormat.date(from: string) {
            return d
        }else {
            
            return anotherFormat.date(from:string)
        }
    }
    
    static func from(string: String, format: String) -> Date?{
         let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = format
        return dateFormatter.date(from:string)
   }
    static func fromN43(string: String) -> Date?{
        return n43Format.date(from:string)
    }

    func formatted(format: String) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = format
        return dateFormatter.string(from: self)
    }
    
    func startOfYear() -> Date?{
        
        var components = Calendar.current.dateComponents([.year, .month, .day], from: self)
        
        components.month = 1
        components.day = 1
        
        return Calendar.current.date(from: components)
    }
    
    var startOfDay: Date {
        return Calendar.current.startOfDay(for: self)
    }

    var startOfMonth: Date {

        let calendar = Calendar(identifier: .gregorian)
        let components = calendar.dateComponents([.year, .month], from: self)

        return  calendar.date(from: components)!
    }

    var endOfDay: Date {
        var components = DateComponents()
        components.day = 1
        components.second = -1
        return Calendar.current.date(byAdding: components, to: startOfDay)!
    }

    var endOfMonth: Date {
        var components = DateComponents()
        components.month = 1
        components.second = -1
        return Calendar(identifier: .gregorian).date(byAdding: components, to: startOfMonth)!
    }
    
    var previousMonth: Date {
        var components = DateComponents()
        components.month = -1

        return Calendar(identifier: .gregorian).date(byAdding: components, to: self)!
    }
    
    var endOfPreviousMonth: Date {
        var components = DateComponents()
        components.second = -1
        return Calendar(identifier: .gregorian).date(byAdding: components, to: startOfMonth)!
    }
    
       // lastQuarter retorna el primer i ultim dia del passat trimestre
       
       var lastQuarter : (start: Date, end: Date){
           let end = endOfPreviousMonth
           let start = addMonths(-3).startOfMonth
           
           return(start: start, end: end)
       }
    
        /// quarter  gives current quarter (1..4)
    
    var quarter : Int {
        let components = Calendar.current.dateComponents([.month], from: self)
        
        return (((components.month ?? 1) - 1) / 3) + 1
    
    }
    
    var year : Int {
        let components = Calendar.current.dateComponents([.year], from: self)
        
        return components.year ?? 0
    
    }

    func isMonday() -> Bool {
        let calendar = Calendar(identifier: .gregorian)
        let components = calendar.dateComponents([.weekday], from: self)
        return components.weekday == 2
    }
    
    func isWorkDay() -> Bool {
        let calendar = Calendar(identifier: .gregorian)
        let components = calendar.dateComponents([.weekday], from: self)
        return components.weekday! >= 2 && components.weekday! <= 6
    }


    func monthCode() -> Int {
        let components = Calendar.current.dateComponents([.year, .month, .day], from: self)
        return (components.year ?? 0) * 100 + (components.month ?? 0)
    }
    
    func addDays(_ days : Int) -> Date {
        
        var components = DateComponents()
        components.day = days
        
        return Calendar.current.date(byAdding: components,  to: self, wrappingComponents: false)!

    }
    func addMonths(_ months : Int) -> Date {
        
        var components = DateComponents()
        components.month = months
        
        return Calendar.current.date(byAdding: components,  to: self, wrappingComponents: false)!

    }

   
    /// Return days from a date
    
    func daysFrom(_ aDate : Date) -> Int{
    
        let calendar = Calendar.current

        // Replace the hour (time) of both dates with 00:00
        let date1 = calendar.startOfDay(for: self)
        let date2 = calendar.startOfDay(for: aDate)

        let components = calendar.dateComponents([.day], from: date2, to: date1)
        
        return components.day ?? 0
    }
}
