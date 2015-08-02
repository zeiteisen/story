import UIKit

extension UIView {
    func shake() {
        let animation = CAKeyframeAnimation(keyPath: "transform.translation.x")
        animation.timingFunctions = [CAMediaTimingFunction(name: kCAMediaTimingFunctionLinear)]
        animation.duration = 0.6
        animation.values = [-20, 20, -20, 20, -10, 10, -5, 5, 0]
        layer.addAnimation(animation, forKey: "shake")
    }
}