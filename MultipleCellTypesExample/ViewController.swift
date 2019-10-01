//
//  ViewController.swift
//  MultipleCellTypesExample
//
//  Created by 山田良治 on 2019/10/02.
//  Copyright © 2019 Martin Rechsteiner. All rights reserved.
//

import UIKit
import Parchment

enum TabPagingItem: Int, PagingItem, Hashable, Comparable, CaseIterable {
    case done
    case todo
    case inProgress
    case archive
    case friend
    
    enum TabType {
        case icon(UIImage)
        case label(String)
        
        var reuseIdentifer: String {
            switch self {
            case .icon:
                return "icon"
                
            case .label:
                return "label"
            }
        }
    }
    
    var tabType: TabType {
        switch self {
        case .done:
            return .icon(UIImage(named: "check")!.withRenderingMode(.alwaysTemplate))
            
        case .todo:
            return .label("TODO")
            
        case .inProgress:
            return .label("In Progress")
            
        case .archive:
            return .label("Archive")
            
        case .friend:
            return .label("Friend")
        }
    }
    
    var reuseIdentifer: String {
        return tabType.reuseIdentifer
    }
    
    static func < (lhs: TabPagingItem, rhs: TabPagingItem) -> Bool {
        return lhs.rawValue < rhs.rawValue
    }

}

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        setupTabUI()
    }

    private func setupTabUI() {
        let pagingViewController = PagingViewController()
        pagingViewController.options.menuItemSources = [
            .nib(nib: UINib(nibName: "IconPagingCell", bundle: nil), reuseIdentifier: "icon"),
            .nib(nib: UINib(nibName: "LabelPagingCell", bundle: nil), reuseIdentifier: "label")
        ]
        pagingViewController.options.menuItemSize = .sizeToFit(minWidth: 40, height: 50)
        pagingViewController.options.textColor = UIColor(red: 0.51, green: 0.54, blue: 0.56, alpha: 1)
        pagingViewController.options.selectedTextColor = UIColor(red: 0.14, green: 0.77, blue: 0.85, alpha: 1)
        pagingViewController.options.indicatorColor = UIColor(red: 0.14, green: 0.77, blue: 0.85, alpha: 1)
        pagingViewController.dataSource = self
        pagingViewController.select(index: 0)
        
        // Add the paging view controller as a child view controller
        // and contrain it to all edges.
        addChild(pagingViewController)
        view.addSubview(pagingViewController.view)
        pagingViewController.view.translatesAutoresizingMaskIntoConstraints = false
        pagingViewController.view.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor).isActive = true
        pagingViewController.view.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor).isActive = true
        pagingViewController.view.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor).isActive = true
        pagingViewController.view.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor).isActive = true
        pagingViewController.didMove(toParent: self)

    }

}

extension ViewController: PagingViewControllerDataSource {
    
    func numberOfViewControllers(in pagingViewController: PagingViewController) -> Int {
        return TabPagingItem.allCases.count
    }
    
    func pagingViewController(_: PagingViewController, viewControllerAt index: Int) -> UIViewController {
        let viewController = TableViewController(style: .plain)
        return viewController
    }
    
    func pagingViewController(_: PagingViewController, pagingItemAt index: Int) -> PagingItem {
        return TabPagingItem(rawValue: index)!
    }
    
    func pagingViewController(_: PagingViewController, reuseIdentifierForPagingItemAt index: Int) -> String {
        return TabPagingItem(rawValue: index)!.reuseIdentifer
    }
    
}
