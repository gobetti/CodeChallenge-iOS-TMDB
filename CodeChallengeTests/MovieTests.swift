//
//  MovieTests.swift
//  CodeChallengeTests
//
//  Created by Marcelo Gobetti on 4/19/18.
//

import XCTest
@testable import CodeChallenge

class MovieTests: XCTestCase {
    func testEqualMoviesAreEqual() {
        let movieJSONString = "{\"vote_count\":213,\"id\":346364,\"video\":false,\"vote_average\":7.2,\"title\":\"It\",\"popularity\":139.429699,\"poster_path\":\"\\/9E2y5Q7WlCVNEhP5GiVTjhEhx1o.jpg\",\"original_language\":\"en\",\"original_title\":\"It\",\"genre_ids\":[27],\"backdrop_path\":\"\\/tcheoA2nPATCm2vvXw2hVQoaEFD.jpg\",\"overview\":\"\",\"release_date\":\"2017-08-17\"}"
        let movie = try! TMDBResults.decoder.decode(Movie.self, from: movieJSONString.data(using: .utf8)!)
        let movie2 = movie
        
        XCTAssertEqual(movie, movie2)
    }
    
    func testEqualMoviesWithDifferentIDAreDifferent() {
        let movieJSONString = "{\"vote_count\":213,\"id\":346364,\"video\":false,\"vote_average\":7.2,\"title\":\"It\",\"popularity\":139.429699,\"poster_path\":\"\\/9E2y5Q7WlCVNEhP5GiVTjhEhx1o.jpg\",\"original_language\":\"en\",\"original_title\":\"It\",\"genre_ids\":[27],\"backdrop_path\":\"\\/tcheoA2nPATCm2vvXw2hVQoaEFD.jpg\",\"overview\":\"\",\"release_date\":\"2017-08-17\"}"
        let movie = try! TMDBResults.decoder.decode(Movie.self, from: movieJSONString.data(using: .utf8)!)
        
        let movie2JSONString = "{\"vote_count\":213,\"id\":346365,\"video\":false,\"vote_average\":7.2,\"title\":\"It\",\"popularity\":139.429699,\"poster_path\":\"\\/9E2y5Q7WlCVNEhP5GiVTjhEhx1o.jpg\",\"original_language\":\"en\",\"original_title\":\"It\",\"genre_ids\":[27],\"backdrop_path\":\"\\/tcheoA2nPATCm2vvXw2hVQoaEFD.jpg\",\"overview\":\"\",\"release_date\":\"2017-08-17\"}"
        let movie2 = try! TMDBResults.decoder.decode(Movie.self, from: movie2JSONString.data(using: .utf8)!)
        
        XCTAssertNotEqual(movie, movie2)
    }
}
