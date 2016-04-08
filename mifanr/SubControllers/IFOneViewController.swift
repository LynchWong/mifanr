//
//  IFOneViewController.swift
//  mifanr
//
//  Created by Lynch Wong on 4/7/16.
//  Copyright © 2016 Lynch Wong. All rights reserved.
//

import UIKit

class IFOneViewController: UIViewController {
    
    var tableView: UITableView!

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        view.clipsToBounds = true
        print("IFOneViewController")
        
        tableView = UITableView(frame: CGRectZero, style: UITableViewStyle.Plain)
        tableView.delegate = self
        tableView.dataSource = self
        view.addSubview(tableView)
        
        tableView.snp_makeConstraints { (make) in
            make.top.leading.bottom.trailing.equalTo(view)
        }
    }
    
    override func willMoveToParentViewController(parent: UIViewController?) {
        super.willMoveToParentViewController(parent)
        print("IFOneViewController willMoveToParentViewController")
    }
    
    override func didMoveToParentViewController(parent: UIViewController?) {
        super.didMoveToParentViewController(parent)
        print("IFOneViewController didMoveToParentViewController")
    }

}

extension IFOneViewController: UITableViewDelegate, UITableViewDataSource {
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 30
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let Identifier = "Cell"
        var cell = tableView.dequeueReusableCellWithIdentifier(Identifier)
        if cell == nil {
            cell = UITableViewCell(style: UITableViewCellStyle.Default, reuseIdentifier: Identifier)
        }
        cell?.textLabel?.text = "HEHE"
        return cell!
    }
    
}

extension IFOneViewController: IFPullRefreshble {
    
    func getPullView(refreshControl: IFPullRefreshControl) -> (pullView: UIScrollView, task: Task?) {
        return (pullView: tableView, task: {
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), {
                NSThread.sleepForTimeInterval(2.0)
                dispatch_async(dispatch_get_main_queue(), {
                    refreshControl.endRefresh()
                })
            })
        })
    }
    
}
