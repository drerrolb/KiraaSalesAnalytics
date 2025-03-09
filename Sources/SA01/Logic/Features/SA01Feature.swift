//
//  SA01Feature.swift
//  kiraa-sales-analytics
//
//  Created by Errol Brandt on 21/2/2025.
//


import Foundation
import os.log


enum SA01Feature: String, CaseIterable {
    
    case SA01F01 = "SA01F01"
    case SA01F02 = "SA01F02"
    case SA01F03 = "SA01F03"
    case SA01F04 = "SA01F04"
    case SA01F05 = "SA01F05"
    case SA01F06 = "SA01F06"
    case SA01F07 = "SA01F07"
    case SA01F08 = "SA01F08"
    case SA01F09 = "SA01F09"
    case SA01F10 = "SA01F10"
    case SA01F11 = "SA01F11"
    case SA01F12 = "SA01F12"
    case SA01F13 = "SA01F13"
    case SA01F14 = "SA01F14"
    case SA01F15 = "SA01F15"
    case SA01F16 = "SA01F16"
    case SA01F17 = "SA01F17"
    case SA01F18 = "SA01F18"
    case SA01F19 = "SA01F19"
    case SA01F20 = "SA01F20"
    case SA01F21 = "SA01F21"
    case SA01F22 = "SA01F22"
    case SA01F23 = "SA01F23"
    case SA01F24 = "SA01F24"
    case SA01F25 = "SA01F25"
    case SA01F26 = "SA01F26"
    case SA01F27 = "SA01F27"
    case SA01F28 = "SA01F28"
    case SA01F29 = "SA01F29"
    case SA01F30 = "SA01F30"
    case SA01F31 = "SA01F31"
    case SA01F32 = "SA01F32"
    case SA01F33 = "SA01F33"
    case SA01F34 = "SA01F34"
    case SA01F35 = "SA01F35"
    case SA01F36 = "SA01F36"
    case SA01F37 = "SA01F37"
    case SA01F38 = "SA01F38"
    case SA01F39 = "SA01F39"
    case SA01F40 = "SA01F40"
    case SA01F41 = "SA01F41"
    case SA01F42 = "SA01F42"
    case SA01F43 = "SA01F43"
    case SA01F44 = "SA01F44"
    case SA01F45 = "SA01F45"
    case SA01F46 = "SA01F46"
    case SA01F47 = "SA01F47"
    case SA01F48 = "SA01F48"
    case SA01F49 = "SA01F49"
    case SA01F50 = "SA01F50"
    case SA01F51 = "SA01F51"
    case SA01F52 = "SA01F52"
    case SA01F53 = "SA01F53"
    case SA01F54 = "SA01F54"
    case SA01F55 = "SA01F55"
    case SA01F56 = "SA01F56"
    case SA01F57 = "SA01F57"
    case SA01F58 = "SA01F58"
    case SA01F59 = "SA01F59"
    case SA01F60 = "SA01F60"
    case SA01F61 = "SA01F61"
    case SA01F62 = "SA01F62"
    case SA01F63 = "SA01F63"
    case SA01F64 = "SA01F64"
    case SA01F65 = "SA01F65"
    case SA01F66 = "SA01F66"
    case SA01F67 = "SA01F67"
    case SA01F68 = "SA01F68"
    case SA01F69 = "SA01F69"
    case SA01F70 = "SA01F70"
    case SA01F71 = "SA01F71"
    case SA01F72 = "SA01F72"
    case SA01F73 = "SA01F73"
    case SA01F74 = "SA01F74"
    case SA01F75 = "SA01F75"
    case SA01F76 = "SA01F76"
    case SA01F77 = "SA01F77"
    case SA01F78 = "SA01F78"
    case SA01F79 = "SA01F79"
    case SA01F80 = "SA01F80"
    case SA01F81 = "SA01F81"
    case SA01F82 = "SA01F82"
    case SA01F83 = "SA01F83"
    case SA01F84 = "SA01F84"
    case SA01F85 = "SA01F85"
    case SA01F86 = "SA01F86"
    case SA01F87 = "SA01F87"
    case SA01F88 = "SA01F88"
    case SA01F89 = "SA01F89"
    case SA01F90 = "SA01F90"
    case SA01F91 = "SA01F91"
    case SA01F92 = "SA01F92"
    case SA01F93 = "SA01F93"
    case SA01F94 = "SA01F94"
    case SA01F95 = "SA01F95"
    case SA01F96 = "SA01F96"
    case SA01F97 = "SA01F97"
    case SA01F98 = "SA01F98"
    case SA01F99 = "SA01F99"
    
    // additional intersections
    
    case SA01F01F11 = "SA01F01F11"
    case SA01F02F03 = "SA01F02F03"
    case SA01F02F04 = "SA01F02F04"
    case SA01F03F02 = "SA01F03F02"
    case SA01F03F04 = "SA01F03F04"
    case SA01F03F07 = "SA01F03F07"
    case SA01F03F16 = "SA01F03F16"
    case SA01F03F17 = "SA01F03F17"
    case SA01F04F02 = "SA01F04F02"
    case SA01F04F03 = "SA01F04F03"
    case SA01F06F07 = "SA01F06F07"
    case SA01F06F08 = "SA01F06F08"
    case SA01F06F12 = "SA01F06F12"
    case SA01F06F17 = "SA01F06F17"
    case SA01F07F03 = "SA01F07F03"
    case SA01F07F06 = "SA01F07F06"
    case SA01F08F06 = "SA01F08F06"
    case SA01F11F01 = "SA01F11F01"
    case SA01F12F06 = "SA01F12F06"
    case SA01F16F03 = "SA01F16F03"
    case SA01F16F17 = "SA01F16F17"
    case SA01F17F03 = "SA01F17F03"
    case SA01F17F06 = "SA01F17F06"
    case SA01F17F16 = "SA01F17F16"
    
    
    var title: String {
        return "title_\(self.rawValue)"
    }

    var article: String {
        return "article_\(self.rawValue)"
    }

    // append the field name to the Article field value
    func articleContent(fieldContent: String) -> String {
        return "[[<prefix>:\(fieldContent)|\(fieldContent)]]"
    }
    
    func toDictionary(fieldContent: String) -> [String: Any] {
        return [
            "featureName": self.rawValue,
            "titleFeatureType": self.title,
            "articleFeatureType": articleContent(fieldContent: fieldContent)
        ]
    }
}
