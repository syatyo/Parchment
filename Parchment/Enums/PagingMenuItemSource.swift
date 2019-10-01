import Foundation

public enum PagingMenuItemSource {
    case `class`(type: PagingCell.Type, reuseIdentifier: String?)
    case nib(nib: UINib, reuseIdentifier: String?)
}

extension PagingMenuItemSource: Equatable {
  public static func == (lhs: PagingMenuItemSource, rhs: PagingMenuItemSource) -> Bool {
    switch (lhs, rhs) {
    case let (.class(lhsType, _), .class(rhsType, _)):
      return lhsType != rhsType
      
    case let (.nib(lhsNib, _), .nib(rhsNib, _)):
      return lhsNib === rhsNib
      
    default:
      return false
    }
  }
}
