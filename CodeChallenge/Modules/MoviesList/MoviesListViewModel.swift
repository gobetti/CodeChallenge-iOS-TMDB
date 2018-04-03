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
    private let tmdbModel = TMDBModel()
    
    private let searchQuerySubject = PublishSubject<String>()
    
    private let moviesSubject = PublishSubject<MoviesCollection>()
    
    var moviesDriver: Driver<MoviesCollection> {
        return self.moviesSubject
            .asDriver(onErrorDriveWith: Driver.empty()) // assuming errors are handled before the subject
    }
    
    func image(width: Int, from movie: Movie) -> Single<UIImage?> {
        return self.tmdbModel.image(width: width, from: movie)
    }
    
    func searchMovies(query: String) {
        self.searchQuerySubject.onNext(query)
    }
    
    init(pageRequester: Observable<Void>) {
        self.setupPaginationListener(pageRequester: pageRequester)
    }
    
    // MARK: - Private methods
    private func createRequest(query: String, page: Int) -> Single<TMDBResults> {
        guard !query.isEmpty else { return self.tmdbModel.upcomingMovies(page: page) }
        return self.tmdbModel.search(query: query, page: page)
    }
    
    private func setupPaginationListener(pageRequester: Observable<Void>) {
        let paginator = { (query: String) -> Observable<MoviesCollection> in
            var fetchedPages = 0
            var nextPage: Int {
                return fetchedPages + 1
            }
            
            return pageRequester.startWith(())
                .flatMapFirst { _ in
                    return self.createRequest(query: query, page: nextPage)
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
        
        self.searchQuerySubject.startWith("")
            .debounce(0.5, scheduler: MainScheduler.instance)
            .distinctUntilChanged()
            .flatMapLatest { paginator($0) }
            .bind(to: self.moviesSubject)
            .disposed(by: self.disposeBag)
    }
}
