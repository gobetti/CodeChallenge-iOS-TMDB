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
    case success(Response)
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
    private var urlSession: URLSessionProtocol!
    
    private let stubBehavior: StubBehavior
    private let scheduler: SchedulerType
    
    init(stubBehavior: StubBehavior = .never,
         scheduler: SchedulerType = ConcurrentDispatchQueueScheduler(qos: .background)) {
        self.stubBehavior = stubBehavior
        self.scheduler = scheduler
    }
    
    public func request(_ target: Target) -> Single<Response> {
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
        
        self.urlSession = target.makeURLSession(stubBehavior: self.stubBehavior,
                                                scheduler: self.scheduler)
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

// MARK: - Private
// Entities and methods that are not supposed to be used outside a Provider
private struct MockURLSession: URLSessionProtocol {
    private let stub: Stub
    private let delay: TimeInterval
    private let scheduler: SchedulerType
    
    init(stub: Stub,
         delay: TimeInterval = 0,
         scheduler: SchedulerType = ConcurrentDispatchQueueScheduler(qos: .background)) {
        self.stub = stub
        self.delay = delay
        self.scheduler = scheduler
    }
    
    func dataTask(with request: URLRequest, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> URLSessionDataTask {
        let completion: MockURLSessionDataTask.Completion = { error in
            switch self.stub {
            case .success(let response):
                completionHandler(response.data,
                                  HTTPURLResponse(url: request.url!,
                                                  statusCode: response.statusCode,
                                                  httpVersion: nil,
                                                  headerFields: nil),
                                  error)
            case .error(let error):
                completionHandler(nil, nil, error)
            case .default:
                fatalError("Unhandled default stub")
            }
        }
        
        return MockURLSessionDataTask(completion: completion,
                                      delay: self.delay,
                                      scheduler: self.scheduler)
    }
}

private enum MockURLSessionDataTaskError: Error {
    case cancelled
}

final class MockURLSessionDataTask: URLSessionDataTask {
    typealias Completion = (Error?) -> ()
    
    private let completion: Completion
    private let delay: TimeInterval
    private let scheduler: SchedulerType
    
    private let isRunning = PublishSubject<Bool>()
    private var scheduledSubscription: Disposable!
    
    init(completion: @escaping Completion, delay: TimeInterval, scheduler: SchedulerType) {
        self.completion = completion
        self.delay = delay
        self.scheduler = scheduler
        super.init()
        
        let scheduleCompletion = Completable.create { [weak self] event in
            guard let strongSelf = self else { return Disposables.create() }
            
            guard strongSelf.delay > 0 else {
                strongSelf.complete()
                event(.completed)
                return Disposables.create()
            }
            
            return strongSelf.scheduler.scheduleRelative((), dueTime: strongSelf.delay) { _ in
                self?.complete()
                event(.completed)
                return Disposables.create { self?.cancel() }
            }
        }
        
        scheduledSubscription = self.isRunning.filter { $0 }.take(1)
            .flatMap { _ in scheduleCompletion }
            .subscribe()
    }
    
    override func cancel() {
        _ = self.scheduler.schedule(()) { _ in
            self.complete(withError: MockURLSessionDataTaskError.cancelled)
            return Disposables.create()
        }
    }
    
    override func resume() {
        _ = self.scheduler.schedule(()) { _ in
            self.isRunning.onNext(true)
            return Disposables.create()
        }
    }
    
    private func complete(withError error: Error? = nil) {
        _ = self.scheduler.schedule(()) { _ in
            self.isRunning.onCompleted()
            self.scheduledSubscription.dispose()
            self.completion(error)
            return Disposables.create()
        }
    }
}

private extension TargetType {
    func makeURLSession(stubBehavior: StubBehavior,
                        scheduler: SchedulerType) -> URLSessionProtocol {
        switch stubBehavior {
        case .delayed(let time, let stub):
            return MockURLSession(stub: makeStub(from: stub), delay: time, scheduler: scheduler)
        case .immediate(let stub):
            return MockURLSession(stub: makeStub(from: stub))
        case .never:
            return URLSession.shared
        }
    }
    
    func makeStub(from baseStub: Stub) -> Stub {
        switch baseStub {
        case .default:
            return Stub.success(Response(200, self.sampleData))
        case .error, .success:
            return baseStub
        }
    }
}
