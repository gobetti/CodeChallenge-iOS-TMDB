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
    private let disposeBag = DisposeBag()
    private let tmdbModel = TMDBModel()
    
    private let pageRequester = PublishSubject<Void>()
    private let upcomingMoviesSubject = Variable<[Movie]>([])
    private var upcomingMovies: [Movie] {
        get {
            return self.upcomingMoviesSubject.value
        }
        set {
            self.upcomingMoviesSubject.value = newValue
        }
    }
    
    var upcomingMoviesDriver: Driver<[Movie]> {
        return self.upcomingMoviesSubject.asDriver()
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
        
        self.pageRequester.flatMapFirst { [unowned self] in
            self.tmdbModel.upcomingMovies(page: nextPage)
                .do(onSuccess: { movies in
                    fetchedPages += 1
                    self.upcomingMovies += movies
                }, onError: { error in
                    print("Error: \(error)")
                }).map { _ in }
            }.subscribe().disposed(by: self.disposeBag)
    }
}
