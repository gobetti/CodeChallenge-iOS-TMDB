//
//  MovieDetailsViewController.swift
//  CodeChallenge
//
//  Created by Marcelo Gobetti on 3/18/18.
//

import ColorCube
import RxCocoa
import RxSwift
import UIKit

final class MovieDetailsViewController: UIViewController {
    private let colorCube = CCColorCube()
    private let disposeBag = DisposeBag()
    private let image: Single<UIImage>
    private let overview: String
    private var shouldHideBarsOnSwipe = false
    
    // MARK: - Outlets
    @IBOutlet private weak var posterImageView: UIImageView! {
        didSet {
            self.image.observeOn(ConcurrentDispatchQueueScheduler(qos: .background))
                .map { [unowned self] image -> (UIImage, UIColor?) in
                    assert(!Thread.isMainThread)
                    let color = self.colorCube.extractBrightColors(from: image, avoid: .white, count: 1)?.first
                    return (image, color)
                }.asDriver(onErrorDriveWith: Driver.empty())
                .drive(onNext: { [unowned self] image, backgroundColor in
                    self.posterImageView.setImageAnimated(image)
                    
                    if let color = backgroundColor {
                        UIView.animate(withDuration: 0.5, animations: {
                            self.view.backgroundColor = color
                        })
                    }
                }).disposed(by: self.disposeBag)
        }
    }
    @IBOutlet private weak var overviewTextView: UITextView! {
        didSet {
            self.overviewTextView.text = self.overview
        }
    }
    
    // MARK: - Initializers
    init(title: String, image: Single<UIImage>, overview: String) {
        self.image = image
        self.overview = overview
        super.init(nibName: "MovieDetailsView", bundle: nil)
        self.title = title
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
