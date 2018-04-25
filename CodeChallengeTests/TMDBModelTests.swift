//
//  TMDBModelTests.swift
//  CodeChallengeTests
//
//  Created by Marcelo Gobetti on 09/09/17.
//

import XCTest
@testable import CodeChallenge
import RxSwift
import RxTest

class TMDBModelTests: XCTestCase {
    var disposeBag: DisposeBag!
    var scheduler: TestScheduler!
    let initialTime = 0
    
    override func setUp() {
        super.setUp()
        self.disposeBag = DisposeBag()
        self.scheduler = TestScheduler(initialClock: 0)
    }
    
    /// This test serves as a test for many other things that we can consider
    /// to have already been tested by the underlying frameworks - especially
    /// given Swift's strong typing. For example, if this test succeeds, we
    /// know that:
    /// - we're able to map a raw JSON into an array.
    /// - we're able to map individual JSON chunks into Movie objects.
    func testUpcomingMoviesSampleDataHas20Movies() {
        let events = self.simulatedEvents().map {
            $0.map { $0.movies.count }
        }
        
        let expected = [
            next(self.initialTime, 20),
            completed(self.initialTime)
        ]
        
        XCTAssertEqual(events, expected)
    }
    
    func testMoviePrefersPosterWhenPosterAndBackdropAreAvailable() {
        let posterPath = "/9E2y5Q7WlCVNEhP5GiVTjhEhx1o.jpg"
        let backdropPath = "/tcheoA2nPATCm2vvXw2hVQoaEFD.jpg"
        XCTAssertNotEqual(posterPath, backdropPath)
        
        let stub = self.customSuccessStub(stubbedResponse: "{\"results\":[{\"vote_count\":213,\"id\":346364,\"video\":false,\"vote_average\":7.2,\"title\":\"It\",\"popularity\":139.429699,\"poster_path\":\"\\\(posterPath)\",\"original_language\":\"en\",\"original_title\":\"It\",\"genre_ids\":[27],\"backdrop_path\":\"\\\(backdropPath)\",\"adult\":false,\"release_date\":\"2017-08-17\"}],\"page\":1,\"total_results\":185,\"dates\":{\"maximum\":\"2017-10-04\",\"minimum\":\"2017-09-16\"},\"total_pages\":10}")
        let events = self.simulatedEvents(stubBehavior: .immediate(stub: stub)).map {
            $0.map { $0.movies.first?.imagePath }
        }
        
        let expected = [
            next(self.initialTime, Optional(posterPath)),
            completed(self.initialTime)
        ]
        
        XCTAssertEqual(events, expected)
    }
    
    func testMovieReadsBackdropWhenPosterIsUnavailable() {
        let backdropPath = "/tcheoA2nPATCm2vvXw2hVQoaEFD.jpg"
        let stub = self.customSuccessStub(stubbedResponse: "{\"results\":[{\"vote_count\":213,\"id\":346364,\"video\":false,\"vote_average\":7.2,\"title\":\"It\",\"popularity\":139.429699,\"original_language\":\"en\",\"original_title\":\"It\",\"genre_ids\":[27],\"backdrop_path\":\"\\\(backdropPath)\",\"adult\":false,\"release_date\":\"2017-08-17\"}],\"page\":1,\"total_results\":185,\"dates\":{\"maximum\":\"2017-10-04\",\"minimum\":\"2017-09-16\"},\"total_pages\":10}")
        let events = self.simulatedEvents(stubBehavior: .immediate(stub: stub)).map {
            $0.map { $0.movies.first?.imagePath }
        }
        
        let expected = [
            next(self.initialTime, Optional(backdropPath)),
            completed(self.initialTime)
        ]
        
        XCTAssertEqual(events, expected)
    }
    
    func testUpcomingMoviesErrorsOutOnNetworkError() {
        let stub = Stub.error(TestError.someError)
        let events = self.simulatedEvents(stubBehavior: .immediate(stub: stub))
        XCTAssertThrowsError(events)
    }
    
    func testUpcomingMoviesErrorsOutOnEmptyResponse() {
        let stub = self.customSuccessStub(stubbedResponse: "")
        let events = self.simulatedEvents(stubBehavior: .immediate(stub: stub))
        XCTAssertThrowsError(events)
    }
    
    func testMoviesAreValidIfOneOrSomeFail() {
        let events = self.simulatedEvents(page: 2).map {
            $0.map { $0.movies.count }
        }
        
        let expected = [
            next(self.initialTime, 19),
            completed(self.initialTime)
        ]
        
        XCTAssertEqual(events, expected)
    }
    
    func testImage() {
        let movieJSONString = "{\"vote_count\":213,\"id\":346364,\"video\":false,\"vote_average\":7.2,\"title\":\"It\",\"popularity\":139.429699,\"poster_path\":\"\\/9E2y5Q7WlCVNEhP5GiVTjhEhx1o.jpg\",\"original_language\":\"en\",\"original_title\":\"It\",\"genre_ids\":[27],\"backdrop_path\":\"\\/tcheoA2nPATCm2vvXw2hVQoaEFD.jpg\",\"adult\":false,\"release_date\":\"2017-08-17\"}"
        let movie = try! TMDBResults.decoder.decode(Movie.self, from: movieJSONString.data(using: .utf8)!)
        let imageWidth = 300
        
        let tmdbModel = TMDBModel(stubBehavior: .immediate(stub: .default), scheduler: scheduler)
        let results = scheduler.createObserver(UIImage.self)
        
        scheduler.scheduleAt(self.initialTime) {
            tmdbModel.image(width: imageWidth, from: movie).asObservable()
                .subscribe(results).disposed(by: self.disposeBag)
        }
        scheduler.start()
        
        let events = results.events.map {
            $0.map { $0.size.width }
        }
        
        let expected = [
            next(self.initialTime, CGFloat(imageWidth)),
            completed(self.initialTime)
        ]
        
        XCTAssertEqual(events, expected)
    }
    
    private func simulatedEvents(page: Int = 1,
                                 stubBehavior: StubBehavior = .immediate(stub: .default))
        -> [Recorded<Event<TMDBResults>>] {
            let tmdbModel = TMDBModel(stubBehavior: stubBehavior, scheduler: scheduler)
            let results = scheduler.createObserver(TMDBResults.self)
            
            scheduler.scheduleAt(self.initialTime) {
                tmdbModel.upcomingMovies(page: page).asObservable()
                    .subscribe(results).disposed(by: self.disposeBag)
            }
            scheduler.start()
            
            return results.events
    }
    
    private func customSuccessStub(stubbedResponse: String) -> Stub {
        return Stub.success(Response(200, stubbedResponse.data(using: .utf8)!))
    }
}
