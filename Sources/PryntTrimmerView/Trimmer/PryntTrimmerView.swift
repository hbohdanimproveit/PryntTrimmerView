//
//  PryntTrimmerView.swift
//  PryntTrimmerView
//
//  Created by HHK on 27/03/2017.
//  Copyright © 2017 Prynt. All rights reserved.
//

import AVFoundation
import UIKit

public protocol TrimmerViewDelegate: class {
    func didChangePositionBar(_ playerTime: CMTime)
    func positionBarStoppedMoving(_ playerTime: CMTime)
}

/// A view to select a specific time range of a video. It consists of an asset preview with thumbnails inside a scroll view, two
/// handles on the side to select the beginning and the end of the range, and a position bar to synchronize the control with a
/// video preview, typically with an `AVPlayer`.
/// Load the video by setting the `asset` property. Access the `startTime` and `endTime` of the view to get the selected time
// range
@IBDesignable public class TrimmerView: AVAssetTimeSelector {
    
    // MARK: - Properties
    
    // MARK: Color Customization
    
    /// The color of the main border of the view
    @IBInspectable public var mainColor: UIColor = UIColor.orange {
        didSet {
            updateMainColor()
        }
    }
    
    /// The color of the handles on the side of the view
    @IBInspectable public var leftHandleColor: UIColor = UIColor.blue {
        didSet {
            leftHandleKnob.backgroundColor = leftHandleColor
        }
    }
    
    /// The color of the handles on the side of the view
    @IBInspectable public var rightHandleColor: UIColor = UIColor.gray {
        didSet {
            rightHandleKnob.backgroundColor = rightHandleColor
        }
    }
    
    /// The bool for handles appearance on the side of the view
    @IBInspectable public var isHiddenHandleViews: Bool = false {
        didSet {
            rightHandleView.isHidden = isHiddenHandleViews
            leftHandleView.isHidden = isHiddenHandleViews
            leftHandleKnob.isHidden = isHiddenHandleViews
            rightHandleKnob.isHidden = isHiddenHandleViews
            trimView.isHidden = isHiddenHandleViews
            isHandlesEnabled = isHiddenHandleViews ? false : isHandlesEnabled
        }
    }
    
    /// The bool for marks handle appearance on the side of the view
    @IBInspectable public var isHiddenMarksHandleViews: Bool = false {
        didSet {
            leftMarkHandlerView.isHidden = isHiddenMarksHandleViews
            rightMarkHandlerView.isHidden = isHiddenMarksHandleViews
            leftMarkImageView.isHidden = isHiddenMarksHandleViews
            rightMarkImageView.isHidden = isHiddenMarksHandleViews
            isMarksEnabled = isHiddenMarksHandleViews ? false : isMarksEnabled
        }
    }
    
    /// The bool for position bar appearance on the side of the view
    @IBInspectable public var isHiddenPositionBar: Bool = false {
        didSet {
            positionBar.isHidden = isHiddenPositionBar
            isPositionBarEnabled = isHiddenPositionBar ? false : isPositionBarEnabled
        }
    }
    
    /// The bool used to handle views user interaction
    @IBInspectable public var isHandlesEnabled: Bool = true {
        didSet {
            leftHandleView.gestureRecognizers?.first?.isEnabled = isHandlesEnabled
            rightHandleView.gestureRecognizers?.first?.isEnabled = isHandlesEnabled
        }
    }
    
    /// The bool used to position bar views user interaction
    @IBInspectable public var isPositionBarEnabled: Bool = true {
        didSet {
            positionBar.gestureRecognizers?.first?.isEnabled = isPositionBarEnabled
        }
    }
    
    /// The bool used to mark handle views user interaction
    @IBInspectable public var isMarksEnabled: Bool = true {
        didSet {
            leftMarkHandlerView.gestureRecognizers?.first?.isEnabled = isMarksEnabled
            rightMarkHandlerView.gestureRecognizers?.first?.isEnabled = isMarksEnabled
        }
    }
    
    
    /// The color of the position indicator
    @IBInspectable public var positionBarColor: UIColor = UIColor.white {
        didSet {
            positionBar.backgroundColor = positionBarColor
        }
    }
    
    /// The color used to mask unselected parts of the video
    @IBInspectable public var maskColor: UIColor = UIColor.black.withAlphaComponent(0.4) {
        didSet {
            leftMaskView.backgroundColor = maskColor
            rightMaskView.backgroundColor = maskColor
        }
    }
    
