//
//  URLSessionProtocol.swift
//  CodeChallenge
//
//  Created by Marcelo Gobetti on 4/23/18.
//

import RxCocoa
import RxSwift

protocol ReactiveURLSessionProtocol {
    func data(request: URLRequest) -> Observable<Data>
}

extension Reactive: ReactiveURLSessionProtocol where Base: URLSession {}
