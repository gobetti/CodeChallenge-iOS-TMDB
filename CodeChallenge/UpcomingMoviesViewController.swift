//
//  UpcomingMoviesViewController.swift
//  CodeChallenge
//
//  Created by Marcelo Gobetti on 10/27/16.
//

import UIKit
import RxCocoa
import RxSwift

final class UpcomingMoviesViewController: UIViewController {
    private lazy var tmdbModel = TMDBModel()
    private let disposeBag = DisposeBag()
    private let pageRequester = PublishSubject<Void>()
    private let upcomingMovies = BehaviorRelay(value: [Movie]())
    
    // MARK: - UI Elements
    private let collectionView = UICollectionView(frame: CGRect.zero,
                                                  collectionViewLayout: UpcomingMoviesFlowLayout())
    
    // MARK: - UIViewController
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = .white
        
        self.setupContent()
        self.setupMoviesFetcher()
        self.fetchMoreMovies()
    }
    
    // MARK: - Private methods
    private func setupContent() {
        self.collectionView.backgroundColor = .clear
        self.collectionView.register(cellType: UpcomingMovieCell.self)
        self.view.addSubview(self.collectionView)
        
        self.collectionView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            self.collectionView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
            self.collectionView.topAnchor.constraint(equalTo: self.view.topAnchor),
            self.collectionView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
            self.collectionView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor)
            ])
        
        self.upcomingMovies.asObservable()
            .bind(to: self.collectionView.rx.items(cellType: UpcomingMovieCell.self)) { (_, movie, cell) in
                cell.titleLabel.text = movie.name
                cell.releaseDateLabel.text = DateFormatter.localizedString(from: movie.releaseDate,
                                                                           dateStyle: .medium,
                                                                           timeStyle: .none)
                cell.image = self.tmdbModel.image(width: 300, from: movie)
            }.disposed(by: self.disposeBag)
    }
    
    // MARK: - Fetch movies
    private func setupMoviesFetcher() {
        self.collectionView.rx.willEndDragging
            .bind { [unowned self] (_, targetContentOffset) in
                let scrollView = self.collectionView
                let distance = scrollView.contentSize.height - (targetContentOffset.pointee.y + scrollView.bounds.height)
                if distance < 200 {
                    self.fetchMoreMovies()
                }
            }.disposed(by: self.disposeBag)
        
        var fetchedPages = 0
        var nextPage: Int {
            return fetchedPages + 1
        }
        
        self.pageRequester.flatMapFirst { [unowned self] in
            self.tmdbModel.upcomingMovies(page: nextPage)
                .do(onSuccess: { movies in
                    fetchedPages += 1
                    self.upcomingMovies.accept(self.upcomingMovies.value + movies)
                }, onError: { error in
                    print("Error: \(error)")
                }).map { _ in }
            }.subscribe().disposed(by: self.disposeBag)
    }
    
    private func fetchMoreMovies() {
        self.pageRequester.onNext(())
    }
}

private class UpcomingMoviesFlowLayout: UICollectionViewFlowLayout {
    override var itemSize: CGSize {
        get { return CGSize(width: UIScreen.main.bounds.width, height: 55) }
        set {}
    }
    
    override var minimumLineSpacing: CGFloat {
        get { return 1 }
        set {}
    }
}
