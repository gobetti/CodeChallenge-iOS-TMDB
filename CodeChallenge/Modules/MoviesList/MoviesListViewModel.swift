//
//  MoviesListViewModel.swift
//  CodeChallenge
//
//  Created by Marcelo Gobetti on 3/18/18.
//

import Moya
import RxCocoa
import RxSwift

struct MoviesListViewModel {
    typealias MoviesCollection = [Movie]
    
    private let disposeBag = DisposeBag()
    private let tmdbModel: TMDBModel
    let moviesDriver: Driver<MoviesCollection>
    
    func image(width: Int, from movie: Movie) -> Single<UIImage?> {
        return self.tmdbModel.image(width: width, from: movie)
    }
    
    // MARK: - Initializers
    init(pageRequester: Observable<Void>,
         searchRequester: Observable<String>,
         tmdbModel: TMDBModel,
         debounceTime: RxTimeInterval = 0.5,
         scheduler: SchedulerType = MainScheduler.instance) {
        self.moviesDriver = MoviesListViewModel.createMoviesDriver(pageRequester: pageRequester,
                                                                   searchRequester: searchRequester,
                                                                   debounceTime: debounceTime,
                                                                   scheduler: scheduler,
                                                                   tmdbModel: tmdbModel)
        self.tmdbModel = tmdbModel
    }
    
    init(pageRequester: Observable<Void>, searchRequester: Observable<String>, uiTesting: Bool = false) {
        let tmdbModel: TMDBModel
        if uiTesting {
            tmdbModel = TMDBModel(imageClosures: MoyaClosures<TMDBImage>(endpointClosure: MoyaProvider<TMDBImage>.defaultEndpointMapping,
                                                                         stubClosure: MoyaProvider<TMDBImage>.immediatelyStub),
                                  moviesClosures: MoyaClosures<TMDB>(endpointClosure: MoyaProvider<TMDB>.defaultEndpointMapping,
                                                                     stubClosure: MoyaProvider<TMDB>.immediatelyStub))
        } else {
            tmdbModel = TMDBModel()
        }
        
        self.init(pageRequester: pageRequester, searchRequester: searchRequester, tmdbModel: tmdbModel)
    }
    
    // MARK: - Private static methods
    private static func createRequest(query: String, page: Int, tmdbModel: TMDBModel) -> Single<TMDBResults> {
        guard !query.isEmpty else { return tmdbModel.upcomingMovies(page: page) }
        return tmdbModel.search(query: query, page: page)
    }
    
    private static func createMoviesDriver(pageRequester: Observable<Void>,
                                           searchRequester: Observable<String>,
                                           debounceTime: RxTimeInterval,
                                           scheduler: SchedulerType,
                                           tmdbModel: TMDBModel)
        -> Driver<MoviesCollection> {
        let paginator = { (query: String) -> Observable<MoviesCollection> in
            var fetchedPages = 0
            var nextPage: Int {
                return fetchedPages + 1
            }
            
            return pageRequester.startWith(())
                .flatMapFirst { _ in
                    return MoviesListViewModel.createRequest(query: query, page: nextPage, tmdbModel: tmdbModel)
                        .do(onSuccess: { _ in fetchedPages += 1 })
                        .catchError {
                            print("Error: \($0)")
                            return Single.just(TMDBResults(movies: [], totalPages: Int.max))
                    }
                }.takeWhileInclusive { fetchedPages < $0.totalPages }
                .map { $0.movies }
                .scan(MoviesCollection()) { (accumulatedMovies, newMovies) -> MoviesCollection in
                    return accumulatedMovies + newMovies
            }
        }
        
        return searchRequester.startWith("")
            .debounce(debounceTime, scheduler: scheduler)
            .distinctUntilChanged()
            .flatMapLatest { paginator($0) }
            .asDriver(onErrorLogAndReturn: MoviesCollection())
    }
}
