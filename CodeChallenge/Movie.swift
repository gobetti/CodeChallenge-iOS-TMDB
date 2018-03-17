//
//  Movie.swift
//  CodeChallenge
//
//  Created by Marcelo Gobetti on 11/4/16.
//

import Foundation

struct Movie: Decodable {
    private let id: Int
    private let posterPath: String?
    private let backdropPath: String?
    
    let name: String
    let genreIDs: [Int]
    let releaseDate: Date
    
    var imagePath: String? {
        return posterPath ?? backdropPath
    }
    
    static let dateFormatter: DateFormatter = {
        $0.dateFormat = "yyyy-MM-dd"
        return $0
    }(DateFormatter())
    
    private enum CodingKeys: String, CodingKey {
        case id
        case posterPath = "poster_path"
        case backdropPath = "backdrop_path"
        case name = "original_title"
        case genreIDs = "genre_ids"
        case releaseDate = "release_date"
    }
}
