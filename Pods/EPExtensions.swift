//
//  EPExtensions.swift
//  EPContactPicker
//
//  Created by Prabaharan Elangovan on 14/10/15.
//  Copyright © 2015 Prabaharan Elangovan. All rights reserved.
//

import UIKit
import Foundation

extension String {
    subscript(r: Range<Int>) -> String? {
        get {
            let stringCount = self.characters.count as Int
            if (stringCount < r.upperBound) || (stringCount < r.lowerBound) {
                return nil
            }
            let startIndex = self.characters.index(self.startIndex, offsetBy: r.lowerBound)
            let endIndex = self.characters.index(self.startIndex, offsetBy: r.upperBound - r.lowerBound)
            return self[(startIndex ..< endIndex)]
        }
    }
    
    func containsAlphabets() -> Bool {
        //Checks if all the characters inside the string are alphabets
        let set = CharacterSet.letters
        return self.utf16.contains( where: {
            guard let unicode = UnicodeScalar($0) else { return false }
            return set.contains(unicode)
        })
    }
}

extension UIAlertController {
  func changeFont(view:UIView, font:UIFont) {
    for item in view.subviews {
      if item.isKind(of: UICollectionView.self) {
        let col = item as! UICollectionView
        for  row in col.subviews{
          changeFont(view: row, font: font)
        }
      }
      if item.isKind(of: UILabel.self) {
        let label = item as! UILabel
        label.font = font
      }else {
        changeFont(view: item, font: font)
      }
      
    }
  }
  open override func viewWillLayoutSubviews() {
    super.viewWillLayoutSubviews()
    let font = UIFont(name: "HelveticaNeue-Medium", size: 17.0)
    changeFont(view: self.view, font: font! )
  }
}