    /// The image of the left mark view
    @IBInspectable public var leftMarkImage: UIImage = UIImage() {
        didSet {
            leftMarkImageView.image = leftMarkImage
        }
    }
    /// The image of the right mark view
    @IBInspectable public var rightMarkImage: UIImage = UIImage() {
        didSet {
            rightMarkImageView.image = rightMarkImage
        }
    }
    
    // MARK: Interface
    
    public weak var delegate: TrimmerViewDelegate?
    
    // MARK: Subviews
    
    private let trimView = UIView()
    private let leftHandleView = HandlerView()
    private let rightHandleView = HandlerView()
    private let positionBar = HandlerView()
    private let leftHandleKnob = UIView()
    private let rightHandleKnob = UIView()
    private let leftMaskView = UIView()
    private let leftMarkHandlerView = HandlerView()
    private let rightMarkHandlerView = HandlerView()
    private let leftMarkImageView = UIImageView()
    private let rightMarkImageView = UIImageView()
    private let rightMaskView = UIView()
    
    // MARK: Constraints
    
    private var currentLeftConstraint: CGFloat = .zero
    private var currentRightConstraint: CGFloat = .zero
    private var currentPositionBarConstraint: CGFloat = .zero
    private var leftConstraint: NSLayoutConstraint?
    private var rightConstraint: NSLayoutConstraint?
    private var positionConstraint: NSLayoutConstraint?
    private var isHandlesViewEnabled: Bool = false
    private let handleWidth: CGFloat = 15
    
    /// The minimum duration allowed for the trimming. The handles won't pan further if the minimum duration is attained.
    public var minDuration: Double = 3
    public var positionBarAnimationDuration: Double = 0.1
    
    // MARK: - View & constraints configurations
    
    override func setupSubviews() {
        super.setupSubviews()
        layer.cornerRadius = 2
        layer.masksToBounds = true
        backgroundColor = UIColor.clear
        layer.zPosition = 1
        setupTrimmerView()
        setupHandleView()
        setupMaskView()
        setupMarksHanlderView()
        setupPositionBar()
        
        setupGestures()
        updateMainColor()
    }
    
