//
//  UpcomingMoviesViewModel.swift
//  CodeChallenge
//
//  Created by Marcelo Gobetti on 3/18/18.
//

import RxCocoa
import RxSwift

/// Has to be a class otherwise "Closure cannot implicitly capture a mutating self parameter"
final class UpcomingMoviesViewModel {
    typealias MoviesCollection = [Movie]
    
    private let disposeBag = DisposeBag()
    private let tmdbModel = TMDBModel()
    
    private let pageRequester = PublishSubject<Void>()
    private let upcomingMoviesSubject = PublishSubject<MoviesCollection>()
    
    var upcomingMoviesDriver: Driver<MoviesCollection> {
        return self.upcomingMoviesSubject
            .asDriver(onErrorDriveWith: Driver.empty()) // assuming errors are handled before the subject
    }
    
    func fetchMoreMovies() {
        self.pageRequester.onNext(())
    }
    
    func image(width: Int, from movie: Movie) -> Single<UIImage?> {
        return self.tmdbModel.image(width: width, from: movie)
    }
    
    init() {
        var fetchedPages = 0
        var nextPage: Int {
            return fetchedPages + 1
        }
        
        self.pageRequester.startWith(())
            .flatMapFirst { [unowned self] in
                self.tmdbModel.upcomingMovies(page: nextPage)
                    .do(onSuccess: { _ in fetchedPages += 1 })
                    .catchError {
                        print("Error: \($0)")
                        return Single.just([])
                }
            }.scan(MoviesCollection()) { (accumulatedMovies, newMovies) -> MoviesCollection in
                return accumulatedMovies + newMovies
            }.bind(to: self.upcomingMoviesSubject)
            .disposed(by: self.disposeBag)
    }
}
