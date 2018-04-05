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
        
        let expected = [
            next(debounceTime, 20)
        ]
        XCTAssertEqual(results.events, expected)
    }
}
