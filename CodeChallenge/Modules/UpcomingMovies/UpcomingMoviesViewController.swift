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
    private let disposeBag = DisposeBag()
    private let viewModel = UpcomingMoviesViewModel()
    
    // MARK: - UI Elements
    private let collectionView = UICollectionView(frame: CGRect.zero,
                                                  collectionViewLayout: MoviesListFlowLayout())
    private let searchController = UISearchController(searchResultsController: nil)
    
    // MARK: - UIViewController
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.hidesBarsOnSwipe = true
        self.view.backgroundColor = .white
        self.navigationController?.hidesBarsOnSwipe = true
        
        self.setupContent()
        self.setupMoviesFetcher()
        self.setupMovieNavigator()
        self.setupSearch()
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
        
        self.viewModel.moviesDriver
            .drive(self.collectionView.rx.items(cellType: UpcomingMovieCell.self)) { (_, movie, cell) in
                cell.titleLabel.text = movie.name
                cell.releaseDateLabel.text = DateFormatter.localizedString(from: movie.releaseDate,
                                                                           dateStyle: .medium,
                                                                           timeStyle: .none)
                cell.image = self.viewModel.image(width: 300, from: movie)
            }.disposed(by: self.disposeBag)
    }
    
    // MARK: - Private methods
    private func setupMoviesFetcher() {
        self.collectionView.rx.willEndDragging
            .bind { [unowned self] (_, targetContentOffset) in
                let scrollView = self.collectionView
                let distance = scrollView.contentSize.height - (targetContentOffset.pointee.y + scrollView.bounds.height)
                if distance < 200 {
                    self.viewModel.fetchMoreMovies()
                }
            }.disposed(by: self.disposeBag)
    }
    
    private func setupMovieNavigator() {
        self.collectionView.rx.modelSelected(Movie.self)
            .bind { [unowned self] selectedMovie in
                guard let navigationController = self.navigationController else {
                    print("Unable to push movie details - no navigation controller")
                    return
                }
                
                navigationController.pushViewController(MovieDetailsViewController(movie: selectedMovie),
                                                        animated: true)
            }.disposed(by: self.disposeBag)
    }
    
    private func setupSearch() {
        self.searchController.obscuresBackgroundDuringPresentation = false
        self.searchController.searchBar.placeholder = "Search for Movies"
        if #available(iOS 11.0, *) {
            self.navigationItem.searchController = self.searchController
        } else {
            // TODO: not working in older iOS versions
        }
        self.definesPresentationContext = true
        
        self.searchController.searchBar.rx.text
            .map { text -> String in
                guard let text = text else { return "" }
                return text
            }.bind { [unowned self] in
                self.viewModel.searchMovies(query: $0)
            }.disposed(by: self.disposeBag)
    }
}

private class MoviesListFlowLayout: UICollectionViewFlowLayout {
    override var itemSize: CGSize {
        get { return CGSize(width: UIScreen.main.bounds.width, height: 55) }
        set {}
    }
    
    override var minimumLineSpacing: CGFloat {
        get { return 1 }
        set {}
    }
}
