//
//  MovieDetailsViewController.swift
//  CodeChallenge
//
//  Created by Marcelo Gobetti on 3/18/18.
//

import UIKit

final class MovieDetailsViewController: UIViewController {
    private let movie: Movie
    
    init(movie: Movie) {
        self.movie = movie
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }
    
    // MARK: - UIViewController
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.accessibilityIdentifier = "detailsView" // UI Test
        self.navigationController?.setNavigationBarHidden(false, animated: true)
    }
}
