//
//  MoviesListViewModel.swift
//  CodeChallenge
//
//  Created by Marcelo Gobetti on 3/18/18.
//

import RxCocoa
import RxSwift

struct MoviesListViewModel {
    typealias MoviesCollection = [Movie]
    
    private let disposeBag = DisposeBag()
    private let tmdbModel: TMDBModel
    
    // MARK: - Public
    let isLoadingDriver: Driver<Bool>
    let moviesDriver: Driver<MoviesCollection>
    
    func image(width: Int, from movie: Movie) -> Single<UIImage> {
        return self.tmdbModel.image(width: width, from: movie)
    }
    
    // MARK: - Initializers
    init(pageRequester: Observable<Void>,
         searchRequester: Observable<String>,
         tmdbModel: TMDBModel,
         debounceTime: RxTimeInterval = 0.5,
         scheduler: SchedulerType = MainScheduler.instance) {
        (self.moviesDriver, self.isLoadingDriver) = MoviesListViewModel.createDrivers(pageRequester: pageRequester,
                                                                                      searchRequester: searchRequester,
                                                                                      debounceTime: debounceTime,
                                                                                      scheduler: scheduler,
                                                                                      tmdbModel: tmdbModel)
        self.tmdbModel = tmdbModel
    }
    
    init(pageRequester: Observable<Void>, searchRequester: Observable<String>, uiTesting: Bool = false) {
        let tmdbModel: TMDBModel
        if uiTesting {
            tmdbModel = TMDBModel(stubBehavior: .immediate(stub: .default), scheduler: MainScheduler.instance)
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
    
    private static func createDrivers(pageRequester: Observable<Void>,
                                      searchRequester: Observable<String>,
                                      debounceTime: RxTimeInterval,
                                      scheduler: SchedulerType,
                                      tmdbModel: TMDBModel) -> (Driver<MoviesCollection>, Driver<Bool>) {
        let isLoading = BehaviorRelay(value: false)
        
        let paginator = { (query: String) -> Observable<MoviesCollection> in
            var fetchedPages = 0
            var nextPage: Int {
                return fetchedPages + 1
            }
            
            return pageRequester.startWith(())
                .do(onNext: { isLoading.accept(true) })
                .flatMapFirst { _ in
                    MoviesListViewModel.createRequest(query: query, page: nextPage, tmdbModel: tmdbModel)
                        .do(onSuccess: { _ in fetchedPages += 1 })
                        .catchError {
                            print("Error: \($0)")
                            return Single.just(TMDBResults(movies: [], totalPages: Int.max))
                    }
                }.do(onNext: { _ in isLoading.accept(false) })
                .takeWhileInclusive { fetchedPages < $0.totalPages }
                .map { $0.movies }
                .scan(MoviesCollection()) { (accumulatedMovies, newMovies) -> MoviesCollection in
                    return accumulatedMovies + newMovies
            }
        }
        
        let moviesDriver = searchRequester.startWith("")
            .debounce(debounceTime, scheduler: scheduler)
            .distinctUntilChanged()
            .flatMapLatest { paginator($0) }
            .asDriver(onErrorLogAndReturn: MoviesCollection())
        
        let isLoadingDriver = isLoading.asDriver().distinctUntilChanged()
        
        return (moviesDriver, isLoadingDriver)
    }
}
