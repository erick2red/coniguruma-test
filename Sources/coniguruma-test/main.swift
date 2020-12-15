import Foundation

import Darwin
import coniguruma

enum StandardError: Error {
    case generic(String)
}

struct Encodings {
    static let utf8: OnigEncoding = UnsafeMutablePointer<OnigEncodingType>(&OnigEncodingUTF8)
    static let ascii: OnigEncoding = UnsafeMutablePointer<OnigEncodingType>(&OnigEncodingASCII)
}

public final class OnigRegularExpression {
    var regexPointer: OnigRegex?

    public init(from pattern: String) throws {
        Self.initialize()

        guard let patternChars = pattern.cString(using: .utf8)?.map({ c in UInt8(c) }) else {
            throw StandardError.generic("Pattern \"\(pattern)\" can't be processed")
        }

        regexPointer = nil
        var error = OnigErrorInfo()
        patternChars.withUnsafeBufferPointer({ patternPointer in
            let result = onig_new(&regexPointer,
                                  patternPointer.baseAddress,
                                  patternPointer.baseAddress?.advanced(by: patternPointer.count),
                                  OnigOptionType(),
                                  Encodings.utf8,
                                  OnigDefaultSyntax,
                                  &error)

            if result != ONIG_NORMAL {
                print("Initialization failed with error: \(result)")
            }
        })
    }

    public func match(string source: String) throws {
        guard let sourceChars = source.cString(using: .utf8)?.map({ c in UInt8(c) }) else {
            throw StandardError.generic("Source \"\(source)\" can't be processed")
        }

        let region = onig_region_new()
        defer {
            onig_region_free(region, 1 /* 1:free self, 0:free contents only */)
        }

        try sourceChars.withUnsafeBufferPointer({ charsPointer in
            let result = onig_search(regexPointer,
                                     charsPointer.baseAddress,
                                     charsPointer.baseAddress?.advanced(by: charsPointer.count),
                                     charsPointer.baseAddress,
                                     charsPointer.baseAddress?.advanced(by: charsPointer.count),
                                     region,
                                     ONIG_OPTION_NONE)

            if result >= 0 {
                guard let region = region else {
                    throw StandardError.generic("onig_search failed with: \(result) but region is nil")
                }

                print("[\(#function)#\(#line)] match found at: \(result)")
                let numberOfMatchers = region.pointee.num_regs
                for i in 0..<numberOfMatchers {
                    let start = region.pointee.beg[Int(i)]
                    let end = region.pointee.end[Int(i)]
                    print("Match[\(i)] starts at: \(start) and ends at: \(end)")
                }
            }
            else if result == ONIG_MISMATCH {
                //FIXME: return not found
                throw StandardError.generic("Initialization failed with error: \(result)")
            } else {
                throw StandardError.generic("Initialization failed with error: \(result)")
            }
        })
    }

    public class func search(pattern string: String, in source: String) throws {
        guard let patternChars = string.cString(using: .utf8)?.map({ c in UInt8(c) }) else {
            throw StandardError.generic("Pattern \"\(string)\" can't be processed")
        }
        guard let sourceChars = source.cString(using: .utf8)?.map({ c in UInt8(c) }) else {
            throw StandardError.generic("Source \"\(source)\" can't be processed")
        }

        initialize()

        var regexPointer: OnigRegex? = nil
        var error = OnigErrorInfo()
        var encoding = OnigEncodingUTF8
        patternChars.withUnsafeBufferPointer({ patternPointer in
            let result = onig_new(&regexPointer,
                                  patternPointer.baseAddress,
                                  patternPointer.baseAddress?.advanced(by: patternPointer.count),
                                  OnigOptionType(),
                                  &encoding,
                                  OnigDefaultSyntax,
                                  &error)

            if result != ONIG_NORMAL {
                print("Initialization failed with error: \(result)")
            }
        })

        let region = onig_region_new()
        defer {
            onig_region_free(region, 1 /* 1:free self, 0:free contents only */)
        }

        try sourceChars.withUnsafeBufferPointer({ charsPointer in
            let result = onig_search(regexPointer,
                                     charsPointer.baseAddress,
                                     charsPointer.baseAddress?.advanced(by: charsPointer.count),
                                     charsPointer.baseAddress,
                                     charsPointer.baseAddress?.advanced(by: charsPointer.count),
                                     region,
                                     ONIG_OPTION_NONE)

            if result >= 0 {
                guard let region = region else {
                    throw StandardError.generic("onig_search failed with: \(result) but region is nil")
                }

                print("[\(#function)#\(#line)] match found at: \(result)")
                let numberOfMatchers = region.pointee.num_regs
                for i in 0..<numberOfMatchers {
                    let start = region.pointee.beg[Int(i)]
                    let end = region.pointee.end[Int(i)]
                    print("Match[\(i)] starts at: \(start) and ends at: \(end)")
                }
            }
            else if result == ONIG_MISMATCH {
                //FIXME: return not found
                throw StandardError.generic("Initialization failed with error: \(result)")
            } else {
                throw StandardError.generic("Initialization failed with error: \(result)")
            }
        })
    }

    class func initialize() {
        var encs: UnsafeMutablePointer<OnigEncodingTypeST>? = Encodings.utf8
        _ = onig_initialize(&encs, 1)
    }
}


try? OnigRegularExpression.search(pattern: "a(.*)b|[e-f]+", in: "zzzzaffffffffb")
print("Works!!")

if let t = try? OnigRegularExpression(from: "a(.*)b|[e-f]+") {
    print("Constructor worked")
    try? t.match(string: "zzzzaffffffffb")
    print("Worked?")
}

if let versionStr = onig_version() {
    let ver = String(cString: versionStr)
    print("Oniguruma version is: \(ver)")
}

print("Bye!")
