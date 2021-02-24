//
//  StringExtensions.swift
//
//  Created by Hamry.
//

import Foundation

// MARK: - calculate Height
public extension String {
    /// Calculates the height a label will need in order to display the String for the given width and font.
    ///
    /// - Parameters:
    ///   - width: Max width of the bounding rect
    ///   - font: Font used to render the string
    /// - Returns: Height a string will need to be completely visible
    func height(forConstrainedWidth width: CGFloat, font: UIFont) -> CGFloat {
        let constraintRect = CGSize(width: width, height: .greatestFiniteMagnitude)
        let boundingBox = self.boundingRect(with: constraintRect, options: [.usesLineFragmentOrigin, .usesFontLeading], attributes: [.font: font], context: nil)
        return boundingBox.height
    }
}

// MARK: - UIColor
import CoreGraphics
extension String {
    /// 解析color色值. "#FFFFFF"
    /// - Returns: (red, green, blue)，不能解析的返回(0, 0, 0)
  func hexColorComponents() -> (red: CGFloat, green: CGFloat, blue: CGFloat) {
    var cString:String = trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
    if (cString.hasPrefix("#")) {
      cString.remove(at: cString.startIndex)
    }
    if ((cString.count) != 6) {
      return (red: 0, green: 0, blue: 0)
    }
    var rgbValue:UInt32 = 0
    Scanner(string: cString).scanHexInt32(&rgbValue)
    return (red: CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0,
            green: CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0,
            blue: CGFloat(rgbValue & 0x0000FF) / 255.0)
  }
}

// MARK: - MD5
import CommonCrypto
extension String {
    /// 得到string的md5值.
    /// - Returns: md5
    func md5() -> String {
        guard let data = self.data(using: .utf8) else {
            return base
        }
        #if swift(>=5.0)
        let message = data.withUnsafeBytes { (bytes: UnsafeRawBufferPointer) in
            return [UInt8](bytes)
        }
        #else
        let message = data.withUnsafeBytes { bytes in
            return [UInt8](UnsafeBufferPointer(start: bytes, count: data.count))
        }
        #endif
        let MD5Calculator = MD5(message)
        let MD5Data = MD5Calculator.calculate()

        var MD5String = String()
        for c in MD5Data {
            MD5String += String(format: "%02x", c)
        }
        return MD5String
    }
    /// 同 API: - "md5()".
    func md5Generate() -> String {
        let str = self.cString(using: String.Encoding.utf8)
        let strLen = CUnsignedInt(self.lengthOfBytes(using: String.Encoding.utf8))
        let digestLen = Int(CC_MD5_DIGEST_LENGTH)
        let result = UnsafeMutablePointer<CUnsignedChar>.allocate(capacity: digestLen)
        CC_MD5(str!, strLen, result)
        let hash = NSMutableString()
        for i in 0 ..< digestLen {
            hash.appendFormat("%02x", result[i])
        }
        result.deallocate()
        return String(format: hash as String)
    }
}

// MARK: - 中文、拼音操作
extension String {
    /// 是否包含中文.
    /// - Returns: true: 包含； false：不包含
    func isIncludeChinese() -> Bool {
        for ch in self.unicodeScalars {     // 中文字符范围：0x4e00 ~ 0x9fff
            if (0x4e00 < ch.value && ch.value < 0x9fff) {
                return true
            }
        }
        return false
    }
    /// 意义同 API:"isIncludeChinese()"
    func containsChineseCharacters() -> Bool {
        return self.range(of: "\\p{Han}", options: .regularExpression) != nil
    }
    /// 转换成拼音
    /// - Returns: 拼音
    func transformToPinyin() -> String {
        let stringRef = NSMutableString(string: self) as CFMutableString   // 转换为带音标的拼音
        CFStringTransform(stringRef,nil, kCFStringTransformToLatin, false);   // 去掉音标
        CFStringTransform(stringRef, nil, kCFStringTransformStripCombiningMarks, false);
        let pinyin = stringRef as String;     return pinyin
    }
    /// 转换成无空格的拼音
    /// - Returns: 无空格拼音
    func transformToPinyinWithoutBlank() -> String {
        var pinyin = self.transformToPinyin()   // 去掉空格
        pinyin = pinyin.replacingOccurrences(of: " ", with: "")
        return pinyin
    }
    /// 字符串转换为首字母大写
    /// - Returns: 首字母，大写，否则返回#.
    func getPinyinHead() -> String {
        let pinyin = self.transformToPinyin().uppercased()
        guard let char = pinyin.first else { return "#" }
        guard char.asciiValue != nil else { return "#" }
        return String(char)
    }
    
}

// MARK: - 和Json互转.
extension String {
    /// 把json字符串转化成json.
    public static func convertJsonStringToHash(from: String?) -> [String : Any]? {
        guard let _from = from else { return nil }
        let data = _from.data(using: .utf8)
        if let _data = data {
            if let json = try? JSONSerialization.jsonObject(with: _data, options: .mutableContainers) as? [String : Any] {
                return json
            }
        }
        return nil
    }
    /// 把json字典转化成String.
    public static func convertJsonHashToString(from: [String : Any]?) -> String? {
        guard let _from = from else { return nil }
        if let data = try? JSONSerialization.data(withJSONObject: _from, options: .prettyPrinted),
            let jsonStr = String.init(data: data, encoding: .utf8) {
            return jsonStr
        }
        return nil
    }
}

// MARK: - Range，NSRange
extension String {
    /// NSRange转化为Range
    func toRange(from nsRange: NSRange) -> Range<String.Index>? {
        guard
            let from16 = utf16.index(utf16.startIndex, offsetBy: nsRange.location, limitedBy: utf16.endIndex),
            let to16 = utf16.index(from16, offsetBy: nsRange.length, limitedBy: utf16.endIndex),
            let from = String.Index(from16, within: self),
            let to = String.Index(to16, within: self)
            else { return nil }
        return from ..< to
    }
    /// Range转NSRange.
    func toNSRange(_ range: Range<String.Index>) -> NSRange {
        guard let from = range.lowerBound.samePosition(in: utf16), let to = range.upperBound.samePosition(in: utf16) else {
            return NSMakeRange(0, 0)
        }
        return NSMakeRange(utf16.distance(from: utf16.startIndex, to: from), utf16.distance(from: from, to: to))
    }
}

// MARK: - 时间
extension String {
    /// 毫秒转"HH:mm:ss"
    /// - Parameter miSec: 毫秒
    /// - Returns: "HH:mm:ss"
    static func getHourMinuteSectionStyleStringFrom(miSec: Int64) -> String {
        let secondsValue = Int64(miSec/1000)
        let hour = secondsValue/3600
        let hourStr = hour < 10 ? "0\(hour)" : "\(hour)"
        let minutes = secondsValue%3600/60
        let minutesStr = minutes < 10 ? "0\(minutes)" : "\(minutes)"
        let seconds = secondsValue%3600%60
        let secondsStr = seconds < 10 ? "0\(seconds)" : "\(seconds)"
        let time = hourStr + ":" + minutesStr + ":" + secondsStr
        return time
    }
}
