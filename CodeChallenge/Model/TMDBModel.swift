//
//  TMDBModel.swift
//  CodeChallenge
//
//  Created by Marcelo Gobetti on 10/31/16.
//

import RxSwift

enum TMDBModelError: Error {
    case missingImagePath
}

struct TMDBModel {
    typealias ImageProvider = Provider<TMDBImage>
    typealias MoviesProvider = Provider<TMDB>
    
    private let imageProvider: ImageProvider
    private let moviesProvider: MoviesProvider
    private let genresStore: GenresStoreProtocol
    
    init(stubBehavior: StubBehavior = .never,
         scheduler: SchedulerType = ConcurrentDispatchQueueScheduler(qos: .background),
         genresStore: GenresStoreProtocol = GenresStore.shared) {
        self.imageProvider = ImageProvider(stubBehavior: stubBehavior, scheduler: scheduler)
        self.moviesProvider = MoviesProvider(stubBehavior: stubBehavior, scheduler: scheduler)
        self.genresStore = genresStore
    }
    
    func image(width: Int, from movie: Movie) -> Single<UIImage> {
        guard movie.imagePath != nil else {
            return .error(TMDBModelError.missingImagePath)
        }
        
        return self.imageProvider
            .request(.movie(movie: movie, imageWidth: width))
            .mapImage()
    }
    
    func search(query: String, page: Int = 1) -> Single<TMDBResults> {
        return self.requestMovies(.search(query: query, page: page))
    }
    
    func upcomingMovies(page: Int = 1) -> Single<TMDBResults> {
        return self.requestMovies(.upcomingMovies(page: page))
    }
    
    // MARK: - Private
    private func requestGenres() -> Single<[Genre]> {
        return self.moviesProvider
            .request(TMDB.genres)
            .map { data -> TMDBGenres in
                return try JSONDecoder().decode(TMDBGenres.self, from: data)
            }.map { $0.genres }
    }
    
    private func requestMovies(_ type: TMDB) -> Single<TMDBResults> {
        return self.moviesProvider
            .request(type)
            .map { data -> TMDBResults in
                return try TMDBResults.decoder.decode(TMDBResults.self, from: data)
            }.flatMap { results -> Single<TMDBResults> in
                let hasUnknownGenre = results.movies.contains {
                    $0.genreIds.contains {
                        !self.genresStore.genres.map { $0.id }.contains($0)
                    }
                }
                guard !hasUnknownGenre else {
                    return self.requestGenres()
                        .do(onSuccess: { self.genresStore.genres = $0 })
                        .map { _ in results }
                }
                return .just(results)
        }
    }
}

enum TMDB {
    case genres
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
        case .genres:
            return "/genre/movie/list"
        case .search:
            return "/search/movie"
        case .upcomingMovies:
            return "/movie/upcoming"
        }
    }
    
    public var method: HTTPMethod {
        return .get
    }
    
    public var sampleData: Data {
        func jsonData(fromFile fileName: String) -> Data {
            return try! Data(contentsOf: Bundle.main.url(forResource: fileName, withExtension: "json")!)
        }
        
        switch self {
        case .genres:
            return jsonData(fromFile: "genres")
        case .search:
            return jsonData(fromFile: "search_1")
        case .upcomingMovies(let page):
            if page == 2 {
                return jsonData(fromFile: "upcoming_page_2")
            }
            return jsonData(fromFile: "upcoming_page_1")
        }
    }
    
    public var task: Task {
        return .requestParameters(parameters: self.parameters)
    }
    
    public var headers: [String : String]? {
        return nil
    }
    
    private var parameters: [String: String] {
        let defaultParameters = ["api_key" : api_key]
        var parameters = defaultParameters
        
        switch self {
        case .genres:
            break
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
    
    public var method: HTTPMethod {
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

struct TMDBGenres: Decodable {
    let genres: [Genre]
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
