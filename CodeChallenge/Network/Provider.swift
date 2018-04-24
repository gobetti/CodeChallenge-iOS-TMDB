//
//  Provider.swift
//  CodeChallenge
//
//  Created by Marcelo Gobetti on 4/23/18.
//

import Foundation
import RxSwift

enum ProviderError: Error {
    case invalidResponse
    case invalidURL
}

struct Provider<Target: TargetType> {
    public func request(_ target: Target) -> Single<Response> {
        guard let url = URL(string: target.baseURL.absoluteString + target.path) else {
            return .error(ProviderError.invalidURL)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = target.method.rawValue
        request.allHTTPHeaderFields = target.headers
        
        switch target.task {
        case .requestParameters(let parameters):
            guard !parameters.isEmpty else { break }
            
            let query = parameters.compactMap { key, value in
                guard let escapedKey = key.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
                    let escapedValue = value.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
                        return nil
                }
                return "\(escapedKey)=\(escapedValue)"
                }.joined(separator: "&")
            
            if var urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false) {
                urlComponents.percentEncodedQuery = query
                request.url = urlComponents.url
            }
        case .requestPlain: break
        }
        
        return Single.create { event -> Disposable in
            let task = self.urlSession.dataTask(with: request) { data, urlResponse, error in
                if let error = error {
                    event(.error(error))
                    return
                }
                
                guard let data = data, let statusCode = (urlResponse as? HTTPURLResponse)?.statusCode else {
                    event(.error(ProviderError.invalidResponse))
                    return
                }
                
                event(.success(Response(statusCode: statusCode, data: data)))
            }
            task.resume()
            
            return Disposables.create { task.cancel() }
        }
    }
}
