import Foundation

class SmartNamer {
    
    static let stopWords = [
        "File", "Edit", "View", "History", "Window", "Help",
        "Chrome", "Safari", "http", "https", "www", "com", "Login"
    ]
    
    // Tokens that suggest this line is code, not prose
    static let codeIndicators = [
        "func ", "var ", "let ", "const ", "class ", "struct ", "import ",
        "#include", "def ", "pub fn", "=>", "return", "{", "}", "://", "git"
    ]
    
    static func generateTitle(from ocrText: String, appName: String) -> String {
        let lines = ocrText.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        
        for line in lines {
            // 1. Check for Code
            // If it looks like code, RETURN IT RAW. Do not clean it.
            if isCode(line) {
                // Return up to 50 chars of the code line
                return String(line.prefix(50))
            }
            
            // 2. Standard Filters (as before)
            if line.count < 4 { continue }
            if isMenuBar(line) { continue }
            
            // 3. Clean Text (Only if it's NOT code)
            let cleanLine = cleanArtifacts(from: line)
            if cleanLine.count > 4 {
                return cleanLine
            }
        }
        
        return appName
    }
    
    // --- HEURISTICS ---
    
    private static func isCode(_ line: String) -> Bool {
        // Check for specific keywords
        for indicator in codeIndicators {
            if line.contains(indicator) { return true }
        }
        
        // Check for CamelCase or snake_case (typical in code, rare in prose)
        let hasCamel = line.contains { $0.isUppercase } && line.contains { $0.isLowercase } && !line.contains(" ")
        let hasSnake = line.contains("_")
        
        return hasCamel || hasSnake
    }
    
    private static func isMenuBar(_ line: String) -> Bool {
        let words = line.components(separatedBy: .whitespaces)
        let intersection = words.filter { stopWords.contains($0) }
        return intersection.count >= 2
    }
    
    private static func cleanArtifacts(from line: String) -> String {
        // We only clean "Text" artifacts. We leave code symbols alone now.
        var text = line
        let noise = ["|", "—", "•", "»", "«"] // Removed "_" from noise list
        for char in noise {
            text = text.replacingOccurrences(of: char, with: "")
        }
        return text.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
