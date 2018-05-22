//
//  ProviderTests.swift
//  CodeChallengeTests
//
//  Created by Marcelo Gobetti on 4/24/18.
//

import XCTest
@testable import CodeChallenge
import RxSwift
import RxTest

enum TestError: Error {
    case someError
}

class ProviderTests: XCTestCase {
    var disposeBag: DisposeBag!
    var scheduler: TestScheduler!
    let initialTime = 0
    
    override func setUp() {
        super.setUp()
        self.disposeBag = DisposeBag()
        self.scheduler = TestScheduler(initialClock: 0, simulateProcessingDelay: false)
    }
    
    func testValidURLRequestSucceeds() {
        let events = self.simulatedEvents().map {
            $0.map { $0 }
        }
        let expected = [
            next(self.initialTime, MockTarget.validURL.sampleData),
            completed(self.initialTime)
        ]
        XCTAssertEqual(events, expected)
    }
    
    func testInvalidURLReturnsError() {
        let events = self.simulatedEvents(target: MockTarget.wrongURL)
        XCTAssertThrowsError(events)
    }
    
    func testDelayedStubRespondsAfterDelay() {
        let integerResponseDelay = 5
        let responseDelay = TimeInterval(integerResponseDelay)
        
        let events = self.simulatedEvents(stubBehavior: .delayed(time: responseDelay, stub: .default)).map {
            $0.map { $0 }
        }
        
        let expected = [
            next(integerResponseDelay, MockTarget.validURL.sampleData),
            completed(integerResponseDelay)
        ]
        
        XCTAssertEqual(events, expected)
    }
    
    func testErrorStubReturnsError() {
        let events = self.simulatedEvents(stubBehavior: .immediate(stub: .error(TestError.someError)))
        XCTAssertThrowsError(events)
    }
    
    private func simulatedEvents(stubBehavior: StubBehavior = .immediate(stub: .default),
                                 target: MockTarget = MockTarget.validURL)
        -> [Recorded<Event<Data>>] {
            let provider = Provider<MockTarget>(stubBehavior: stubBehavior, scheduler: self.scheduler)
            let results = scheduler.createObserver(Data.self)
            
            scheduler.scheduleAt(self.initialTime) {
                provider.request(target).asObservable()
                    .subscribe(results).disposed(by: self.disposeBag)
            }
            scheduler.start()
            
            return results.events
    }
    
    // MARK: - Memory
    func testDelayedStubClearsResourcesWhenCancelled() {
        let previousResourcesCount = RxSwift.Resources.total
        let integerResponseDelay = 5
        let responseDelay = TimeInterval(integerResponseDelay)
        
        let cancelTime = 3
        XCTAssertGreaterThan(integerResponseDelay, cancelTime,
                             "This test is not meant to work for a cancelTime <= responseDelay")
        
        func localScope() {
            // scoped so that the `subscription` itself is not only disposed but also deallocated
            let provider = Provider<MockTarget>(stubBehavior: .delayed(time: responseDelay, stub: .default),
                                                scheduler: self.scheduler)
            
            var requestSubscription: Disposable?
            scheduler.scheduleAt(self.initialTime) {
                requestSubscription = provider.request(MockTarget.validURL).asObservable().subscribe()
            }
            scheduler.scheduleAt(cancelTime) {
                XCTAssertLessThan(previousResourcesCount, RxSwift.Resources.total)
                requestSubscription?.dispose()
            }
            scheduler.start()
        }
        localScope()
        
        XCTAssertEqual(previousResourcesCount, RxSwift.Resources.total)
    }
    
    func testDelayedStubClearsResourcesOnceCompleted() {
        let previousResourcesCount = RxSwift.Resources.total
        let integerResponseDelay = 5
        let responseDelay = TimeInterval(integerResponseDelay)
        
        func localScope() {
            // scoped so that the `subscription` itself is not only disposed but also deallocated
            let provider = Provider<MockTarget>(stubBehavior: .delayed(time: responseDelay, stub: .default),
                                                scheduler: self.scheduler)
            
            scheduler.scheduleAt(self.initialTime) {
                _ = provider.request(MockTarget.validURL).asObservable().subscribe()
            }
            scheduler.scheduleAt(integerResponseDelay + 1) {
                XCTAssertEqual(previousResourcesCount + 1, RxSwift.Resources.total,
                               "The only additional resource living after completion should be `scheduleAt`")
            }
            scheduler.start()
        }
        localScope()
        
        XCTAssertEqual(previousResourcesCount, RxSwift.Resources.total)
    }
}

private enum MockTarget: TargetType {
    case validURL
    case wrongURL
    
    var baseURL: URL { return URL(string: "www.foo.com")! }
    
    var path: String {
        switch self {
        case .validURL: return ""
        case .wrongURL: return ")!$%*#"
        }
    }
    
    var method: HTTPMethod { return .get }
    
    var sampleData: Data { return "".data(using: .utf8)! }
    
    var task: Task { return .requestPlain }
    
    var headers: [String : String]? { return [:] }
}
