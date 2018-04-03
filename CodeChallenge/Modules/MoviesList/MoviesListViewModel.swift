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
    let moviesDriver: Driver<MoviesCollection>
    
    func image(width: Int, from movie: Movie) -> Single<UIImage?> {
        return self.tmdbModel.image(width: width, from: movie)
    }
    
    init(pageRequester: Observable<Void>,
         searchRequester: Observable<String>,
         tmdbModel: TMDBModel = TMDBModel()) {
        self.moviesDriver = MoviesListViewModel.createMoviesDriver(pageRequester: pageRequester,
                                                                   searchRequester: searchRequester,
                                                                   tmdbModel: tmdbModel)
        self.tmdbModel = tmdbModel
    }
    
    // MARK: - Private static methods
    private static func createRequest(query: String, page: Int, tmdbModel: TMDBModel) -> Single<TMDBResults> {
        guard !query.isEmpty else { return tmdbModel.upcomingMovies(page: page) }
        return tmdbModel.search(query: query, page: page)
    }
    
    private static func createMoviesDriver(pageRequester: Observable<Void>,
                                           searchRequester: Observable<String>,
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
            .debounce(0.5, scheduler: MainScheduler.instance)
            .distinctUntilChanged()
            .flatMapLatest { paginator($0) }
            .asDriver(onErrorRecover: {
                print("Unexpected error: \($0.localizedDescription)")
                return Driver.just(MoviesCollection())
            })
    }
}