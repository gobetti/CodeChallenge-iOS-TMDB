//
//  Movie.swift
//  CodeChallenge
//
//  Created by Marcelo Gobetti on 11/4/16.
//

import Mapper

enum MovieError: Error {
    case invalidDate
}

struct Movie: Mappable {
    let name: String
    let imagePath: String? // either poster or backdrop image path
    let genreIDs: [Int]
    let releaseDate: Date
    
    private static let dateFormatter: DateFormatter = {
        $0.dateFormat = "yyyy-MM-dd"
        return $0
    }(DateFormatter())
    
    init(map: Mapper) throws {
        Movie.dateFormatter.dateFormat = "yyyy-MM-dd"
        
        try self.name = map.from("original_title")
        let imagePath: String? = map.optionalFrom("poster_path") ?? map.optionalFrom("backdrop_path")
        self.imagePath = imagePath
        try self.genreIDs = map.from("genre_ids")
        try self.releaseDate = map.from("release_date") {
            guard let dateString = $0 as? String else {
                print("Attempt to convert non-String type to Date")
                throw MovieError.invalidDate
            }
            
            guard let date = Movie.dateFormatter.date(from: dateString) else {
                print("Impossible to convert string \(dateString) to Date")
                throw MovieError.invalidDate
            }
            
            return date
        }
    }
}
