//
//  MoviesListViewController.swift
//  CodeChallenge
//
//  Created by Marcelo Gobetti on 10/27/16.
//

import UIKit
import RxCocoa
import RxSwift

private enum MoviesListViewConstants {
    static let cellHeight: CGFloat = 55
}

final class MoviesListViewController: UIViewController {
    private let disposeBag = DisposeBag()
    private let uiTesting: Bool
    private lazy var viewModel = MoviesListViewModel(pageRequester: self.pageRequester,
                                                     searchRequester: self.searchRequester,
                                                     uiTesting: self.uiTesting)
    
    // MARK: - UI Elements
    private let collectionView = UICollectionView(frame: CGRect.zero,
                                                  collectionViewLayout: MoviesListFlowLayout())
    private let loadingView = UIActivityIndicatorView(activityIndicatorStyle: .gray)
    private let searchController = UISearchController(searchResultsController: nil)
    private let stackView = UIStackView(frame: CGRect.zero)
    
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
        self.stackView.axis = .vertical
        self.stackView.addArrangedSubview(self.collectionView)
        self.stackView.addArrangedSubview(self.loadingView)
        self.view.addSubview(self.stackView)
        
        self.stackView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            self.stackView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
            self.stackView.topAnchor.constraint(equalTo: self.view.topAnchor),
            self.stackView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
            self.stackView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor)
            ])
        
        // Movies
        self.collectionView.backgroundColor = .clear
        self.collectionView.register(cellType: MoviesListCell.self)
        self.viewModel.moviesDriver
            .drive(self.collectionView.rx.items(cellType: MoviesListCell.self)) { (_, movie, cell) in
                cell.titleLabel.text = movie.originalTitle
                cell.releaseDateLabel.text = DateFormatter.localizedString(from: movie.releaseDate,
                                                                           dateStyle: .medium,
                                                                           timeStyle: .none)
                cell.image = self.viewModel.image(width: 300, from: movie).asDriver(onErrorDriveWith: Driver.empty())
            }.disposed(by: self.disposeBag)
        
        // Loading
        self.loadingView.heightAnchor.constraint(equalToConstant: MoviesListViewConstants.cellHeight).isActive = true
        self.viewModel.isLoadingDriver
            .drive(onNext: { [unowned self] isLoading in
                // TODO: RxAnimated
                UIView.animate(withDuration: 0.3, animations: {
                    self.loadingView.isHidden = !isLoading
                })
            }).disposed(by: self.disposeBag)
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
                
                navigationController.pushViewController(
                    MovieDetailsViewController(title: selectedMovie.originalTitle,
                                               image: self.viewModel.image(width: 500, from: selectedMovie),
                                               overview: selectedMovie.overview),
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
        get { return CGSize(width: UIScreen.main.bounds.width, height: MoviesListViewConstants.cellHeight) }
        set {}
    }
    
    override var minimumLineSpacing: CGFloat {
        get { return 1 }
        set {}
    }
}
