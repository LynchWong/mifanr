//
//  IFPullRefreshControl.swift
//  mifanr
//
//  Created by Lynch Wong on 4/7/16.
//  Copyright © 2016 Lynch Wong. All rights reserved.
//

import UIKit
import SnapKit

// 刷新时执行的闭包
public typealias Task = () -> Void

// 刷新控件的类型，只实现了下拉刷新，上拉加载没实现
public enum RefreshControlType: String {
    case Header
    case Footer
}

/**
 控件的状态
 
 - Normal:         正常
 - Pulling:        拉动
 - WillRefreshing: 将要刷新
 - Refreshing:     刷新中
 - Ending:         刷新结束
 */
public enum RefreshState {
    case Normal
    case Pulling
    case WillRefreshing
    case Refreshing
    case Ending
}

// 适配了该协议的控制器能够刷新，返回滚动视图和要执行的闭包
public protocol IFPullRefreshble {
    func getPullView(refreshControl: IFPullRefreshControl) -> (pullView: UIScrollView, task: Task?)
}

// 下拉刷新的动画图片
private let imageArray = [
    UIImage(named: "fresh1")!.CGImage!,
    UIImage(named: "fresh2")!.CGImage!,
    UIImage(named: "fresh3")!.CGImage!,
    UIImage(named: "fresh4")!.CGImage!
]

// 下拉刷新的动画
private let freshAnimate: CAKeyframeAnimation = {
    let animate = CAKeyframeAnimation(keyPath: "contents")
    animate.duration = 0.4
    animate.values = imageArray
    animate.keyTimes = [NSNumber(float: 0.1), NSNumber(float: 0.2), NSNumber(float: 0.3), NSNumber(float: 0.4)]
    animate.repeatCount = MAXFLOAT
    animate.calculationMode = kCAAnimationLinear
    return animate
}()

public class IFPullRefreshControl: UIView {

    // 控件类型
    private var type: RefreshControlType
    // 顶部标题
    private var titles: [String]
    // 标题间的间隔
    private var titleSpaces: CGFloat!
    
    // 刷新的滚动视图
    public var scrollView: UIScrollView!
    // 刷新执行的闭包
    public var freshTask: Task?
    
    // 代理，对滚动视图进行KVO来实现下拉
    public var delegate: IFPullRefreshble? {
        willSet {
            if let newValue = newValue {
                scrollView = newValue.getPullView(self).pullView
                scrollView.addObserver(self, forKeyPath: "contentOffset", options: NSKeyValueObservingOptions.New, context: nil)
                scrollView.addObserver(self, forKeyPath: "contentSize", options: NSKeyValueObservingOptions.New, context: nil)
                
                freshTask = newValue.getPullView(self).task ?? nil
            }
        }
        didSet {
            if let oldValue = oldValue {
                oldValue.getPullView(self).pullView.removeObserver(self, forKeyPath: "contentOffset", context: nil)
                oldValue.getPullView(self).pullView.removeObserver(self, forKeyPath: "contentSize", context: nil)
            }
        }
    }
    
    // 红线视图
    private let redView = UIView()
    // 默认宽度
    private var redViewWidth: CGFloat = 40.0
    // 宽度约束
    private var redViewWidthConstraint: Constraint!
    
    // 刷新控件默认高度
    private var refreshControlHeight: CGFloat = 20.0
    // 高度约束
    public var refreshControlHeightConstraint: Constraint!
    
    // 装载刷新动画的视图
    private var animateContainerView = UIView()
    
    // 刷新时的文字指示标签
    private var nText = "下拉即可刷新"
    private let nLabel = UILabel()
    
    // 显示顶部标题标签的容器
    private let labelContainerView = UIView()
    // 距离左端的约束
    private var labelContainerViewLeadingConstraint: Constraint!
    
    public init(type: RefreshControlType, titles: [String]) {
        self.type = type
        self.titles = titles
        super.init(frame: CGRectZero)
        backgroundColor = UIColor.blackColor()// 设置背景色为黑色
        initializeViews()// 初始化视图
    }
    
