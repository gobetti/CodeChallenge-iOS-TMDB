//
//  MoviesListViewModelTests.swift
//  CodeChallengeTests
//
//  Created by Marcelo Gobetti on 4/04/18.
//

import XCTest
@testable import CodeChallenge
import Moya // may be removed if we decide to have our own mock without going through Moya
import RxSwift
import RxTest

class MoviesListViewModelTests: XCTestCase {
    var disposeBag: DisposeBag!
    var scheduler: TestScheduler!
    
    func expectedResultsCount(for request: TMDB) -> Int {
        switch request {
        case .search: return 18
        case .upcomingMovies: return 20
        }
    }
    
    override func setUp() {
        super.setUp()
        disposeBag = DisposeBag()
        scheduler = TestScheduler(initialClock: 0)
    }
    
    func testFirstPageIsReturnedBeforeAnyUserEvent() {
        let tmdbModel = TMDBModel(moviesClosures: MoyaClosures<TMDB>(endpointClosure: MoyaProvider<TMDB>.defaultEndpointMapping,
                                                                     stubClosure: MoyaProvider<TMDB>.immediatelyStub))
        
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
        let endpointClosure: MoyaProvider<TMDB>.EndpointClosure = { target in
            return Endpoint(url: target.baseURL.absoluteString, sampleResponseClosure: {
                return .networkError(TestError.someError as NSError)
            }, method: .get, task: target.task, httpHeaderFields: [:])
        }
        let tmdbModel = TMDBModel(moviesClosures: MoyaClosures<TMDB>(endpointClosure: endpointClosure,
                                                                     stubClosure: MoyaProvider<TMDB>.immediatelyStub))
        
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
        let tmdbModel = TMDBModel(moviesClosures: MoyaClosures<TMDB>(endpointClosure: MoyaProvider<TMDB>.defaultEndpointMapping,
                                                                     stubClosure: MoyaProvider<TMDB>.immediatelyStub))
        
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
        let tmdbModel = TMDBModel(moviesClosures: MoyaClosures<TMDB>(endpointClosure: MoyaProvider<TMDB>.defaultEndpointMapping,
                                                                     stubClosure: MoyaProvider<TMDB>.immediatelyStub))
        
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
    
    private func simulatedMoviesCountEvents(pageRequester: Observable<Void>,
                                            searchRequester: Observable<String>,
                                            debounceTime: Int,
                                            tmdbModel: TMDBModel)
        -> [Recorded<Event<Int>>] {
            let viewModel = MoviesListViewModel(pageRequester: pageRequester,
                                                searchRequester: searchRequester,
                                                debounceTime: RxTimeInterval(debounceTime),
                                                scheduler: self.scheduler,
                                                tmdbModel: tmdbModel)
            
            let results = scheduler.createObserver(Int.self)
            
            scheduler.scheduleAt(0) {
                viewModel.moviesDriver.map { $0.count }
                    .drive(results).disposed(by: self.disposeBag)
            }
            scheduler.start()
            
            return results.events
    }
}
