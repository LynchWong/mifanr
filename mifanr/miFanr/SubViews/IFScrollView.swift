//
//  IFScrollView.swift
//  mifanr
//
//  Created by Lynch Wong on 4/7/16.
//  Copyright © 2016 Lynch Wong. All rights reserved.
//

import UIKit

public protocol ContentSizeDelegate {
    func adjustContentSize(zoomScale: CGFloat)
}

public class IFScrollView: UIScrollView {
    
    public var contentSizeDelegate: ContentSizeDelegate?
    public var shouldEnableGesture = true
    public var zoom: CGFloat = 1.0
    
    public var scaleAble: Bool {
        return maximumZoomScale > minimumZoomScale
    }


    public override func touchesShouldCancelInContentView(view: UIView) -> Bool {
        print("touchesShouldBegin")
        return true
    }
    
    public override func touchesShouldBegin(touches: Set<UITouch>, withEvent event: UIEvent?, inContentView view: UIView) -> Bool {
        print("touchesShouldBegin")
        return true
    }
    
    public override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        print("touchesBegan")
        shouldEnableGesture = false
    }
    
    public override func touchesMoved(touches: Set<UITouch>, withEvent event: UIEvent?) {
        print("touchesMoved")
        if scaleAble {
            let previousLocation = touches.first?.previousLocationInView(self)
            let currentLocation = touches.first?.locationInView(self)
            if let currentLocation = currentLocation, previousLocation = previousLocation
                where fabs(currentLocation.y - previousLocation.y) > fabs(currentLocation.x - previousLocation.x) {
                if currentLocation.y - previousLocation.y > 0 {
                    zoom -= 0.01
                } else {
                    zoom += 0.01
                }
                setZoomScale(zoom, animated: true)
                contentSizeDelegate?.adjustContentSize(zoom)
            }
        }
    }
    
    public override func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?) {
        print("touchesEnded")
        if scaleAble {
            zoom = 1.0
            setZoomScale(zoom, animated: true)
            contentSizeDelegate?.adjustContentSize(zoomScale)
        }
        shouldEnableGesture = true
    }
    
    public override func touchesCancelled(touches: Set<UITouch>?, withEvent event: UIEvent?) {
        print("touchesCancelled")
        if scaleAble {
            zoom = 1.0
            setZoomScale(zoom, animated: true)
            contentSizeDelegate?.adjustContentSize(zoomScale)
        }
        shouldEnableGesture = true
    }

}
