//
//  UpcomingMovieCell.swift
//  CodeChallenge
//
//  Created by Marcelo Gobetti on 11/9/16.
//

import UIKit

final class UpcomingMovieCell: UICollectionViewCell {
    // TODO: image
    
    lazy var titleLabel: UILabel = {
        let view = UILabel()
        view.backgroundColor = UIColor.clear
        view.textAlignment = .left
        view.font = UIFont.systemFont(ofSize: 18)
        view.textColor = UIColor.darkText
        self.contentView.addSubview(view)
        return view
    }()
    
    lazy var releaseDateLabel: UILabel = {
        let view = UILabel()
        view.backgroundColor = UIColor.clear
        view.textAlignment = .right
        view.font = UIFont.systemFont(ofSize: 14)
        view.textColor = UIColor.lightGray
        self.contentView.addSubview(view)
        return view
    }()
    
    override func layoutSubviews() {
        super.layoutSubviews()
        let frame = contentView.bounds.insetBy(dx: 0, dy: 0)
        self.titleLabel.frame = frame
        self.releaseDateLabel.frame = frame
    }
}
