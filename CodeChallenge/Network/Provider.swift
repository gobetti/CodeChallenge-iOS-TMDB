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
    private let disposeBag = DisposeBag()
    
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
        let task = MockURLSessionDataTask()
        
        guard let url = request.url else {
            print("Invalid URL when mocking URLSession")
            return task
        }
        
        let completion = {
            switch self.stub {
            case .success(let response):
                completionHandler(response.data,
                                  HTTPURLResponse(url: url,
                                                  statusCode: response.statusCode,
                                                  httpVersion: nil,
                                                  headerFields: nil),
                                  nil)
            case .error(let error):
                completionHandler(nil, nil, error)
            case .default:
                fatalError("Unhandled default stub")
            }
        }
        
        guard delay > 0 else {
            completion()
            return task
        }
        
        let scheduledObservable = Completable.create { event in
            return self.scheduler.scheduleRelative((), dueTime: self.delay) { _ in
                completion()
                event(.completed)
                return Disposables.create { task.cancel() }
            }
        }
        
        _ = task.didStartRunning
            .andThen(scheduledObservable)
            .subscribe().disposed(by: disposeBag)
        
        return task
    }
}

private enum MockURLSessionDataTaskError: Error {
    case cancelled
}

private final class MockURLSessionDataTask: URLSessionDataTask {
    private let lock = NSRecursiveLock()
    
    private let isCancelled = BehaviorRelay(value: false)
    private let isRunning = BehaviorSubject(value: false)
    
    var didStartRunning: Completable {
        return Completable.create { event in
            self.isRunning.filter { $0 }.take(1).subscribe(onCompleted: {
                event(.completed)
            })
        }
    }
    
    override func cancel() {
        lock.lock()
        self.isCancelled.accept(true)
        self.isRunning.onError(MockURLSessionDataTaskError.cancelled)
        lock.unlock()
    }
    
    override func resume() {
        lock.lock()
        self.isRunning.onNext(true)
        lock.unlock()
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
