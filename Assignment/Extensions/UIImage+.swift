//
//  UIImage+.swift
//  Assignment
//
//  Created by Hieu Vu on 11/1/25.
//

import Foundation
import UIKit

extension UIImageView {
    
    func makeRounded() {
        layer.borderWidth = 1
        layer.masksToBounds = false
        layer.borderColor = UIColor.gray.cgColor
        layer.cornerRadius = self.frame.height / 2
        clipsToBounds = true
    }
}
