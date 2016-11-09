//
//  ViewController.swift
//  CodeChallenge
//
//  Created by Marcelo Gobetti on 10/27/16.
//

import UIKit
import RxSwift

final class ViewController: UIViewController {
    private lazy var tmdbModel = TMDBModel()
    private let disposeBag = DisposeBag()
    private var upcomingMovies: [Movie]?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.tmdbModel.upcomingMovies().subscribe { [unowned self] event in
            switch event {
            case let .success(movies):
                self.upcomingMovies = movies
                print("Received \(movies.count) movies")
            case let .error(error):
                print("Error: \(error)")
            }
            }.disposed(by: self.disposeBag)
    }
}
