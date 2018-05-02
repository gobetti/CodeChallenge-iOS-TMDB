//
//  MoviesListViewModelTests.swift
//  CodeChallengeTests
//
//  Created by Marcelo Gobetti on 4/04/18.
//

import XCTest
@testable import CodeChallenge
import RxSwift
import RxTest

class MoviesListViewModelTests: XCTestCase {
    var disposeBag: DisposeBag!
    var scheduler: TestScheduler!
    
    func expectedResultsCount(for request: TMDB) -> Int {
        switch request {
        case .search: return 18
        case .upcomingMovies(let page):
            if page == 2 { return 19 }
            return 20
        }
    }
    
    override func setUp() {
        super.setUp()
        disposeBag = DisposeBag()
        scheduler = TestScheduler(initialClock: 0, simulateProcessingDelay: false)
    }
    
    func testFirstPageIsReturnedBeforeAnyUserEvent() {
        let tmdbModel = self.makeTMDBModel()
        
        let pageRequester = Observable<Void>.never()
        let searchRequester = Observable<String>.never()
        let debounceTime = 2
        
        let events = simulatedMoviesCountEvents(pageRequester: pageRequester,
                                                searchRequester: searchRequester,
                                                debounceTime: debounceTime,
                                                tmdbModel: tmdbModel)
        let expected = [
            next(debounceTime, expectedResultsCount(for: .upcomingMovies(page: 1)))
        ]
        XCTAssertEqual(events, expected)
    }
    
    func testEmptyListIsReturnedOnNetworkError() {
        let stub = Stub.error(TestError.someError)
        let tmdbModel = self.makeTMDBModel(stubBehavior: .immediate(stub: stub))
        
        let pageRequester = Observable<Void>.never()
        let searchRequester = Observable<String>.never()
        let debounceTime = 2
        
        let events = simulatedMoviesCountEvents(pageRequester: pageRequester,
                                                searchRequester: searchRequester,
                                                debounceTime: debounceTime,
                                                tmdbModel: tmdbModel)
        let expected = [
            next(debounceTime, 0)
        ]
        XCTAssertEqual(events, expected)
    }
    
    func testSearchResultsReplaceUpcomingMoviesWhenUserSearches() {
        let tmdbModel = self.makeTMDBModel()
        
        let searchTime = 100
        let pageRequester = Observable<Void>.never()
        let searchRequester = scheduler.createHotObservable([
            next(searchTime, "abc")
            ])
        let debounceTime = 2
        XCTAssertGreaterThan(searchTime, debounceTime,
                             "This test is not meant to work for a searchTime <= debounceTime")
        
        let events = simulatedMoviesCountEvents(pageRequester: pageRequester,
                                                searchRequester: searchRequester.asObservable(),
                                                debounceTime: debounceTime,
                                                tmdbModel: tmdbModel)
        let expected = [
            next(debounceTime, expectedResultsCount(for: .upcomingMovies(page: 1))),
            next(searchTime + debounceTime, expectedResultsCount(for: .search(query: "abc", page: 1)))
        ]
        XCTAssertEqual(events, expected)
    }
    
    func testUpcomingMoviesReplaceSearchResultsWhenUserClearsQuery() {
        let tmdbModel = self.makeTMDBModel()
        
        let searchTime = 100
        let searchClearTime = 200
        let pageRequester = Observable<Void>.never()
        let searchRequester = scheduler.createHotObservable([
            next(searchTime, "abc"),
            next(searchClearTime, "")
            ])
        let debounceTime = 2
        XCTAssertGreaterThan(searchTime, debounceTime,
                             "This test is not meant to work for a searchTime <= debounceTime")
        XCTAssertGreaterThan(searchClearTime, searchTime,
                             "This test is not meant to work for a searchClearTime <= searchTime")
        
        let events = simulatedMoviesCountEvents(pageRequester: pageRequester,
                                                searchRequester: searchRequester.asObservable(),
                                                debounceTime: debounceTime,
                                                tmdbModel: tmdbModel)
        
        let expectedResultsCount1 = expectedResultsCount(for: .upcomingMovies(page: 1))
        
        let expected = [
            next(debounceTime, expectedResultsCount1),
            next(searchTime + debounceTime, expectedResultsCount(for: .search(query: "abc", page: 1))),
            next(searchClearTime + debounceTime, expectedResultsCount1)
        ]
        XCTAssertEqual(events, expected)
    }
    
