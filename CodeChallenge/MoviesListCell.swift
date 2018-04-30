//
//  MoviesListCell.swift
//  CodeChallenge
//
//  Created by Marcelo Gobetti on 11/9/16.
//

import UIKit
import ColorCube
import RxCocoa
import RxSwift

final class MoviesListCell: UICollectionViewCell {
    private typealias BrightColor = UIColor
    private typealias DarkColor = UIColor
    
    private var disposeBag = DisposeBag()
    private let colorCube = CCColorCube()
    
    var image: Single<UIImage>? {
        didSet {
            guard let image = self.image else {
                self.imageView.setImageAnimated(nil)
                return
            }
            
            image.observeOn(ConcurrentDispatchQueueScheduler(qos: .background))
                .map { [unowned self] image -> (UIImage, BrightColor?, DarkColor?) in
                    assert(!Thread.isMainThread)
                    let brightColor = self.colorCube.extractBrightColors(from: image, avoid: .white, count: 1)?.first
                    let darkColor = self.colorCube.extractDarkColors(from: image, avoid: .black, count: 1)?.first
                    return (image, brightColor, darkColor)
                }.asDriver(onErrorDriveWith: Driver.empty())
                .drive(onNext: { [unowned self] image, brightColor, darkColor in
                    self.imageView.setImageAnimated(image)
                    
                    if let color = brightColor {
                        self.titleLabel.attributedText = NSAttributedString(string: self.titleLabel.text ?? "",
                                                                            attributes: [.backgroundColor: color])
                    }
                    if let color = darkColor {
                        self.releaseDateLabel.attributedText = NSAttributedString(string: self.releaseDateLabel.text ?? "",
                                                                                  attributes: [.backgroundColor: color])
                    }
                }).disposed(by: self.disposeBag)
        }
    }
    
    lazy var imageView: UIImageView = {
        let view = UIImageView()
        view.contentMode = .scaleAspectFill
        view.clipsToBounds = true
        self.contentView.addSubview(view)
        
        view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            view.leadingAnchor.constraint(equalTo: self.contentView.leadingAnchor),
            view.trailingAnchor.constraint(equalTo: self.contentView.trailingAnchor),
            view.topAnchor.constraint(equalTo: self.contentView.topAnchor),
            view.bottomAnchor.constraint(equalTo: self.contentView.bottomAnchor)
            ])
        
        return view
    }()
    
    lazy var titleLabel: UILabel = {
        let view = UILabel()
        view.backgroundColor = .clear
        view.font = UIFont.boldSystemFont(ofSize: 24)
        view.textColor = .darkText
        self.contentView.insertSubview(view, aboveSubview: self.imageView)
        
        view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            view.leadingAnchor.constraint(equalTo: self.imageView.leadingAnchor, constant: 5),
            view.trailingAnchor.constraint(equalTo: self.releaseDateLabel.leadingAnchor, constant: -5),
            view.centerYAnchor.constraint(equalTo: self.imageView.centerYAnchor)
            ])
        
        return view
    }()
    
    lazy var releaseDateLabel: UILabel = {
        let view = UILabel()
        view.backgroundColor = UIColor.clear
        view.textAlignment = .right
        view.font = UIFont.systemFont(ofSize: 14)
        view.textColor = UIColor.lightGray
        self.contentView.insertSubview(view, aboveSubview: self.imageView)
        
        view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            view.trailingAnchor.constraint(equalTo: self.imageView.trailingAnchor),
            view.bottomAnchor.constraint(equalTo: self.imageView.bottomAnchor)
            ])
        
        return view
    }()
    
    // MARK: - UICollectionViewCell overrides
    override func prepareForReuse() {
        super.prepareForReuse()
        self.disposeBag = DisposeBag()
        self.releaseDateLabel.text = nil
        self.image = nil
        self.titleLabel.text = nil
    }
}
