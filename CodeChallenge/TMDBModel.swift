//
//  TMDBModel.swift
//  CodeChallenge
//
//  Created by Marcelo Gobetti on 10/31/16.
//

import Mapper
import Moya
import Moya_ModelMapper
import RxSwift

enum TMDBModelError: Error {
    case missingImagePath
}

struct TMDBModel {
    private let imageProvider = MoyaProvider<TMDBImage>()
    private let moviesProvider = MoyaProvider<TMDB>()
    
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
            .map(to: [Movie].self, keyPath: "results")
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
