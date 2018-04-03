//
//  MoviesListCell.swift
//  CodeChallenge
//
//  Created by Marcelo Gobetti on 11/9/16.
//

import UIKit
import RxSwift

final class MoviesListCell: UICollectionViewCell {
    private var disposeBag = DisposeBag()
    
    var image: Single<UIImage?>? {
        didSet {
            guard let image = self.image else {
                self.imageView.setImageAnimated(nil)
                return
            }
            
            image.subscribe { event in
                switch event {
                case let .success(image):
                    assert(Thread.isMainThread)
                    self.imageView.setImageAnimated(image)
                case let .error(error):
                    print("Error fetching image: \(error)")
                }
                }.disposed(by: self.disposeBag)
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
        view.backgroundColor = UIColor.clear
        view.textAlignment = .center
        view.font = UIFont.systemFont(ofSize: 18)
        view.textColor = UIColor.darkText
        self.contentView.insertSubview(view, aboveSubview: self.imageView)
        
        view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            view.leadingAnchor.constraint(equalTo: self.releaseDateLabel.leadingAnchor),
            view.trailingAnchor.constraint(equalTo: self.releaseDateLabel.trailingAnchor),
            view.bottomAnchor.constraint(equalTo: self.releaseDateLabel.topAnchor, constant: 5)
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
            view.leadingAnchor.constraint(equalTo: self.imageView.leadingAnchor),
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