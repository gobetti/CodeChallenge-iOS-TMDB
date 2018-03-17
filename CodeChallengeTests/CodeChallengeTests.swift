//
//  CodeChallengeTests.swift
//  CodeChallengeTests
//
//  Created by Marcelo Gobetti on 09/09/17.
//

import XCTest
@testable import CodeChallenge
import Moya
import RxSwift

class TestError: NSError {}

class CodeChallengeTests: XCTestCase {
    var disposeBag: DisposeBag!
    var tmdbModel: TMDBModel!
    
    override func setUp() {
        super.setUp()
        self.disposeBag = DisposeBag()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    /// This test serves as a test for many other things that we can consider
    /// to have already been tested by the underlying frameworks - especially
    /// given Swift's strong typing. For example, if this test succeeds, we
    /// know that:
    /// - we're able to map a raw JSON into an array.
    /// - we're able to map individual JSON chunks into Movie objects.
    func testUpcomingMoviesSampleDataHas20Movies() {
        self.runTestStubbing(expectationDescription: "received stub movies",
                             onSuccess: { XCTAssertEqual($0.count, 20) },
                             onError: { _ in XCTFail() })
    }
    
    func testMoviePrefersPosterWhenPosterAndBackdropAreAvailable() {
        let posterPath = "/9E2y5Q7WlCVNEhP5GiVTjhEhx1o.jpg"
        let backdropPath = "/tcheoA2nPATCm2vvXw2hVQoaEFD.jpg"
        XCTAssertNotEqual(posterPath, backdropPath)
        
        let endpointClosure: MoyaProvider<TMDB>.EndpointClosure = { target in
            self.customEndpoint(for: target, stubbedResponse: "{\"results\":[{\"vote_count\":213,\"id\":346364,\"video\":false,\"vote_average\":7.2,\"title\":\"It\",\"popularity\":139.429699,\"poster_path\":\"\\\(posterPath)\",\"original_language\":\"en\",\"original_title\":\"It\",\"genre_ids\":[27],\"backdrop_path\":\"\\\(backdropPath)\",\"adult\":false,\"release_date\":\"2017-08-17\"}],\"page\":1,\"total_results\":185,\"dates\":{\"maximum\":\"2017-10-04\",\"minimum\":\"2017-09-16\"},\"total_pages\":10}")
        }
        
        self.runTestStubbing(endpointClosure: endpointClosure,
                             expectationDescription: "empty response",
                             onSuccess: {
                                guard let movie = $0.first else { return XCTFail() }
                                XCTAssertEqual(movie.imagePath, posterPath)
        }, onError: { _ in XCTFail() })
    }
    
    func testMovieReadsBackdropWhenPosterIsUnavailable() {
        let backdropPath = "/tcheoA2nPATCm2vvXw2hVQoaEFD.jpg"
        
        let endpointClosure: MoyaProvider<TMDB>.EndpointClosure = { target in
            self.customEndpoint(for: target, stubbedResponse: "{\"results\":[{\"vote_count\":213,\"id\":346364,\"video\":false,\"vote_average\":7.2,\"title\":\"It\",\"popularity\":139.429699,\"original_language\":\"en\",\"original_title\":\"It\",\"genre_ids\":[27],\"backdrop_path\":\"\\\(backdropPath)\",\"adult\":false,\"release_date\":\"2017-08-17\"}],\"page\":1,\"total_results\":185,\"dates\":{\"maximum\":\"2017-10-04\",\"minimum\":\"2017-09-16\"},\"total_pages\":10}")
        }
        
        self.runTestStubbing(endpointClosure: endpointClosure,
                             expectationDescription: "empty response",
                             onSuccess: {
                                guard let movie = $0.first else { return XCTFail() }
                                XCTAssertEqual(movie.imagePath, backdropPath)
        }, onError: { _ in XCTFail() })
    }
    
    func testUpcomingMoviesErrorsOutOnNetworkError() {
        let endpointClosure: MoyaProvider<TMDB>.EndpointClosure = { target in
            return Endpoint(url: target.baseURL.absoluteString, sampleResponseClosure: {
                return .networkError(TestError())
            }, task: target.task)
        }
        
        self.runTestStubbing(endpointClosure: endpointClosure,
                             expectationDescription: "network error",
                             onSuccess: { _ in XCTFail() })
    }
    
    func testUpcomingMoviesErrorsOutOnEmptyResponse() {
        let endpointClosure: MoyaProvider<TMDB>.EndpointClosure = { target in
            self.customEndpoint(for: target, stubbedResponse: "")
        }
        
        self.runTestStubbing(endpointClosure: endpointClosure,
                             expectationDescription: "empty response",
                             onSuccess: { _ in XCTFail() })
    }
    
    func testImage() {
        let movieJSONString = "{\"vote_count\":213,\"id\":346364,\"video\":false,\"vote_average\":7.2,\"title\":\"It\",\"popularity\":139.429699,\"poster_path\":\"\\/9E2y5Q7WlCVNEhP5GiVTjhEhx1o.jpg\",\"original_language\":\"en\",\"original_title\":\"It\",\"genre_ids\":[27],\"backdrop_path\":\"\\/tcheoA2nPATCm2vvXw2hVQoaEFD.jpg\",\"adult\":false,\"release_date\":\"2017-08-17\"}"
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .formatted(Movie.dateFormatter)
        let movie = try! decoder.decode(Movie.self, from: movieJSONString.data(using: .utf8)!)
        
        let thisExpectation = expectation(description: "received stub image")
        let imageWidth = 300
        
        self.tmdbModel = TMDBModel(imageClosures: MoyaClosures<TMDBImage>(endpointClosure: MoyaProvider<TMDBImage>.defaultEndpointMapping,
                                                                          stubClosure: MoyaProvider<TMDBImage>.immediatelyStub))
        
        self.tmdbModel.image(width: imageWidth, from: movie).subscribe { event in
            switch event {
            case let .success(image):
                XCTAssertEqual(image?.size.width, CGFloat(imageWidth))
            case let .error(error):
                XCTFail(error.localizedDescription)
            }
            thisExpectation.fulfill()
            }.disposed(by: self.disposeBag)
        
        waitForExpectations(timeout: 1.0) { error in
            XCTAssertNil(error)
        }
    }
    
    private func runTestStubbing(endpointClosure: @escaping MoyaProvider<TMDB>.EndpointClosure = MoyaProvider<TMDB>.defaultEndpointMapping,
                                 stubClosure: MoyaProvider<TMDB>.StubClosure = MoyaProvider<TMDB>.immediatelyStub,
                                 expectationDescription: String,
                                 onSuccess: (([Movie]) -> ())? = nil,
                                 onError: ((Error) -> ())? = nil) {
        self.tmdbModel = TMDBModel(moviesClosures: MoyaClosures<TMDB>(endpointClosure: endpointClosure,
                                                                      stubClosure: MoyaProvider<TMDB>.immediatelyStub))
        let thisExpectation = expectation(description: expectationDescription)
        
        self.tmdbModel.upcomingMovies().subscribe { event in
            switch event {
            case let .success(movies):
                onSuccess?(movies)
            case let .error(error):
                onError?(error)
            }
            thisExpectation.fulfill()
            }.disposed(by: self.disposeBag)
        
        waitForExpectations(timeout: 1.0) { error in
            XCTAssertNil(error)
        }
    }
    
    private func customEndpoint<T: TargetType>(for target: T, stubbedResponse: String) -> Endpoint<T> {
        return Endpoint(url: target.baseURL.absoluteString,
                        sampleResponseClosure: { .networkResponse(200, stubbedResponse.data(using: .utf8)!) },
                        task: target.task)
    }
}
