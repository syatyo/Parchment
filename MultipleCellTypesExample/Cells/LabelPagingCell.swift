//
//  LabelPagingCell.swift
//  MultipleCellTypesExample
//
//  Created by 山田良治 on 2019/10/02.
//  Copyright © 2019 Martin Rechsteiner. All rights reserved.
//

import UIKit
import Parchment

class LabelPagingCell: PagingCell {

    @IBOutlet weak var titleLabel: UILabel!
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setPagingItem(_ pagingItem: PagingItem, selected: Bool, options: PagingOptions) {
        
        if let tabPagingItem = pagingItem as? TabPagingItem {
            if case .label(let text) = tabPagingItem.tabType {
                titleLabel.text = text
            }
            
            if selected {
                titleLabel.textColor = options.selectedTextColor
            } else {
                titleLabel.textColor = options.textColor
            }
        }
    }

}
