//
//  ObservableExtensionsTests.swift
//  CodeChallengeTests
//
//  Created by Marcelo Gobetti on 4/18/18.
//

import XCTest
@testable import CodeChallenge
import RxCocoa
import RxSwift
import RxTest

enum TestError: Error {
    case someError
}

class ObservableExtensionsTests: XCTestCase {
    var disposeBag: DisposeBag!
    var scheduler: TestScheduler!
    
    override func setUp() {
        super.setUp()
        self.disposeBag = DisposeBag()
        self.scheduler = TestScheduler(initialClock: 0)
    }
    
    // MARK: - takeWhileInclusive
    func testTakeWhileInclusiveIncludesFirstEventThatFailsConditionThenCompletes() {
        let results = scheduler.createObserver(Int.self)
        
        scheduler.scheduleAt(0) {
            Observable.of(1, 2, 3)
                .takeWhileInclusive { $0 < 2 }
                .subscribe(results).disposed(by: self.disposeBag)
        }
        scheduler.start()
        
        let expected = [
            next(0, 1),
            next(0, 2),
            completed(0)
        ]
        XCTAssertEqual(results.events, expected)
    }
    
    func testTakeWhileInclusiveDoesNotDuplicateSubscription() {
        let results = scheduler.createObserver(Int.self)
        
        scheduler.scheduleAt(0) {
            var count = 0
            Observable.just(()) // single event emitted
                .do(onNext: {
                    count += 1
                })
                .takeWhileInclusive { count < 2 }
                .map { _ in count }
                .subscribe(results).disposed(by: self.disposeBag)
        }
        scheduler.start()
        
        let expected = [
            next(0, 1), // single event emitted
            completed(0)
        ]
        XCTAssertEqual(results.events, expected)
    }
    
    func testTakeWhileInclusiveClearsResourcesOnSelfDisposal() {
        let subject = PublishSubject<Void>()
        let previousResourcesCount = RxSwift.Resources.total
        
        var count = 0
        _ = subject
            .do(onNext: {
                count += 1
            })
            .takeWhileInclusive { count < 1 }
            .subscribe()
        subject.onNext(())
        
        XCTAssertEqual(previousResourcesCount, RxSwift.Resources.total)
    }
    
    func testTakeWhileInclusiveClearsResourcesOnManualDisposal() {
        let subject = PublishSubject<Void>()
        let previousResourcesCount = RxSwift.Resources.total
        
        var count = 0
        
        func localScope() {
            // scoped so that the `subscription` itself is not only disposed but also deallocated
            let subscription = subject
                .do(onNext: {
                    count += 1
                })
                .takeWhileInclusive { count < 2 }
                .subscribe()
            subject.onNext(())
            subscription.dispose()
        }
        localScope()
        
        XCTAssertEqual(previousResourcesCount, RxSwift.Resources.total)
    }
    
    // MARK: - asDriver(onErrorJustReturn:)
    func testDriverReturnsOriginalValueIfNoError() {
        let results = scheduler.createObserver(Int.self)
        let expectedValue = 1
        
        scheduler.scheduleAt(0) {
            Observable.just(expectedValue)
                .asDriver(onErrorLogAndReturn: expectedValue)
                .drive(results).disposed(by: self.disposeBag)
        }
        scheduler.start()
        
        let expected = [
            next(0, expectedValue),
            completed(0)
        ]
        XCTAssertEqual(results.events, expected)
    }
    
    func testDriverReturnsSpecifiedValueOnError() {
        let results = scheduler.createObserver(Int.self)
        let expectedValue = 1
        
        scheduler.scheduleAt(0) {
            Observable<Int>.error(TestError.someError)
                .asDriver(onErrorLogAndReturn: expectedValue)
                .drive(results).disposed(by: self.disposeBag)
        }
        scheduler.start()
        
        let expected = [
            next(0, expectedValue),
            completed(0)
        ]
        XCTAssertEqual(results.events, expected)
    }
}
