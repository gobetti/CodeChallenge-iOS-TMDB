//
//  URLSessionProtocol.swift
//  CodeChallenge
//
//  Created by Marcelo Gobetti on 4/23/18.
//

import Foundation

protocol URLSessionProtocol {
    func dataTask(with request: URLRequest, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> URLSessionDataTask
}

extension URLSession: URLSessionProtocol {}