    func testSecondPageIsAppendedWhenUserPaginates() {
        let tmdbModel = self.makeTMDBModel()
        
        let paginationTime = 100
        let pageRequester = scheduler.createHotObservable([
            next(paginationTime, ())
            ])
        let searchRequester = Observable<String>.never()
        let debounceTime = 2
        XCTAssertGreaterThan(paginationTime, debounceTime,
                             "This test is not meant to work for a paginationTime <= debounceTime")
        
        let events = simulatedMoviesCountEvents(pageRequester: pageRequester.asObservable(),
                                                searchRequester: searchRequester,
                                                debounceTime: debounceTime,
                                                tmdbModel: tmdbModel)
        
        let expectedResultsCount1 = expectedResultsCount(for: .upcomingMovies(page: 1))
        let expectedResultsCount2 = expectedResultsCount1 + expectedResultsCount(for: .upcomingMovies(page: 2))
        
        let expected = [
            next(debounceTime, expectedResultsCount1),
            next(paginationTime, expectedResultsCount2)
        ]
        XCTAssertEqual(events, expected)
    }
    
    func testLoadingStartsOnRequestAndStopsWhenDone() {
        let integerResponseDelay = 5
        let responseDelay = TimeInterval(integerResponseDelay)
        let tmdbModel = self.makeTMDBModel(stubBehavior: .delayed(time: responseDelay, stub: .default))
        
        let pageRequester = Observable<Void>.never()
        let searchRequester = Observable<String>.never()
        let debounceTime = 2
        
        let viewModel = MoviesListViewModel(pageRequester: pageRequester,
                                            searchRequester: searchRequester,
                                            tmdbModel: tmdbModel,
                                            debounceTime: RxTimeInterval(debounceTime),
                                            scheduler: self.scheduler)
        
        let results = scheduler.createObserver(Bool.self)
        
        scheduler.scheduleAt(0) {
            viewModel.isLoadingDriver
                .drive(results).disposed(by: self.disposeBag)
            
            // At least 1 subscriber is needed:
            viewModel.moviesDriver.drive().disposed(by: self.disposeBag)
        }
        scheduler.start()
        
        let expected = [
            next(0, false),
            next(debounceTime, true),
            next(debounceTime + integerResponseDelay, false)
        ]
        XCTAssertEqual(results.events, expected)
    }
    
    private func makeTMDBModel(stubBehavior: StubBehavior = .immediate(stub: .default)) -> TMDBModel {
        return TMDBModel(stubBehavior: stubBehavior, scheduler: self.scheduler)
    }
    
    private func simulatedMoviesCountEvents(pageRequester: Observable<Void>,
                                            searchRequester: Observable<String>,
                                            debounceTime: Int,
                                            tmdbModel: TMDBModel)
        -> [Recorded<Event<Int>>] {
            let viewModel = MoviesListViewModel(pageRequester: pageRequester,
                                                searchRequester: searchRequester,
                                                tmdbModel: tmdbModel,
                                                debounceTime: RxTimeInterval(debounceTime),
                                                scheduler: self.scheduler)
            
            let results = scheduler.createObserver(Int.self)
            
            scheduler.scheduleAt(0) {
                viewModel.moviesDriver.map { $0.count }
                    .drive(results).disposed(by: self.disposeBag)
            }
            scheduler.start()
            
            return results.events
    }
}
