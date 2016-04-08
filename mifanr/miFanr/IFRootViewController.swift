//
//  IFRootViewController.swift
//  mifanr
//
//  Created by Lynch Wong on 4/7/16.
//  Copyright © 2016 Lynch Wong. All rights reserved.
//

import UIKit
import SnapKit

let ScreenWidth = UIScreen.mainScreen().bounds.width
let ScreenHeight = UIScreen.mainScreen().bounds.height

/**
 标识根视图控制器的状态，正常或者缩放
 
 - Full:  正常大小
 - Small: 缩小
 */
public enum RootState {
    case Full
    case Small
}

// Controller容器
public class IFRootViewController: UIViewController {
    
    // 标识当前控制器状态
    private var state = RootState.Full
    
    // 顶部刷新视图
    private var refreshControl: IFPullRefreshControl!
    
    // 视图缩放按钮
    private let button = UIButton()
    
    // 滚动视图
    private let scrollView = IFScrollView()
    // 用于布局scrollView的镜像视图
    private let mirrorView = UIView()
    // 用于布局scrollView，跟镜像视图登高等宽
    private let contentView = UIView()
    
    // 镜像视图的宽高约束，用于后面更新
    private var mirrorViewWidthConstraint: Constraint!
    private var mirrorViewHeightConstraint: Constraint!
    
    // 滚动视图的宽高约束
    private var scrollViewWidthConstraint: Constraint!
    private var scrollViewHeightConstraint: Constraint!
    
    // 添加到滚动视图的点击和扫动手势，用于缩放的时候恢复正常大小
    private var scrollViewSwipeGestureRecognizer:  UISwipeGestureRecognizer!
    private var scrollViewTapGestureRecognizer: UITapGestureRecognizer!
    
    // 底层控制器，缩小时才能看见
    private let backController: UIViewController
    // 控制器对应的标题
    private let subTitles: [String]
    // 控制器
    private let subControllers: [UIViewController]
    
    public init(backController: UIViewController, subTitles: [String], subControllers: [UIViewController]) {
        self.backController = backController
        self.subTitles = subTitles
        self.subControllers = subControllers
        super.init(nibName: nil, bundle: nil)
    }
    
    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        initViews()
    }
    
    public override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        scrollView.setContentOffset(CGPoint(x: ScreenWidth, y: 0.0), animated: false)// 设置显示第二页
    }

}

// MARK: - 初始化视图

extension IFRootViewController {
    
    private func initViews() {
        initBackView()// 添加背景视图
        initScrollView()// 添加滚动视图
        initChildrenView()// 添加子视图
        initButton()// 添加缩放按钮
        initRefreshControl()// 添加顶部刷新视图
    }
    
    private func initBackView() {
        addChildViewController(backController)
        backController.didMoveToParentViewController(self)
        backController.view.hidden = true
        view.addSubview(backController.view)
        
        backController.view.snp_makeConstraints { (make) in
            make.top.leading.bottom.trailing.equalTo(view)
        }
    }
    
    private func initRefreshControl() {
        refreshControl = IFPullRefreshControl(type: RefreshControlType.Header, titles: subTitles)
        view.addSubview(refreshControl)
        
        refreshControl.snp_makeConstraints { (make) in
            make.leading.trailing.top.equalTo(view)
            refreshControl.refreshControlHeightConstraint = make.height.equalTo(20.0).constraint
        }
        
        setupRefreshControlDelegate(0)
    }
    
    // 设置刷新的代理，滚动切换了视图的时候也会调用这个方法，只有适配了IFPullRefreshble协议的Controller才能下拉刷新
    // 如IFOneViewController和IFThrViewController，一个适配，一个没有
    private func setupRefreshControlDelegate(index: Int) {
        if let delegate = subControllers[index] as? IFPullRefreshble {
            refreshControl.delegate = delegate
        }
    }
    
    private func initScrollView() {
        scrollView.pagingEnabled = true
        scrollView.showsVerticalScrollIndicator = false
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.delegate = self
        scrollView.contentSizeDelegate = self
        view.addSubview(scrollView)
        
        scrollView.snp_makeConstraints { (make) in
            make.leading.bottom.equalTo(view)
            scrollViewWidthConstraint = make.width.equalTo(ScreenWidth).constraint
            scrollViewHeightConstraint = make.height.equalTo(ScreenHeight - 20).constraint
        }
        
        initMirrorView()
        initContentView()
        initGestureRecognizer()
    }
    
    private func initMirrorView() {
        mirrorView.hidden = true
        view.addSubview(mirrorView)
        mirrorView.snp_makeConstraints { (make) in
            make.leading.bottom.equalTo(view)
            mirrorViewWidthConstraint = make.width.equalTo(ScreenWidth).constraint
            mirrorViewHeightConstraint = make.height.equalTo(ScreenHeight - 20).constraint
        }
    }
    
