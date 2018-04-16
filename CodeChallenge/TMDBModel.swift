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
    
    func search(query: String, page: Int = 1) -> Single<TMDBResults> {
        return self.requestMovies(.search(query: query, page: page))
    }
    
    func upcomingMovies(page: Int = 1) -> Single<TMDBResults> {
        return self.requestMovies(.upcomingMovies(page: page))
    }
    
    // Maps into [Movie] the "results" part of the JSON returned by the API
    private func requestMovies(_ type: TMDB) -> Single<TMDBResults> {
        return self.moviesProvider.rx
            .request(type)
            .map { response -> TMDBResults in
                return try TMDBResults.decoder.decode(TMDBResults.self, from: response.data)
            }
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
    case search(query: String, page: Int)
    case upcomingMovies(page: Int)
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
        case .search:
            return "/search/movie"
        case .upcomingMovies:
            return "/movie/upcoming"
        }
    }
    
    public var method: Moya.Method {
        return .get
    }
    
    public var sampleData: Data {
        switch self {
        case .search:
            return try! Data(contentsOf: Bundle.main.url(forResource: "search_1", withExtension: "json")!)
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
        let defaultParameters = ["api_key" : api_key]
        var parameters = defaultParameters
        
        switch self {
        case .search(_, let page),
             .upcomingMovies(let page):
            parameters.merge(["page": "\(page)"]) { (_, new) in new }
        }
        
        if case .search(let query, _) = self {
            parameters.merge(["query": "\(query)"]) { (_, new) in new }
        }
        
        return parameters
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

struct TMDBResults: Decodable, Equatable {
    private let results: [FailableMovie]
    let totalPages: Int
    
    var movies: [Movie] {
        return self.results.compactMap { $0.movie }
    }
    
    init(movies: [Movie], totalPages: Int) {
        self.results = movies.map(FailableMovie.init)
        self.totalPages = totalPages
    }
    
    static let decoder: JSONDecoder = {
        $0.dateDecodingStrategy = .formatted(Movie.dateFormatter)
        $0.keyDecodingStrategy = .convertFromSnakeCase
        return $0
    }(JSONDecoder())
}

private struct FailableMovie: Decodable, Equatable {
    let movie: Movie?
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        self.movie = try? container.decode(Movie.self)
    }
    
    init(movie: Movie) {
        self.movie = movie
    }
}