    override func constrainAssetPreview() {
        assetPreview.leftAnchor.constraint(equalTo: leftAnchor, constant: handleWidth).isActive = true
        assetPreview.rightAnchor.constraint(equalTo: rightAnchor, constant: -handleWidth).isActive = true
        assetPreview.topAnchor.constraint(equalTo: topAnchor, constant: 9).isActive = true
        assetPreview.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -9).isActive = true
    }
    
    public func setHandleSubviewPosition(isSelectedMark: Bool) {
        if isSelectedMark {
            insertSubview(leftMarkHandlerView, aboveSubview: leftHandleView)
            insertSubview(rightMarkHandlerView, aboveSubview: rightHandleView)
        } else {
            insertSubview(leftHandleView, aboveSubview: leftMarkHandlerView)
            insertSubview(rightHandleView, aboveSubview: rightMarkHandlerView)
        }
    }
    
    private func setupTrimmerView() {
        trimView.layer.borderWidth = 2.0
        trimView.layer.cornerRadius = 2.0
        trimView.translatesAutoresizingMaskIntoConstraints = false
        trimView.isUserInteractionEnabled = false
        addSubview(trimView)
        
        trimView.topAnchor.constraint(equalTo: topAnchor).isActive = true
        trimView.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
        leftConstraint = trimView.leftAnchor.constraint(equalTo: leftAnchor)
        rightConstraint = trimView.rightAnchor.constraint(equalTo: rightAnchor)
        leftConstraint?.isActive = true
        rightConstraint?.isActive = true
    }
    
    private func setupHandleView() {
        leftHandleView.isUserInteractionEnabled = true
        leftHandleView.layer.cornerRadius = 2.0
        leftHandleView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(leftHandleView)
        
        leftHandleView.heightAnchor.constraint(equalTo: heightAnchor, multiplier: 0.9).isActive = true
        leftHandleView.widthAnchor.constraint(equalToConstant: handleWidth).isActive = true
        leftHandleView.leftAnchor.constraint(equalTo: trimView.leftAnchor).isActive = true
        leftHandleView.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        
        leftHandleKnob.translatesAutoresizingMaskIntoConstraints = false
        leftHandleView.addSubview(leftHandleKnob)
        
        leftHandleKnob.heightAnchor.constraint(equalTo: heightAnchor, multiplier: 0.5).isActive = true
        leftHandleKnob.widthAnchor.constraint(equalToConstant: 2).isActive = true
        leftHandleKnob.centerYAnchor.constraint(equalTo: leftHandleView.centerYAnchor).isActive = true
        leftHandleKnob.centerXAnchor.constraint(equalTo: leftHandleView.centerXAnchor).isActive = true
        
        rightHandleView.isUserInteractionEnabled = true
        rightHandleView.layer.cornerRadius = 2.0
        rightHandleView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(rightHandleView)
        
        rightHandleView.heightAnchor.constraint(equalTo: heightAnchor, multiplier: 0.9).isActive = true
        rightHandleView.widthAnchor.constraint(equalToConstant: handleWidth).isActive = true
        rightHandleView.rightAnchor.constraint(equalTo: trimView.rightAnchor).isActive = true
        rightHandleView.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        
        rightHandleKnob.translatesAutoresizingMaskIntoConstraints = false
        rightHandleView.addSubview(rightHandleKnob)
        
        rightHandleKnob.heightAnchor.constraint(equalTo: heightAnchor, multiplier: 0.5).isActive = true
        rightHandleKnob.widthAnchor.constraint(equalToConstant: 2).isActive = true
        rightHandleKnob.centerYAnchor.constraint(equalTo: rightHandleView.centerYAnchor).isActive = true
        rightHandleKnob.centerXAnchor.constraint(equalTo: rightHandleView.centerXAnchor).isActive = true
    }
    
    private func setupMarksHanlderView() {
        leftMarkHandlerView.isUserInteractionEnabled = true
        leftMarkHandlerView.layer.cornerRadius = 2.0
        leftMarkHandlerView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(leftMarkHandlerView)
        
        leftMarkHandlerView.topAnchor.constraint(equalTo: topAnchor).isActive = true
        leftMarkHandlerView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -11).isActive = true
        leftMarkHandlerView.widthAnchor.constraint(equalToConstant: handleWidth).isActive = true
        leftMarkHandlerView.leftAnchor.constraint(equalTo: trimView.leftAnchor).isActive = true
        
        leftMarkImageView.translatesAutoresizingMaskIntoConstraints = false
        leftMarkHandlerView.addSubview(leftMarkImageView)
        
        leftMarkImageView.topAnchor.constraint(equalTo: leftMarkHandlerView.topAnchor).isActive = true
        leftMarkImageView.bottomAnchor.constraint(equalTo: leftMarkHandlerView.bottomAnchor).isActive = true
        leftMarkImageView.widthAnchor.constraint(equalToConstant: 8).isActive = true
        leftMarkImageView.centerXAnchor.constraint(equalTo: leftMarkHandlerView.centerXAnchor).isActive = true
        
        rightMarkHandlerView.isUserInteractionEnabled = true
        rightMarkHandlerView.layer.cornerRadius = 2.0
        rightMarkHandlerView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(rightMarkHandlerView)
        
        rightMarkHandlerView.topAnchor.constraint(equalTo: topAnchor).isActive = true
        rightMarkHandlerView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -11).isActive = true
        rightMarkHandlerView.widthAnchor.constraint(equalToConstant: handleWidth).isActive = true
        rightMarkHandlerView.rightAnchor.constraint(equalTo: trimView.rightAnchor).isActive = true
        
        rightMarkImageView.translatesAutoresizingMaskIntoConstraints = false
        rightMarkHandlerView.addSubview(rightMarkImageView)
        
        rightMarkImageView.topAnchor.constraint(equalTo: rightMarkHandlerView.topAnchor).isActive = true
        rightMarkImageView.bottomAnchor.constraint(equalTo: rightMarkHandlerView.bottomAnchor).isActive = true
        rightMarkImageView.widthAnchor.constraint(equalToConstant: 8).isActive = true
        rightMarkImageView.centerXAnchor.constraint(equalTo: rightMarkHandlerView.centerXAnchor).isActive = true
    }
    
    private func setupMaskView() {
        leftMaskView.isUserInteractionEnabled = false
        leftMaskView.backgroundColor = maskColor
        
        leftMaskView.translatesAutoresizingMaskIntoConstraints = false
        insertSubview(leftMaskView, belowSubview: leftHandleView)
        
        leftMaskView.leftAnchor.constraint(equalTo: leftAnchor).isActive = true
        leftMaskView.rightAnchor.constraint(equalTo: leftHandleView.centerXAnchor).isActive = true
        leftMaskView.bottomAnchor.constraint(equalTo: assetPreview.bottomAnchor).isActive = true
        leftMaskView.topAnchor.constraint(equalTo: assetPreview.topAnchor).isActive = true
        
        rightMaskView.isUserInteractionEnabled = false
        rightMaskView.backgroundColor = maskColor
        rightMaskView.translatesAutoresizingMaskIntoConstraints = false
        insertSubview(rightMaskView, belowSubview: rightHandleView)
        
        rightMaskView.leftAnchor.constraint(equalTo: rightHandleView.centerXAnchor).isActive = true
        rightMaskView.rightAnchor.constraint(equalTo: rightAnchor).isActive = true
        rightMaskView.bottomAnchor.constraint(equalTo: assetPreview.bottomAnchor).isActive = true
        rightMaskView.topAnchor.constraint(equalTo: assetPreview.topAnchor).isActive = true
    }
    
    private func setupPositionBar() {
        positionBar.hitFramePoint = -10
        positionBar.frame = CGRect(x: 0, y: 0, width: 3, height: frame.height)
        positionBar.backgroundColor = positionBarColor
        positionBar.center = CGPoint(x: leftHandleView.frame.maxX, y: center.y)
        positionBar.layer.cornerRadius = 1
        positionBar.translatesAutoresizingMaskIntoConstraints = false
        positionBar.isUserInteractionEnabled = false
        addSubview(positionBar)
        
        positionBar.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        positionBar.widthAnchor.constraint(equalToConstant: 3).isActive = true
        positionBar.heightAnchor.constraint(equalTo: heightAnchor).isActive = true
        positionConstraint = positionBar.leftAnchor.constraint(equalTo: leftHandleView.rightAnchor, constant: 0)
        positionConstraint?.isActive = true
    }
    
    private func setupGestures() {
        let leftPanGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(TrimmerView.handlePanGesture))
        let rightPanGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(TrimmerView.handlePanGesture))
        let positionBarPanGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(TrimmerView.handlePanGesture))
        let leftMarkGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(TrimmerView.handlePanGesture))
        let rightMarkGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(TrimmerView.handlePanGesture))
        
        leftHandleView.addGestureRecognizer(leftPanGestureRecognizer)
        rightHandleView.addGestureRecognizer(rightPanGestureRecognizer)
        positionBar.addGestureRecognizer(positionBarPanGestureRecognizer)
        leftMarkHandlerView.addGestureRecognizer(leftMarkGestureRecognizer)
        rightMarkHandlerView.addGestureRecognizer(rightMarkGestureRecognizer)
    }
    
    private func updateMainColor() {
        trimView.layer.borderColor = UIColor.clear.cgColor
        leftHandleView.backgroundColor = mainColor
        rightHandleView.backgroundColor = mainColor
    }
    
    // MARK: - Trim Gestures
    
    @objc func handlePanGesture(_ gestureRecognizer: UIPanGestureRecognizer) {
        guard let view = gestureRecognizer.view,
            let superView = gestureRecognizer.view?.superview else { return }
        
        switch gestureRecognizer.state {
        case .began:
            switch view {
            case leftHandleView:
                currentLeftConstraint = leftConstraint!.constant
            case rightHandleView:
                currentRightConstraint = rightConstraint!.constant
            case positionBar:
                currentPositionBarConstraint = positionConstraint!.constant
            case leftMarkHandlerView:
                currentLeftConstraint = leftConstraint!.constant
            case rightMarkHandlerView:
                currentRightConstraint = rightConstraint!.constant
            default:
                break
            }
            
            updateSelectedTime(stoppedMoving: false)
        case .changed:
            let translation = gestureRecognizer.translation(in: superView)
            switch view {
            case leftHandleView, leftMarkHandlerView:
                updateLeftConstraint(with: translation)
            case rightHandleView, rightMarkHandlerView:
                updateRightConstraint(with: translation)
            case positionBar:
                updatePositionConstraint(with: translation)
            default:
                break
            }
            
            layoutIfNeeded()
            
            switch view {
            case leftHandleView, leftMarkHandlerView:
                if let startTime = startTime {
                    seek(to: startTime)
                }
            case rightHandleView, rightMarkHandlerView:
                if let endTime = endTime {
                    seek(to: endTime)
                }
            case positionBar:
                if let startTime = thumbTime {
                    seek(to: startTime)
                }
            default:
                break
            }
            
            updateSelectedTime(stoppedMoving: false)
            
        case .cancelled, .ended, .failed:
            updateSelectedTime(stoppedMoving: true)
        default: break
        }
    }
    
    private func updateLeftConstraint(with translation: CGPoint) {
        let maxConstraint = max(rightHandleView.frame.origin.x - handleWidth - minimumDistanceBetweenHandle, 0)
        let newConstraint = min(max(0, currentLeftConstraint + translation.x), maxConstraint)
        leftConstraint?.constant = newConstraint
    }
    
    private func updateRightConstraint(with translation: CGPoint) {
        let maxConstraint = min(2 * handleWidth - frame.width + leftHandleView.frame.origin.x + minimumDistanceBetweenHandle, 0)
        let newConstraint = max(min(0, currentRightConstraint + translation.x), maxConstraint)
        rightConstraint?.constant = newConstraint
    }
    
    private func updatePositionConstraint(with translation: CGPoint) {
        let maxConstraint = max(rightHandleView.frame.origin.x - handleWidth, 0)
        let newConstraint = min(max(0, currentPositionBarConstraint + translation.x), maxConstraint)
        positionConstraint?.constant = newConstraint
    }
    
    // MARK: - Asset loading
    
    override func assetDidChange(newAsset: AVAsset?) {
        super.assetDidChange(newAsset: newAsset)
        resetHandleViewPosition()
    }
    
    private func resetHandleViewPosition() {
        leftConstraint?.constant = 0
        rightConstraint?.constant = 0
        layoutIfNeeded()
    }
    
    // MARK: - Time Equivalence
    
    /// Move the position bar to the given time.
    public func seek(to time: CMTime) {
        if let newPosition = getPosition(from: time) {
            
            let offsetPosition = newPosition - assetPreview.contentOffset.x - leftHandleView.frame.origin.x
            let maxPosition = rightHandleView.frame.origin.x - (leftHandleView.frame.origin.x + handleWidth) - positionBar.frame.width
            let normalizedPosition = min(max(0, offsetPosition), maxPosition)
            self.positionConstraint?.constant = normalizedPosition
            
            UIView.animate(withDuration: positionBarAnimationDuration, animations: {
                guard let startTime = self.startTime,
                    let endTime = self.endTime,
                    time > startTime && time < endTime  else { return }
                
                self.layoutIfNeeded()
            })
        }
    }
    
    /// The selected start time for the current asset.
    public var startTime: CMTime? {
        let startPosition = leftHandleView.frame.origin.x + assetPreview.contentOffset.x
        return getTime(from: startPosition)
    }
    
    /// The selected end time for the current asset.
    public var endTime: CMTime? {
        let endPosition = rightHandleView.frame.origin.x + assetPreview.contentOffset.x - handleWidth
        return getTime(from: endPosition)
    }
    
    public var thumbTime: CMTime? {
        let thumbPosition = positionBar.frame.origin.x - handleWidth
        return getTime(from: thumbPosition)
    }
    
    private func updateSelectedTime(stoppedMoving: Bool) {
        guard let playerTime = positionBarTime else {
            return
        }
        if stoppedMoving {
            delegate?.positionBarStoppedMoving(playerTime)
        } else {
            delegate?.didChangePositionBar(playerTime)
        }
    }
    
    private var positionBarTime: CMTime? {
        let barPosition = positionBar.frame.origin.x + assetPreview.contentOffset.x - handleWidth
        return getTime(from: barPosition)
    }
    
    private var minimumDistanceBetweenHandle: CGFloat {
        guard let asset = asset else { return 0 }
        return CGFloat(minDuration) * assetPreview.contentView.frame.width / CGFloat(asset.duration.seconds)
    }
    
    // MARK: - Scroll View Delegate
    
    public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        updateSelectedTime(stoppedMoving: true)
    }
    
    public func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if !decelerate {
            updateSelectedTime(stoppedMoving: true)
        }
    }
    
    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        updateSelectedTime(stoppedMoving: false)
    }
}
