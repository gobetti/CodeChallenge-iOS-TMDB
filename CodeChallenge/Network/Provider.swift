//
//  Provider.swift
//  CodeChallenge
//
//  Created by Marcelo Gobetti on 4/23/18.
//

import Foundation
import RxCocoa
import RxSwift

enum ProviderError: Error {
    case invalidResponse
    case invalidURL
}

/// The different types of stub, where `default` falls back to the `TargetType`'s `sampleData`.
enum Stub {
    case `default`
    case success(Data)
    case error(Error)
}

/// The different stubbing modes.
enum StubBehavior {
    /// Stubs and delays the response for a specified amount of time.
    case delayed(time: TimeInterval, stub: Stub)
    
    /// Stubs the response without delaying it.
    case immediate(stub: Stub)
    
    /// Does not stub the response.
    case never
}

/// A self-mockable network data requester.
final class Provider<Target: TargetType> {
    private let stubBehavior: StubBehavior
    private let scheduler: SchedulerType
    
    init(stubBehavior: StubBehavior = .never,
         scheduler: SchedulerType = ConcurrentDispatchQueueScheduler(qos: .background)) {
        self.stubBehavior = stubBehavior
        self.scheduler = scheduler
    }
    
    public func request(_ target: Target) -> Single<Data> {
        guard let url = URL(string: target.baseURL.absoluteString + target.path) else {
            return .error(ProviderError.invalidURL)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = target.method.rawValue
        request.allHTTPHeaderFields = target.headers
        
        switch target.task {
        case .requestParameters(let parameters):
            request = request.addingParameters(parameters)
        case .requestPlain: break
        }
        
        return target.makeURLSession(stubBehavior: self.stubBehavior, scheduler: self.scheduler)
            .data(request: request).asSingle()
    }
}

// MARK: - Private
// Entities and methods that are not supposed to be used outside a Provider
private struct ReactiveURLSessionMock: ReactiveURLSessionProtocol {
    private let stub: Stub
    private let scheduler: SchedulerType
    private let delay: TimeInterval
    
    init(stub: Stub, scheduler: SchedulerType, delay: TimeInterval = 0) {
        self.stub = stub
        self.scheduler = scheduler
        self.delay = delay
    }
    
    func data(request: URLRequest) -> Observable<Data> {
        switch self.stub {
        case .success(let data):
            let immediateResponse = Observable.just(data)
            guard self.delay > 0 else { return immediateResponse }
            return immediateResponse.delay(self.delay, scheduler: self.scheduler)
        case .error(let error):
            return .error(error)
        case .default:
            fatalError("Unhandled default stub")
        }
    }
}

private extension TargetType {
    func makeURLSession(stubBehavior: StubBehavior,
                        scheduler: SchedulerType) -> ReactiveURLSessionProtocol {
        switch stubBehavior {
        case .delayed(let time, let stub):
            return ReactiveURLSessionMock(stub: makeStub(from: stub), scheduler: scheduler, delay: time)
        case .immediate(let stub):
            return ReactiveURLSessionMock(stub: makeStub(from: stub), scheduler: scheduler)
        case .never:
            return URLSession.shared.rx
        }
    }
    
    func makeStub(from baseStub: Stub) -> Stub {
        switch baseStub {
        case .default:
            return Stub.success(self.sampleData)
        case .error, .success:
            return baseStub
        }
    }
}