    private func initContentView() {
        scrollView.addSubview(contentView)
        contentView.snp_makeConstraints { (make) in
            make.leading.top.bottom.trailing.equalTo(scrollView)
            make.height.width.equalTo(mirrorView)
        }
    }
    
    private func initGestureRecognizer() {
        // UISwipeGestureRecognizer
        scrollViewSwipeGestureRecognizer = UISwipeGestureRecognizer(target: self, action: #selector(IFRootViewController.handleGestureRecognizerDirection(_:)))
        scrollViewSwipeGestureRecognizer.direction = UISwipeGestureRecognizerDirection.Up
        scrollViewSwipeGestureRecognizer.delegate = self
        
        // UITapGestureRecognizer
        scrollViewTapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(IFRootViewController.handleGestureRecognizerDirection(_:)))
        scrollViewTapGestureRecognizer.delegate = self
    }
    
    private func initChildrenView() {
        mirrorViewHeightConstraint.updateOffset(ScreenHeight - 20)
        mirrorViewWidthConstraint.updateOffset(CGFloat(subControllers.count) * ScreenWidth)
        
        for subController in subControllers {
            addChildViewController(subController)
            subController.didMoveToParentViewController(self)
            contentView.addSubview(subController.view)
        }
        
        layoutSubControllers()
    }
    
    private func layoutSubControllers() {
        for i in 0..<subControllers.count {
            let subController = subControllers[i]
            if i == 0 {
                subController.view.snp_makeConstraints(closure: { (make) in
                    make.top.bottom.equalTo(contentView)
                    make.leading.equalTo(contentView).offset(1)
                    for j in 1..<subControllers.count {
                        let otherController = subControllers[j]
                        make.width.equalTo(otherController.view)
                    }
                })
            } else if i > 0 && i < subControllers.count - 1 {
                subController.view.snp_makeConstraints(closure: { (make) in
                    let preController = subControllers[i - 1]
                    let nxtController = subControllers[i + 1]
                    make.top.bottom.equalTo(contentView)
                    make.leading.equalTo(preController.view.snp_trailing).offset(1)
                    make.trailing.equalTo(nxtController.view.snp_leading).offset(-1)
                })
            } else if i == subControllers.count - 1 {
                subController.view.snp_makeConstraints { (make) in
                    make.top.bottom.equalTo(contentView)
                    make.trailing.equalTo(contentView).offset(-1)
                }
            }
        }
    }
    
    private func initButton() {
        button.setTitle("S", forState: UIControlState.Normal)
        button.backgroundColor = UIColor.blackColor()
        button.layer.cornerRadius = 25.0
        button.addTarget(self, action: #selector(IFRootViewController.buttonTap(_:)), forControlEvents: UIControlEvents.TouchUpInside)
        view.addSubview(button)
        
        button.snp_makeConstraints { (make) in
            make.width.height.equalTo(50.0)
            make.right.equalTo(self.view).offset(-20.0)
            make.top.equalTo(self.view).offset(40.0)
        }
    }
    
    func buttonTap(sender: UIButton) {
        state = RootState.Small
        scrollViewHeightConstraint.updateOffset((ScreenHeight - 20) / 2.3)
        mirrorViewHeightConstraint.updateOffset((ScreenHeight - 20) / 2.3)
        mirrorViewWidthConstraint.updateOffset(CGFloat(subControllers.count) * ScreenWidth / 2.3)
        backController.view.hidden = false
        showStatusBar()
        hiddenRefreshControl()
        UIView.animateWithDuration(0.3, delay: 0.0, options: UIViewAnimationOptions.CurveEaseInOut, animations: {
            self.view.layoutIfNeeded()
            self.button.hidden = true
            self.setCornerRadius()
        }) {
            if $0 {
                self.enableScrollViewZooming()
                self.addGestureRecognizer()
                self.disableUserInteraction()
            }
        }
    }
    
}

// MARK: - UIScrollView Zooming

extension IFRootViewController {
    
    // 设置圆角
    private func setCornerRadius() {
        for subController in subControllers {
            subController.view.layer.cornerRadius = 10.0
        }
    }
    
    // 取消圆角
    private func removeCornerRadius() {
        for subController in subControllers {
            subController.view.layer.cornerRadius = 0.0
        }
    }
    
    // 缩放后禁止交互
    private func disableUserInteraction() {
        contentView.userInteractionEnabled = false
    }
    
    private func enableUserInteraction() {
        contentView.userInteractionEnabled = true
    }
    
    // 缩放后允许滚动视图放大缩少
    private func enableScrollViewZooming() {
        scrollView.pagingEnabled = false
        scrollView.minimumZoomScale = 0.3
        scrollView.maximumZoomScale = 3.0
        scrollView.pinchGestureRecognizer?.enabled = false
        scrollView.panGestureRecognizer.cancelsTouchesInView = false
    }
    
