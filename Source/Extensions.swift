//
//  ------------------------------------------------------------------------
//
//  Copyright 2016 Dan Lindholm
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//
//  ------------------------------------------------------------------------
//
//  Extensions.swift
//

import Foundation

extension UITextView {
    public var emojicaText: NSAttributedString {
        get { return self.attributedText }
        set { self.attributedText = newValue }
    }
}

extension UILabel {
    public var emojicaText: NSAttributedString? {
        get { return self.attributedText }
        set { self.attributedText = newValue }
    }
}

extension UITextInput {
    
    /// Returns the cursor offset from the end of the document.
    internal func getCursor() -> Int? {
        guard let range = self.selectedTextRange else { return nil }
        return self.offset(from: self.endOfDocument, to: range.end)
    }
    
    /// Sets the cursor to the end position offset by the given argument.
    /// - parameter offset:     The value to offset the cursor with.
    internal func setCursor(to offset: Int) {
        guard let position = self.position(from: self.endOfDocument, offset: offset) else { return }
        self.selectedTextRange = self.textRange(from: position, to: position)
    }
    
}

extension NSTextAttachment {
    /// Resizes the attachment to work well with the font.
    internal func resize(to size: CGFloat, with font: UIFont?) {
        let font = font ?? UIFont.systemFont(ofSize: size)
        let height = font.ascender - font.descender
        let side = (size + height) / 2
        let margin = (height - side) / 2
        self.bounds = CGRect(x: 0, y: font.descender + margin, width: side, height: side).integral
    }
}

extension UnicodeScalar {
    
    var isObjectReplacementCharacter: Bool { return 0xfffc == self.value }
    var isReplacementCharacter: Bool { return 0xfffd == self.value }
    var isZeroWidthJoiner: Bool { return 0x200d == self.value }
    var isVariationSelector: Bool { return 0xfe0e...0xfe0f ~= self.value }
    var isVariationSelector15: Bool { return 0xfe0e == self.value }
    var isVariationSelector16: Bool { return 0xfe0f == self.value }
    var isRegionalIndicatorSymbol: Bool { return 0x1f1e6...0x1f1ff ~= self.value }
    var isModifierSymbol: Bool { return 0x1f3fb...0x1f3ff ~= self.value }
    var isKeycapSymbol: Bool { return 0x20e3 == self.value }
    var isKeycapBase: Bool { return Unicode.keycapBaseCharacters.contains(self.value) }
    var type: EmojiHandler.ScalarType { return isZeroWidthJoiner ? .binding : .standard }
}

extension Character {
    
    var unicodeScalars: String.UnicodeScalarView { return String(self).unicodeScalars }
    
    var hasZeroWidthJoiner: Bool { return !self.unicodeScalars.filter{ $0.isZeroWidthJoiner }.isEmpty }
    var hasVariationSelector: Bool { return !self.unicodeScalars.filter{ $0.isVariationSelector }.isEmpty }
    var hasVariationSelector15: Bool { return !self.unicodeScalars.filter{ $0.isVariationSelector15 }.isEmpty }
    var hasVariationSelector16: Bool { return !self.unicodeScalars.filter{ $0.isVariationSelector16 }.isEmpty }
    var hasRegionalIndicatorSymbol: Bool { return !self.unicodeScalars.filter{ $0.isRegionalIndicatorSymbol }.isEmpty }
    var isModifierSymbol: Bool { return !self.unicodeScalars.filter{ $0.isModifierSymbol }.isEmpty }
    var hasKeycapSymbol: Bool { return !self.unicodeScalars.filter{ $0.isKeycapSymbol }.isEmpty }
    var hasKeycapBase: Bool { return !self.unicodeScalars.filter{ $0.isKeycapBase }.isEmpty }
    
    var isFlagSequence: Bool {
        let count = self.unicodeScalars.count
        return count % 2 == 0 && self.unicodeScalars.filter{ $0.isRegionalIndicatorSymbol }.count == count
    }
}

extension Character {
    
    /// A boolean value based on whether the character is emoji or not.
    /// - note: This value is false for replacement characters.
    internal var isEmoji: Bool {
        guard
            let first = self.unicodeScalars.first,
            !first.isReplacementCharacter,
            !first.isObjectReplacementCharacter
            else { return false }
        
        // The significant code point is always the first scalar.
        let codePoint = first.value
        
        switch codePoint {
        case Unicode.Block.miscellaneousSymbols.range:
            let block = Unicode.Block.miscellaneousSymbols
            return !block.nonEmoji.contains(codePoint)
            
        case Unicode.Block.dingbats.range:
            let block = Unicode.Block.dingbats
            return !block.nonEmoji.contains(codePoint)
            
        case Unicode.Block.miscellaneousSymbolsAndPictographs.range:
            let block = Unicode.Block.miscellaneousSymbolsAndPictographs
            return !block.nonEmoji.contains(codePoint)
            
        case Unicode.Block.emoticons.range:
            return true
            
        case Unicode.Block.transportAndMapSymbols.range:
            let block = Unicode.Block.transportAndMapSymbols
            return !block.nonEmoji.contains(codePoint) && !block.unassigned.contains(codePoint)
            
        case Unicode.Block.supplementalSymbolsAndPictographs.range:
            let block = Unicode.Block.supplementalSymbolsAndPictographs
            return !block.nonEmoji.contains(codePoint) && !block.unassigned.contains(codePoint)
            
        case let value where Unicode.additionalCharacters.contains(value):
            // Remove unaccompanied keycap bases.
            if first.isKeycapBase {
                guard self.hasKeycapSymbol else { return false }
            }
            return true
            
        default:
            return false
        }
    }
}



