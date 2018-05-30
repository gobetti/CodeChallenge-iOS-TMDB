//
//  Response.swift
//  CodeChallenge
//
//  Created by Marcelo Gobetti on 4/23/18.
//

import Foundation
import RxSwift

enum ImageDataError: Error {
    case invalidImage
}

extension PrimitiveSequence where TraitType == SingleTrait, ElementType == Data {
    func mapImage() -> Single<UIImage> {
        return self.map {
            guard let image = UIImage(data: $0) else {
                throw ImageDataError.invalidImage
            }
            return image
        }
    }
}
