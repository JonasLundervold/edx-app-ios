//
//  CropViewController.swift
//  edX
//
//  Created by Michael Katz on 10/19/15.
//  Copyright © 2015 edX. All rights reserved.
//

import Foundation

private class CircleView: UIView {
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = OEXStyles.sharedStyles().neutralBlack().colorWithAlphaComponent(0.8)
        userInteractionEnabled = false
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    var circleBounds: CGRect {
        let rect = bounds
        let minSize = min(rect.width, rect.height)
        let hole = CGRectInset(CGRect(x: (rect.width - minSize) / 2, y: (rect.height - minSize) / 2, width: minSize, height: minSize), 6, 6)
        return hole
    }
    
    private override func drawRect(rect: CGRect) {
        let context = UIGraphicsGetCurrentContext()
        CGContextSaveGState(context)
        
        let hole = circleBounds
        CGContextAddEllipseInRect(context, hole);
        CGContextClip(context);
        CGContextClearRect(context, hole);
        CGContextSetFillColorWithColor( context, UIColor.clearColor().CGColor);
        CGContextFillRect( context, hole);
        CGContextSetStrokeColorWithColor(context, OEXStyles.sharedStyles().neutralLight().CGColor)
        CGContextStrokeEllipseInRect(context, hole)
        CGContextRestoreGState(context)
    }
}

class CropViewController: UIViewController {
    
    var image: UIImage
    
    let imageView: UIImageView
    let scrollView: UIScrollView
    let completion: UIImage -> Void
    private let circleView: CircleView
    
    init(image: UIImage, completion: UIImage -> Void) {
        self.image = image
        self.completion = completion
        imageView = UIImageView(image: image)
        scrollView = UIScrollView()
        circleView = CircleView()
        
        super.init(nibName: nil, bundle: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        scrollView.addSubview(imageView)
        scrollView.contentSize = image.size
        scrollView.delegate = self
        
        view.addSubview(scrollView)
        view.backgroundColor = OEXStyles.sharedStyles().neutralBlack()
        
        let toolbar = UIToolbar()
        toolbar.barTintColor = UIColor.clearColor()
        toolbar.tintColor = OEXStyles.sharedStyles().neutralWhiteT()
        let cancel = UIBarButtonItem(barButtonSystemItem: .Cancel, target: nil, action: nil)
        cancel.oex_setAction() {
            if let nav = self.navigationController {
                nav.popViewControllerAnimated(true)
            } else {
                self.dismissViewControllerAnimated(true, completion: nil)
            }
        }
        let choose = UIBarButtonItem(title: "Choose", style: .Plain, target: nil, action: nil)
        choose.oex_setAction() { [weak self] in
            let rect = self!.circleView.circleBounds
            let shift = CGRectApplyAffineTransform(rect, CGAffineTransformMakeTranslation(self!.scrollView.contentOffset.x, self!.scrollView.contentOffset.y))
            let scaled = CGRectApplyAffineTransform(shift, CGAffineTransformMakeScale(1.0 / self!.scrollView.zoomScale, 1.0 / self!.scrollView.zoomScale))
            let newImage = self?.image.imageCroppedToRect(scaled)
            self?.completion(newImage!)
        }
        let flex = UIBarButtonItem(barButtonSystemItem: .FlexibleSpace, target: nil, action: nil)
        var items = [cancel, flex, choose]
        if toolbar.isRightToLeft {
            items = items.reverse()
        }
        toolbar.items = items
        
        view.addSubview(circleView)
        view.addSubview(toolbar)
        
        scrollView.snp_makeConstraints { (make) -> Void in
            make.top.equalTo(view)
            make.left.equalTo(view)
            make.right.equalTo(view)
            make.bottom.equalTo(view)
        }
        
        toolbar.snp_makeConstraints { (make) -> Void in
            make.leading.equalTo(view)
            make.trailing.equalTo(view)
            make.bottom.equalTo(view)
            make.height.equalTo(50)
        }
        
        
        circleView.snp_makeConstraints { (make) -> Void in
            make.edges.equalTo(scrollView)
        }
        
        let tap = UITapGestureRecognizer(target: self, action: "zoomOut")
        tap.numberOfTapsRequired = 2
        scrollView.addGestureRecognizer(tap)
        
        UIApplication.sharedApplication().setStatusBarStyle(UIStatusBarStyle.Default, animated: false)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        
        let scrollFrame = scrollView.frame
        let hole = circleView.circleBounds
        
        let imSize = image.size
        guard hole.width > 0 else { return }
        
        let verticalRatio = hole.height / imSize.height
        let horizontalRatio = hole.width / imSize.width
        
        scrollView.minimumZoomScale = max(horizontalRatio, verticalRatio)
        scrollView.maximumZoomScale = 1
        scrollView.zoomScale = scrollView.minimumZoomScale
        
        let insetHeight = (scrollFrame.height - hole.height) / 2
        let insetWidth = (scrollFrame.width - hole.width) / 2
        scrollView.contentInset = UIEdgeInsetsMake(insetHeight, insetWidth, insetHeight, insetWidth)
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}

extension CropViewController: UIScrollViewDelegate {
    func zoomOut() {
        let newScale = scrollView.zoomScale == scrollView.minimumZoomScale ? 0.5 : scrollView.minimumZoomScale
        scrollView.setZoomScale(newScale, animated: true)
    }
    
    func viewForZoomingInScrollView(scrollView: UIScrollView) -> UIView? {
        return imageView
    }
    
    func scrollViewDidEndZooming(scrollView: UIScrollView, withView view: UIView?, atScale scale: CGFloat) {
        //need empty implementation for zooming
    }
}