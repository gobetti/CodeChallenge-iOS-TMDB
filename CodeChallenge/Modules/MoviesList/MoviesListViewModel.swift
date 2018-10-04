//
//  MoviesListViewModel.swift
//  CodeChallenge
//
//  Created by Marcelo Gobetti on 3/18/18.
//

import RxCocoa
import RxSwift

typealias MoviesCollection = [Movie]

struct MoviesList {
    let movies: Driver<MoviesCollection>
    let isLoading: Driver<Bool>
}

struct MoviesListViewModel {
    private let disposeBag = DisposeBag()
    private let scheduler: SchedulerType
    private let tmdbModel: TMDBModel
    
    func image(width: Int, from movie: Movie) -> Single<UIImage> {
        return self.tmdbModel.image(width: width, from: movie)
    }
    
    // MARK: - Initializers
    init(tmdbModel: TMDBModel = TMDBModel(),
         uiTesting: Bool = false,
         scheduler: SchedulerType = MainScheduler.instance) {
        self.scheduler = scheduler
        
        if uiTesting {
            self.tmdbModel = TMDBModel(stubBehavior: .immediate(stub: .default), scheduler: MainScheduler.instance)
        } else {
            self.tmdbModel = tmdbModel
        }
    }
    
    private static func createRequest(query: String, page: Int, tmdbModel: TMDBModel) -> Single<TMDBResults> {
        guard !query.isEmpty else { return tmdbModel.upcomingMovies(page: page) }
        return tmdbModel.search(query: query, page: page)
    }
    
    func movies(pageRequester: Observable<Void>,
                searchRequester: Observable<String>,
                debounceTime: RxTimeInterval = 0.5) -> MoviesList {
        let isLoading = BehaviorRelay(value: false)
        
        let paginator = { (query: String) -> Observable<MoviesCollection> in
            var fetchedPages = 0
            var nextPage: Int {
                return fetchedPages + 1
            }
            
            return pageRequester.startWith(())
                .do(onNext: { isLoading.accept(true) })
                .flatMapFirst { _ in
                    MoviesListViewModel.createRequest(query: query, page: nextPage, tmdbModel: self.tmdbModel)
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
        
        return MoviesList(movies: moviesDriver, isLoading: isLoadingDriver)
    }
}
