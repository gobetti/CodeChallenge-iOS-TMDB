//
//  UICollectionView+Extensions.swift
//  CodeChallenge
//
//  Created by Marcelo Gobetti on 09/09/17.
//

import RxCocoa
import RxSwift

extension UICollectionViewCell {
    /// Every cell must have its reuse identifier set identically to its class name
    static var reuseIdentifier: String {
        return String(describing: self)
    }
}

extension UICollectionView {
    /// Helper register method where only the cell type must be passed, assuming a common reuseIdentifier
    func register<Cell: UICollectionViewCell>(cellType: Cell.Type) {
        register(cellType, forCellWithReuseIdentifier: cellType.reuseIdentifier)
    }
}

extension Reactive where Base: UICollectionView {
    /// Helper items method where  only the cell type must be passed, assuming a common reuseIdentifier
    public func items<S: Sequence, Cell: UICollectionViewCell, O : ObservableType>
        (cellType: Cell.Type = Cell.self)
        -> (_ source: O)
        -> (_ configureCell: @escaping (Int, S.Iterator.Element, Cell) -> Void)
        -> Disposable where O.E == S {
            return items(cellIdentifier: cellType.reuseIdentifier, cellType: cellType)
    }
}
