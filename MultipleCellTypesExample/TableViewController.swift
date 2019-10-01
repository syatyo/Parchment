//
//  TableViewController.swift
//  MultipleCellTypesExample
//
//  Created by 山田良治 on 2019/10/02.
//  Copyright © 2019 Martin Rechsteiner. All rights reserved.
//

import UIKit

class TableViewController: UITableViewController {
    
    private static let CellIdentifier = "CellIdentifier"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: TableViewController.CellIdentifier)
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 500
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: TableViewController.CellIdentifier, for: indexPath)
        cell.textLabel?.text = "Title"
        return cell
    }
    
}