    public override func willMoveToSuperview(newSuperview: UIView?) {
        frame = CGRect(x: 0.0, y: -20.0, width: ScreenWidth, height: 20.0)
    }
    
    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // 根据当前类型来初始化不同的视图
    private func initializeViews() {
        type == RefreshControlType.Header ? initHeaderViews() : initFooterViews()
    }
    
    // 根据当前状态来改变当前视图
    public var refreshState = RefreshState.Normal {
        didSet {
            switch refreshState {
                case .Normal:
                    setNormalState()
                case .Pulling:
                    setPullingState()
                case .WillRefreshing:
                    setWillRefreshingState()
                case .Refreshing:
                    setRefreshingState()
                case .Ending:
                    setEndingState()
            }
        }
    }
    
    private func beginRefresh() {
        
    }
    
    // 结束刷新
    public func endRefresh() {
        refreshControlHeight = 20.0
        redViewWidth = 40.0
        refreshState = .Ending
    }

}

// MARK: - 刷新相关

extension IFPullRefreshControl {
    
    public override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        if let keyPath = keyPath, change = change
            where keyPath == "contentOffset"
        {
            if let offSet = change[NSKeyValueChangeNewKey]?.CGPointValue() {
                
                // 如果处于刷新状态，直接退出
                if case refreshState = RefreshState.Refreshing {
                    return
                }
                
                // 根据拖动滚动视图的距离来设置当前控件的高度，视觉上就像是拉动了刷新控件一样
                let height = -offSet.y + 20.0
                refreshControlHeight = height < 20.0 ? 20.0 : height// 边界保护，最小值为默认高度20，即向上滚动的时候没有什么效果
                print(height)
                
                if scrollView.dragging {// 如果处于拖动状态，持续设置状态
                    if height <= 20.0 {
                        redViewWidth = 40.0
                        nText = "下拉即可刷新"
                        refreshState = .Normal
                    } else if height > 20.0 && height < 64.0 {
                        let width = (40.0 - ((height - 20.0) / 44.0) * 40.0)
                        redViewWidth = width < 1.0 ? 1.0 : width
                        nText = "下拉即可刷新"
                        refreshState = .Pulling
                    } else if height >= 64.0 {// 当高度大于64.0的时候说明已经处于阀值，松开就可以刷新了
                        redViewWidth = 1.0
                        nText = "释放即可刷新"
                        refreshState = .WillRefreshing
                    }
                } else if case refreshState = RefreshState.WillRefreshing {// 可以刷新状态
                    refreshControlHeight = 64.0
                    nText = "正在刷新..."
                    refreshState = .Refreshing
                } else {// 不是可以刷新的状态，恢复普通
                    refreshControlHeight = 20.0
                    redViewWidth = 40.0
                    refreshState = .Normal
                }
            }
        }
    }
    
    private func setNormalState() {
        layoutIfNeeded()
        UIView.animateWithDuration(0.1, animations: {
            self.refreshControlHeightConstraint.updateOffset(self.refreshControlHeight)
            self.redViewWidthConstraint.updateOffset(self.redViewWidth)
            self.labelContainerView.hidden = false
            self.nLabel.hidden = true
            self.layoutIfNeeded()
        })
    }
    
    private func setPullingState() {
        layoutIfNeeded()
        UIView.animateWithDuration(0.01, animations: {
            self.refreshControlHeightConstraint.updateOffset(self.refreshControlHeight)
            self.redViewWidthConstraint.updateOffset(self.redViewWidth)
            self.labelContainerView.hidden = true
            self.nLabel.hidden = false
            self.nLabel.text = self.nText
            self.layoutIfNeeded()
        })
    }
    
    private func setWillRefreshingState() {
        layoutIfNeeded()
        UIView.animateWithDuration(0.01, animations: {
            self.refreshControlHeightConstraint.updateOffset(self.refreshControlHeight)
            self.redViewWidthConstraint.updateOffset(self.redViewWidth)
            self.nLabel.text = self.nText
            self.layoutIfNeeded()
        })
    }
    
    private func setRefreshingState() {
        layoutIfNeeded()
        startRefreshAnimate()
        UIView.animateWithDuration(0.25, animations: {
            self.refreshControlHeightConstraint.updateOffset(self.refreshControlHeight)
            self.redViewWidthConstraint.updateOffset(self.redViewWidth)
            self.scrollView.contentInset = UIEdgeInsets(top: 44.0, left: 0.0, bottom: 0.0, right: 0.0)
            self.nLabel.text = self.nText
            self.layoutIfNeeded()
            }, completion: {
                if $0 {
                    self.excuteTask()
                }
        })
    }
    
    private func setEndingState() {
        layoutIfNeeded()
        stopRefreshAnimate()
        UIView.animateWithDuration(0.4, animations: {
            self.refreshControlHeightConstraint.updateOffset(self.refreshControlHeight)
            self.redViewWidthConstraint.updateOffset(self.redViewWidth)
            self.scrollView.contentInset = UIEdgeInsetsZero
            self.labelContainerView.hidden = false
            self.nLabel.hidden = true
            self.layoutIfNeeded()
        })
    }
    
    // 刷新执行的任务
    private func excuteTask() {
        self.freshTask?()
    }
    
}

