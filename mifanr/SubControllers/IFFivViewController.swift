//
//  IFFivViewController.swift
//  mifanr
//
//  Created by Lynch Wong on 4/7/16.
//  Copyright © 2016 Lynch Wong. All rights reserved.
//

import UIKit

class IFFivViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        view.clipsToBounds = true
        view.backgroundColor = UIColor ( red: 1.0, green: 0.3838, blue: 0.5102, alpha: 1.0 )
        print("IFFivViewController")
        
        initButton()
    }

    override func willMoveToParentViewController(parent: UIViewController?) {
        super.willMoveToParentViewController(parent)
        print("IFFivViewController willMoveToParentViewController")
    }
    
    override func didMoveToParentViewController(parent: UIViewController?) {
        super.didMoveToParentViewController(parent)
        print("IFFivViewController didMoveToParentViewController")
    }

}

extension IFFivViewController {

    private func initButton() {
        let button = UIButton()
        button.setTitle("Button", forState: UIControlState.Normal)
        button.addTarget(self, action: #selector(IFBackViewController.buttonAction), forControlEvents: UIControlEvents.TouchUpInside)
        view.addSubview(button)
        
        button.snp_makeConstraints { (make) in
            make.center.equalTo(view)
            make.height.equalTo(40.0)
            make.width.equalTo(100.0)
        }
    }
    
    func buttonAction() {
        print("IFFivViewController buttonAction")
    }
    
}