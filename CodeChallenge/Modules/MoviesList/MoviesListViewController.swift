//
//  MoviesListViewController.swift
//  CodeChallenge
//
//  Created by Marcelo Gobetti on 10/27/16.
//

import UIKit
import RxCocoa
import RxSwift

final class MoviesListViewController: UIViewController {
    private let disposeBag = DisposeBag()
    private let uiTesting: Bool
    private lazy var viewModel = MoviesListViewModel(pageRequester: self.pageRequester,
                                                     searchRequester: self.searchRequester,
                                                     uiTesting: self.uiTesting)
    
    // MARK: - UI Elements
    private let collectionView = UICollectionView(frame: CGRect.zero,
                                                  collectionViewLayout: MoviesListFlowLayout())
    private let searchController = UISearchController(searchResultsController: nil)
    
    // MARK: - Initializers
    init(uiTesting: Bool = false) {
        self.uiTesting = uiTesting
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }
    
    // MARK: - UIViewController
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.hidesBarsOnSwipe = true
        self.view.backgroundColor = .white
        self.navigationController?.hidesBarsOnSwipe = true
        
        self.setupContent()
        self.setupMovieNavigator()
        self.setupSearch()
    }
    
    // MARK: - Private methods
    private func setupContent() {
        self.collectionView.backgroundColor = .clear
        self.collectionView.register(cellType: MoviesListCell.self)
        self.view.addSubview(self.collectionView)
        
        self.collectionView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            self.collectionView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
            self.collectionView.topAnchor.constraint(equalTo: self.view.topAnchor),
            self.collectionView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
            self.collectionView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor)
            ])
        
        self.viewModel.moviesDriver
            .drive(self.collectionView.rx.items(cellType: MoviesListCell.self)) { (_, movie, cell) in
                cell.titleLabel.text = movie.originalTitle
                cell.releaseDateLabel.text = DateFormatter.localizedString(from: movie.releaseDate,
                                                                           dateStyle: .medium,
                                                                           timeStyle: .none)
                cell.image = self.viewModel.image(width: 300, from: movie)
            }.disposed(by: self.disposeBag)
    }
    
    // MARK: - Private methods
    private var pageRequester: Observable<Void> {
        return self.collectionView.rx.willEndDragging
            .filter { [unowned self] (_, targetContentOffset) in
                let scrollView = self.collectionView
                let distance = scrollView.contentSize.height - (targetContentOffset.pointee.y + scrollView.bounds.height)
                return distance < 200
            }.map { _ in }
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
        self.searchController.searchResultsUpdater = self
        self.searchController.obscuresBackgroundDuringPresentation = false
        self.searchController.searchBar.placeholder = "Search for Movies"
        if #available(iOS 11.0, *) {
            self.navigationItem.searchController = self.searchController
        } else {
            self.navigationItem.titleView = self.searchController.searchBar
            self.searchController.hidesNavigationBarDuringPresentation = false
        }
        self.definesPresentationContext = true
        
        Observable.merge(self.searchController.searchBar.rx.textDidBeginEditing.map { _ in false },
                         self.searchController.searchBar.rx.textDidEndEditing.map { _ in true })
            .bind { [unowned self] shouldHideNavigationBar in
                self.navigationController?.hidesBarsOnSwipe = shouldHideNavigationBar
            }.disposed(by: self.disposeBag)
    }
    
    private var searchRequester: Observable<String> {
        // TODO: Rx extension for UISearchResultsUpdating
        return self.rx.sentMessage(#selector(self.updateSearchResults(for:)))
            .flatMap { Observable.from(optional: $0.first as? UISearchController) }
            .map { $0.searchBar.text }
            .flatMap { Observable.from(optional: $0) }
    }
}

// TODO: Rx extension for UISearchResultsUpdating
extension MoviesListViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {}
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
