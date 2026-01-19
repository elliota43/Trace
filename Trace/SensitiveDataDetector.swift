import Foundation

struct SensitiveRange: Identifiable {
    let id = UUID()
    let range: Range<String.Index>
    let type: SecretType
}

enum SecretType {
    case email, ipAddress, apiKey, creditCard
    case phoneNumber, address, link // <--- NEW TYPES
}

class SensitiveDataDetector {
    
    // 1. CUSTOM PATTERNS (Things Apple misses)
    static let patterns: [SecretType: String] = [
        .email: "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}",
        .ipAddress: "\\b(?:\\d{1,3}\\.){3}\\d{1,3}\\b",
        .apiKey: "(sk_live_[0-9a-zA-Z]{24,})|(ghp_[0-9a-zA-Z]{36})",
    ]
    
    static func findSecrets(in text: String) -> [SensitiveRange] {
        var detected: [SensitiveRange] = []
        
        // PHASE 1: Run "Dumb" Regex (For Developer Keys)
        for (type, pattern) in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern) {
                let matches = regex.matches(in: text, range: NSRange(text.startIndex..., in: text))
                
                for match in matches {
                    if let range = Range(match.range, in: text) {
                        detected.append(SensitiveRange(range: range, type: type))
                    }
                }
            }
        }
        
        // PHASE 2: Run "Smart" Apple Detector (For Human Info)
        // We ask for: Phone Numbers, Addresses, and Links
        let types: NSTextCheckingResult.CheckingType = [.phoneNumber, .address, .link]
        
        if let detector = try? NSDataDetector(types: types.rawValue) {
            let matches = detector.matches(in: text, options: [], range: NSRange(text.startIndex..., in: text))
            
            for match in matches {
                if let range = Range(match.range, in: text) {
                    
                    var type: SecretType?
                    
                    switch match.resultType {
                    case .phoneNumber: type = .phoneNumber
                    case .address:     type = .address
                    case .link:        type = .link
                    default:           break
                    }
                    
                    if let type = type {
                        detected.append(SensitiveRange(range: range, type: type))
                    }
                }
            }
        }
        
        return detected
    }
}
