//
//  IconPagingCell.swift
//  MultipleCellTypesExample
//
//  Created by 山田良治 on 2019/10/02.
//  Copyright © 2019 Martin Rechsteiner. All rights reserved.
//

import UIKit
import Parchment

class IconPagingCell: PagingCell {
    @IBOutlet weak var imageView: UIImageView!
    
    struct ViewModel {
        var image: UIImage
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    override func setPagingItem(_ pagingItem: PagingItem, selected: Bool, options: PagingOptions) {
        
        if let tabPagingItem = pagingItem as? TabPagingItem {
            if case .icon(let image) = tabPagingItem.tabType {
                imageView.image = image
            }
            
            if selected {
                imageView.tintColor = options.selectedTextColor
            } else {
                imageView.tintColor = options.textColor
            }
        }
    }

}
