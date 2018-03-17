//
//  TMDBModel.swift
//  CodeChallenge
//
//  Created by Marcelo Gobetti on 10/31/16.
//

import Moya
import RxSwift

enum TMDBModelError: Error {
    case missingImagePath
}

struct TMDBModel {
    typealias ImageProvider = MoyaProvider<TMDBImage>
    typealias MoviesProvider = MoyaProvider<TMDB>
    
    private let imageProvider: ImageProvider
    private let moviesProvider: MoviesProvider
    
    init(imageClosures: MoyaClosures<TMDBImage> = MoyaClosures<TMDBImage>(),
         moviesClosures: MoyaClosures<TMDB> = MoyaClosures<TMDB>()) {
        self.imageProvider = ImageProvider(endpointClosure: imageClosures.endpointClosure,
                                           stubClosure: imageClosures.stubClosure)
        self.moviesProvider = MoviesProvider(endpointClosure: moviesClosures.endpointClosure,
                                             stubClosure: moviesClosures.stubClosure)
    }
    
    func image(width: Int, from movie: Movie) -> Single<Image?> {
        guard movie.imagePath != nil else {
            return .error(TMDBModelError.missingImagePath)
        }
        
        return self.imageProvider.rx
            .request(.movie(movie: movie, imageWidth: width))
            .mapImage()
    }
    
    // TODO: add page parameter
    func upcomingMovies() -> Single<[Movie]> {
        return self.requestMovies(.upcomingMovies)
    }
    
    // Maps into [Movie] the "results" part of the JSON returned by the API
    private func requestMovies(_ type: TMDB) -> Single<[Movie]> {
        return self.moviesProvider.rx
            .request(type)
            .map { response -> TMDBResults in
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .formatted(Movie.dateFormatter)
                return try decoder.decode(TMDBResults.self, from: response.data)
            }.map { $0.movies }
    }
}

struct MoyaClosures<T: TargetType> {
    let endpointClosure: MoyaProvider<T>.EndpointClosure
    let stubClosure: MoyaProvider<T>.StubClosure
    
    init(endpointClosure: @escaping MoyaProvider<T>.EndpointClosure = MoyaProvider<T>.defaultEndpointMapping,
         stubClosure: @escaping MoyaProvider<T>.StubClosure = MoyaProvider<T>.neverStub) {
        self.endpointClosure = endpointClosure
        self.stubClosure = stubClosure
    }
}

enum TMDB {
    case upcomingMovies
}

enum TMDBImage {
    case movie(movie: Movie, imageWidth: Int)
}

extension TMDB: TargetType {
    public var baseURL: URL {
        return URL(string: "https://api.themoviedb.org/3")!
    }
    
    public var path: String {
        switch self {
        case .upcomingMovies:
            return "/movie/upcoming"
        }
    }
    
    public var method: Moya.Method {
        return .get
    }
    
    public var sampleData: Data {
        switch self {
        case .upcomingMovies:
            return try! Data(contentsOf: Bundle.main.url(forResource: "upcoming_page_1", withExtension: "json")!)
        }
    }
    
    public var task: Task {
        return .requestParameters(parameters: self.parameters,
                                  encoding: URLEncoding())
    }
    
    public var headers: [String : String]? {
        return nil
    }
    
    private var parameters: [String: Any] {
        // TODO: page
        return ["api_key" : api_key]
    }
}

extension TMDBImage: TargetType {
    public var baseURL: URL { return URL(string: "https://image.tmdb.org/t/p")! }
    
    public var path: String {
        switch self {
        case let .movie(movie, imageWidth):
            return "/w\(imageWidth)\(movie.imagePath!)"
        }
    }
    
    public var method: Moya.Method {
        return .get
    }
    
    public var parameters: [String: Any]? {
        return nil
    }
    
    public var sampleData: Data {
        switch self {
        case .movie:
            return try! Data(contentsOf: Bundle.main.url(forResource: "poster", withExtension: "jpg")!)
        }
    }
    
    public var task: Task {
        return .requestPlain
    }
    
    public var headers: [String : String]? {
        return nil
    }
}

private struct TMDBResults: Decodable {
    let movies: [Movie]
    
    enum CodingKeys: String, CodingKey {
        case movies = "results"
    }
}
