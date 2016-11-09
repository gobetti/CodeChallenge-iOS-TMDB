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

struct TMDBModel {
    private let provider = MoyaProvider<TMDB>()
    
    // TODO: add page parameter
    func upcomingMovies() -> Single<[Movie]> {
        return self.requestMovies(.upcomingMovies)
    }
    
    // Maps into [Movie] the "results" part of the JSON returned by the API
    private func requestMovies(_ type: TMDB) -> Single<[Movie]> {
        return self.provider.rx
            .request(type)
            .map(to: [Movie].self, keyPath: "results")
    }
}

enum TMDB {
    case upcomingMovies
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
