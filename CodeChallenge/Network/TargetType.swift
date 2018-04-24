//
//  TargetType.swift
//  CodeChallenge
//
//  Created by Marcelo Gobetti on 4/23/18.
//

import Foundation

enum HTTPMethod: String {
    case get = "GET"
}

/// Inspired by Moya
/// https://github.com/Moya/Moya/blob/master/Sources/Moya/Task.swift
enum Task {
    /// A request sent with encoded parameters.
    case requestParameters(parameters: [String: String])
    
    /// A request with no additional data.
    case requestPlain
}

/// Defines the contract for API models that are able to provide stubs by themselves.
/// Intentionally mimics Moya.TargetType very closely in order to keep compatibility.
/// https://github.com/Moya/Moya/blob/master/Sources/Moya/TargetType.swift
protocol TargetType {
    /// The target's base `URL`.
    var baseURL: URL { get }
    
    /// The path to be appended to `baseURL` to form the full `URL`.
    var path: String { get }
    
    /// The HTTP method used in the request.
    var method: HTTPMethod { get }
    
    /// Provides stub data for use in testing.
    var sampleData: Data { get }
    
    /// The type of HTTP task to be performed.
    var task: Task { get }
    
    /// The headers to be used in the request.
    var headers: [String: String]? { get }
}
