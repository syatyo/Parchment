import Foundation

public enum PagingMenuItemSource {
    case `class`(type: PagingCell.Type, reuseIdentifier: String?)
    case nib(nib: UINib, reuseIdentifier: String?)
}

extension PagingMenuItemSource: Equatable {
  public static func == (lhs: PagingMenuItemSource, rhs: PagingMenuItemSource) -> Bool {
    switch (lhs, rhs) {
    case let (.class(lhsType, lhsIdentifier), .class(rhsType, rhsIdentifier)):
      return lhsType == rhsType && lhsIdentifier == rhsIdentifier
      
    case let (.nib(lhsNib, lhsIdentifier), .nib(rhsNib, rhsIdentifier)):
      return lhsNib === rhsNib && lhsIdentifier == rhsIdentifier
      
    default:
      return false
    }
  }
}