extension IFPullRefreshControl {
    
    // 开始刷新动画
    private func startRefreshAnimate() {
        redView.hidden = true
        animateContainerView.hidden = false
        animateContainerView.layer.addAnimation(freshAnimate, forKey: "fresh")
    }
    
    // 结束刷新动画
    private func stopRefreshAnimate() {
        animateContainerView.hidden = true
        animateContainerView.layer.removeAllAnimations()
        redView.hidden = false
    }
    
}

// MARK: - 初始化控件类型是下拉刷新的视图

extension IFPullRefreshControl {
    
    private func initHeaderViews() {
        initContainerView()
        initRedView()
        initAnimateContainerView()
        initLabels()
    }
    
    private func initContainerView() {
        let width = CGFloat(titles.count) * ScreenWidth
        addSubview(labelContainerView)
        labelContainerView.snp_makeConstraints { (make) in
            labelContainerViewLeadingConstraint = make.leading.equalTo(self).constraint
            make.bottom.equalTo(self)
            make.height.equalTo(16)
            make.width.equalTo(width)
        }
    }
    
    private func initRedView() {
        redView.backgroundColor = UIColor.redColor()
        addSubview(redView)
        
        redView.snp_makeConstraints { (make) in
            make.top.equalTo(self).offset(1.0)
            make.bottom.equalTo(labelContainerView.snp_top).offset(-1.0)
            redViewWidthConstraint = make.width.equalTo(redViewWidth).constraint
            make.centerX.equalTo(self.snp_centerX)
        }
    }
    
    private func initAnimateContainerView() {
        animateContainerView.hidden = true
        addSubview(animateContainerView)
        animateContainerView.snp_makeConstraints { (make) in
            make.height.equalTo(30.0)
            make.width.equalTo(60.0)
            make.centerX.equalTo(self)
            make.top.equalTo(self).offset(9.0)
        }
    }
    
