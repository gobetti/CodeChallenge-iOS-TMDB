//
//  MovieDetailsViewController.swift
//  CodeChallenge
//
//  Created by Marcelo Gobetti on 3/18/18.
//

import UIKit

final class MovieDetailsViewController: UIViewController {
    private let movie: Movie
    private var shouldHideBarsOnSwipe = false
    
    init(movie: Movie) {
        self.movie = movie
        super.init(nibName: "MovieDetailsView", bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }
    
    // MARK: - UIViewController
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.accessibilityIdentifier = "detailsView" // UI Test
        self.navigationController?.setNavigationBarHidden(false, animated: true)
        self.shouldHideBarsOnSwipe = self.navigationController?.hidesBarsOnSwipe == true
        self.navigationController?.hidesBarsOnSwipe = false
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.navigationController?.hidesBarsOnSwipe = self.shouldHideBarsOnSwipe
    }
}
