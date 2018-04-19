//
//  ObservableType+Extensions.swift
//  CodeChallenge
//
//  Created by Marcelo Gobetti on 3/29/18.
//

import RxSwift

extension ObservableType {
    /// Returns elements from an observable sequence as long as a specified condition is true,
    /// including the last event from the original sequence (before the condition is checked).
    ///
    /// - Parameter predicate: A function to test each element for a condition.
    /// - Returns: An observable sequence that contains the elements from the input sequence that
    ///            occur before and including the element at which the test no longer passes.
    func takeWhileInclusive(_ predicate: @escaping (E) throws -> Bool) -> Observable<E> {
        let sharedSelf = self.share()
        return Observable.merge(sharedSelf.takeWhile(predicate),
                                sharedSelf.skipWhile(predicate).take(1))
    }
}
