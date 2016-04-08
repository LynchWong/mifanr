//
//  IFBackViewController.swift
//  mifanr
//
//  Created by Lynch Wong on 4/7/16.
//  Copyright © 2016 Lynch Wong. All rights reserved.
//

import UIKit
//import SnapKit

class IFBackViewController: UIViewController {
    
    private let bgImageView = UIImageView()

    override func viewDidLoad() {
        super.viewDidLoad()
        initViews()
    }
    
}

// MARK: - 初始化视图

extension IFBackViewController {
    
    private func initViews() {
        initBackgroundImageView()
        initButton()
    }
    
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
        print("IFBackViewController buttonAction")
    }
    
    private func initBackgroundImageView() {
        bgImageView.image = UIImage(named: "bg")
        view.addSubview(bgImageView)
        
        bgImageView.snp_makeConstraints { (make) in
            make.top.left.bottom.right.equalTo(self.view)
        }
    }
    
}