    private func initLabels() {
        
        let font = UIFont.systemFontOfSize(11)
        let attributes = [NSFontAttributeName: font]
        
        var maxSize = CGSizeZero
        for title in titles {
            let size = (title as NSString).boundingRectWithSize(CGSizeMake(1000, 16),
                                                                options: NSStringDrawingOptions.UsesLineFragmentOrigin,
                                                                attributes: attributes,
                                                                context: nil).size
            if size.width > maxSize.width {
                maxSize = size
            }
        }
        print("maxSize: \(maxSize)")
        let halfWidth = ScreenWidth / 2
        titleSpaces = halfWidth - maxSize.width * 0.5
        print("halfWidth: \(halfWidth)")
        print("titleSpaces: \(titleSpaces)")
        for i in 0..<titles.count {
            let label = UILabel()
            label.text = titles[i]
            label.textColor = UIColor.whiteColor()
            label.font = font
            label.textAlignment = NSTextAlignment.Center
            label.frame = CGRect(origin: CGPointZero, size: maxSize)
            labelContainerView.addSubview(label)
            
            let center = CGPoint(x: halfWidth + titleSpaces * CGFloat(i), y: 8.0)
            label.center = center
        }
        
        addSubview(nLabel)
        nLabel.textColor = UIColor.whiteColor()
        nLabel.textAlignment = NSTextAlignment.Center
        nLabel.font = UIFont.systemFontOfSize(11)
        nLabel.text = nText
        nLabel.hidden = true
        nLabel.snp_makeConstraints { (make) in
            make.leading.bottom.trailing.equalTo(self)
            make.height.equalTo(16)
        }
    }
    
    public func changeTitle(index: Int, offsetX: CGFloat) {
        let x = offsetX / (4 * ScreenWidth) * (CGFloat(titles.count - 1) * titleSpaces)
        print("x: \(x)")
        layoutIfNeeded()
        UIView.animateWithDuration(0.01, animations: {
            self.labelContainerViewLeadingConstraint.updateOffset(-x)
            self.layoutIfNeeded()
        })
    }
    
}

// MARK: - 初始化控件类型是上拉加载的视图 TODO: 未实现上拉加载

extension IFPullRefreshControl {
    
    private func initFooterViews() {
        
    }
    
}

//public extension UIScrollView {
//
//    private struct AssociatedKeys {
//        static var Header = "BNBHeader"
//        static var Footer = "BNBFooter"
//    }
//
//    var bnbHeader: IFPullRefreshControl? {
//        get {
//            return objc_getAssociatedObject(self, &AssociatedKeys.Header) as? IFPullRefreshControl
//        }
//        set {
//            if let newValue = newValue {
//
//                guard case newValue.type = RefreshControlType.Header else {
//                    print("RefreshControlType 不对，只能设置 .Header 类型的 BNBPullRefreshControl 给 bnbHeader 属性！")
//                    return
//                }
//
//                if let header = bnbHeader {
//                    if newValue === header {
//                        return
//                    } else {
//                        header.removeFromSuperview()
//                        self.addSubview(newValue)
//                        objc_setAssociatedObject(self,
//                                                 &AssociatedKeys.Header,
//                                                 newValue,
//                                                 objc_AssociationPolicy.OBJC_ASSOCIATION_COPY_NONATOMIC)
//                    }
//                } else {
//                    self.addSubview(newValue)
//                    objc_setAssociatedObject(self,
//                                             &AssociatedKeys.Header,
//                                             newValue,
//                                             objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
//                }
//            }
//        }
//    }
//
//    var bnbFooter: IFPullRefreshControl? {
//        get {
//            return objc_getAssociatedObject(self, &AssociatedKeys.Footer) as? IFPullRefreshControl
//        }
//        set {
//            if let newValue = newValue {
//                guard case newValue.type = RefreshControlType.Footer else {
//                    print("RefreshControlType 不对，只能设置 .Footer 类型的 BNBPullRefreshControl 给 bnbFooter 属性！")
//                    return
//                }
//
//                if let footer = bnbFooter {
//                    if newValue === footer {
//                        return
//                    } else {
//                        footer.removeFromSuperview()
//                        self.addSubview(newValue)
//                        objc_setAssociatedObject(self,
//                                                 &AssociatedKeys.Footer,
//                                                 newValue,
//                                                 objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
//                    }
//                } else {
//                    self.addSubview(newValue)
//                    objc_setAssociatedObject(self,
//                                             &AssociatedKeys.Footer,
//                                             newValue,
//                                             objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
//                }
//            }
//        }
//    }
//
//}
