//
//  Genre.swift
//  CodeChallenge
//
//  Created by Marcelo Gobetti on 5/6/18.
//

import Foundation

struct Genre: Decodable {
    let id: Int
    let name: String
}

protocol GenresStoreProtocol: class {
    var genres: [Genre] { get set }
}

extension GenresStoreProtocol {
    func genreNames(for movie: Movie) -> [String] {
        return movie.genreIds.compactMap { id in
            self.genres.first { $0.id == id }?.name
        }
    }
}

final class GenresStore: GenresStoreProtocol {
    static let shared = GenresStore()
    var genres = [Genre]()
    
    private init() {}
}
