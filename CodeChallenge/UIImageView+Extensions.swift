//
//  UIImageView+Extensions.swift
//  CodeChallenge
//
//  Created by Marcelo Gobetti on 3/17/18.
//

import UIKit

public extension UIImageView {
    func setImageAnimated(_ image: UIImage?,
                          duration: TimeInterval = 0.5) {
        UIView.transition(with: self, duration: duration, options: .transitionCrossDissolve, animations: {
            self.image = image
        }, completion: nil)
    }
}
