//
//  Languages.swift
//  BartyCrouchKit
//
//  Created by Cihat Gündüz on 14.01.19.
//

import Foundation

enum Language: String {
    case afrikaans = "af"
    case arabic = "ar"
    case bulgarian = "bg"
    case bangla = "bn"
    case bosnian = "bs"
    case catalan = "ca"
    case czech = "cs"
    case welsh = "cy"
    case danish = "da"
    case german = "de"
    case greek = "el"
    case english = "en"
    case spanish = "es"
    case estonian = "et"
    case persian = "fa"
    case finnish = "fi"
    case filipino = "fil"
    case fijian = "fj"
    case french = "fr"
    case hebrew = "he"
    case hindi = "hi"
    case croatian = "hr"
    case haitianCreole = "ht"
    case hungarian = "hu"
    case indonesian = "id"
    case icelandic = "is"
    case italian = "it"
    case japanese = "ja"
    case korean = "ko"
    case lithuanian = "lt"
    case latvian = "lv"
    case malagasy = "mg"
    case malay = "ms"
    case maltese = "mt"
    case hmongDaw = "mww"
    case norwegian = "nb"
    case dutch = "nl"
    case queretaroOtomi = "otq"
    case polish = "pl"
    case portuguese = "pt"
    case romanian = "ro"
    case russian = "ru"
    case slovak = "sk"
    case slovenian = "sl"
    case samoan = "sm"
    case serbianCyrillic = "sr-Cyrl"
    case serbianLatin = "sr-Latn"
    case swedish = "sv"
    case kiswahili = "sw"
    case tamil = "ta"
    case telugu = "te"
    case thai = "th"
    case klingon = "tlh"
    case tongan = "to"
    case turkish = "tr"
    case tahitian = "ty"
    case ukrainian = "uk"
    case urdu = "ur"
    case vietnamese = "vi"
    case yucatecMaya = "yua"
    case cantoneseTraditional = "yue"
    case chineseSimplified = "zh-Hans"
    case chineseTraditional = "zh-Hant"

    static func with(languageCode: String, region: String?) -> Language? {
        guard let region = region else { return Language(rawValue: languageCode) }
        return Language(rawValue: "\(languageCode)-\(region)")
    }
}