    private func disableScrollViewZooming() {
        scrollView.pagingEnabled = true
        scrollView.minimumZoomScale = 1.0
        scrollView.maximumZoomScale = 1.0
        scrollView.pinchGestureRecognizer?.enabled = false
        scrollView.panGestureRecognizer.cancelsTouchesInView = true
    }
    
    // 缩放后显示状态栏
    private func showStatusBar() {
        UIApplication.sharedApplication().setStatusBarHidden(false, withAnimation: UIStatusBarAnimation.Slide)
    }
    
    private func showRefreshControl() {
        refreshControl.hidden = false
    }
    
    private func hiddenStatusBar() {
        UIApplication.sharedApplication().setStatusBarHidden(true, withAnimation: UIStatusBarAnimation.Slide)
    }
    
    private func hiddenRefreshControl() {
        refreshControl.hidden = true
    }
    
    // 缩放后添加恢复手势
    private func addGestureRecognizer() {
        scrollView.addGestureRecognizer(scrollViewSwipeGestureRecognizer)
        scrollView.addGestureRecognizer(scrollViewTapGestureRecognizer)
    }
    
    // 恢复后移除手势
    private func removeGestureRecognizer() {
        scrollView.removeGestureRecognizer(scrollViewSwipeGestureRecognizer)
        scrollView.removeGestureRecognizer(scrollViewTapGestureRecognizer)
    }
    
    // 处理手势的方法
    func handleGestureRecognizerDirection(gestureRecognizer: UIGestureRecognizer) {
        print("handleGestureRecognizerDirection")
        state = RootState.Full
        let touchPoint = gestureRecognizer.locationInView(scrollView)
        let scaledWidth = ScreenWidth / 2.3
        let index = Int(touchPoint.x / scaledWidth)
        print(touchPoint)
        switch gestureRecognizer {
            case gestureRecognizer as UISwipeGestureRecognizer:
                scrollViewHeightConstraint.updateOffset(ScreenHeight - 20)
                mirrorViewHeightConstraint.updateOffset(ScreenHeight - 20)
                mirrorViewWidthConstraint.updateOffset(CGFloat(subControllers.count) * ScreenWidth)
            case gestureRecognizer as UITapGestureRecognizer:
                scrollViewHeightConstraint.updateOffset(ScreenHeight - 20)
                mirrorViewHeightConstraint.updateOffset(ScreenHeight - 20 )
                mirrorViewWidthConstraint.updateOffset(CGFloat(subControllers.count) * ScreenWidth)
            default:
                break
        }
        hiddenStatusBar()
        showRefreshControl()
        UIView.animateWithDuration(0.3, delay: 0.0, options: UIViewAnimationOptions.CurveEaseInOut, animations: {
            self.view.layoutIfNeeded()
            self.button.hidden = false
            self.scrollView.setContentOffset(CGPoint(x: CGFloat(index) * ScreenWidth, y: 0.0), animated: true)
            self.removeCornerRadius()
        }) {
            if $0 {
                self.disableScrollViewZooming()
                self.removeGestureRecognizer()
                self.enableUserInteraction()
                self.backController.view.hidden = true
            }
        }
    }
    
}

// MARK: - UIScrollViewDelegate

extension IFRootViewController: UIScrollViewDelegate {
    
    public func scrollViewDidScroll(scrollView: UIScrollView) {
        if case state = RootState.Full {
            let contentOffsetX = scrollView.contentOffset.x
            let index = Int(contentOffsetX / ScreenWidth)
            setupRefreshControlDelegate(index)// 设置下拉刷新的代理
            refreshControl.changeTitle(index, offsetX: contentOffsetX)// 滚动时改变顶部显示的标题
        }
    }
    
    public func viewForZoomingInScrollView(scrollView: UIScrollView) -> UIView? {
        return contentView
    }
    
}

// MARK: - UIGestureRecognizerDelegate

extension IFRootViewController: UIGestureRecognizerDelegate {
    
    public func gestureRecognizerShouldBegin(gestureRecognizer: UIGestureRecognizer) -> Bool {
        return scrollView.shouldEnableGesture
    }
    
}

// MARK: - ContentSizeDelegate

extension IFRootViewController: ContentSizeDelegate {
    
    // 缩放后，手指滑动时修改滚动视图的大小
    public func adjustContentSize(zoomScale: CGFloat) {
        if zoomScale >= 1.0 {
            scrollViewWidthConstraint.updateOffset(ScreenWidth * zoomScale)
            scrollViewHeightConstraint.updateOffset((ScreenHeight - 20) / 2.3 * zoomScale)
        } else {
            scrollViewHeightConstraint.updateOffset((ScreenHeight - 20) / 2.3 * zoomScale)
        }
        view.layoutIfNeeded()
        UIView.animateWithDuration(0.1) {
            self.view.layoutIfNeeded()
        }
    }
    
}
