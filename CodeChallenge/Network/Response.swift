//
//  Response.swift
//  CodeChallenge
//
//  Created by Marcelo Gobetti on 4/23/18.
//

import Foundation
import RxSwift

typealias Response = (statusCode: Int, data: Data)

enum ResponseError: Error {
    case invalidImage
}

extension PrimitiveSequence where TraitType == SingleTrait, ElementType == Response {
    func mapImage() -> Single<UIImage> {
        return self.map {
            guard let image = UIImage(data: $0.data) else {
                throw ResponseError.invalidImage
            }
            return image
        }
    }
}
