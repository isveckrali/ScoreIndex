import UIKit



enum ScoreIndex {
    
    static func run() {
        let input =  "[({(<(())[]>[[{[]{<()<>> [(()[<>])]({[<{<<[]>>( {([(<{}[<>[]}>{[]{[(<()> (((({<>}<{<{<>}{[]{[]{} [[<[([]))<([[{}[[()]]] [{[{({}]{}}([{[{{{}}([] {<[[]]>}<{[{[{[]{()[[[] [<(<(<(<{}))><([]([]() <{([([[(<>()){}]>(<<{{ <{([{{}}[<[[[<>{}]]]>[]]"
        var lineScores: [Int] = []
        let lines = input.lines
        for line in lines {
            var lineScore = 0
            do {
                print("Processing line: \(line) \n\t", terminator: "")
                var program = ProgramStack()
                for char in line {
                    try program.parse(char)
                }

                if program.isIncomplete {
                    let autocompleteSequence = program.autocomplete()
                    lineScore = autocompleteScore(autocompleteSequence)
                    print("autocomplete sequence: \(autocompleteSequence) ==> \(lineScore)")
                }
            } catch ProgramStack.Errors.corruptedChunk(let tag) {
                print("Corrupted Chunk on tag: \(tag)")
            } catch {
                print("Error with line: \(error)")
            }
            print("Line score: \(lineScore)")
            if lineScore > 0 {
                lineScores.append(lineScore)
            }
        }
        let totalScore = lineScores.sorted()[(lineScores.count - 1) / 2]
        print("Syntax error score for file: \(totalScore)")
    }
}

func autocompleteScore(_ sequence: [Character]) -> Int {
    let scores: [Character: Int] = [
        ")": 1,
        "]": 2,
        "}": 3,
        ">": 4
    ]

    return sequence.reduce(0) { total, character in
        total * 5 + scores[character]!
    }
}

func syntaxErrorScore(_ tag: Character) -> Int {
    [
        ")" : 3,
        "]" : 57,
        "}" : 1197,
        ">" : 25137
    ][tag] ?? 0
}

struct ProgramStack {
    private var openTags: [Character] = []
    private let validOpenTags = "([{<"
    private let validCloseTags = ")]}>"

    enum Errors: Error {
        case invalidTag(Character)
        case corruptedChunk(Character)
    }

    var isIncomplete: Bool {
        !openTags.isEmpty
    }

    func autocomplete() -> [Character] {
        var sequence: [Character] = []
        var tags = openTags
        while let openTag = tags.popLast() {
            let index = validOpenTags.firstIndex(of: openTag)!
            let closeTag = validCloseTags[index]
            sequence.append(closeTag)
        }
        return sequence
    }

    mutating func parse(_ tag: Character) throws {
        if validOpenTags.contains(tag) {
            try push(tag)
        } else if validCloseTags.contains(tag) {
            try pop(tag)
        } else {
            throw Errors.invalidTag(tag)
        }
    }

    mutating func push(_ tag: Character) throws {
        openTags.append(tag)
    }

    mutating func pop(_ tag: Character) throws {
        let index = validCloseTags.firstIndex(of: tag)!
        let openTag = validOpenTags[index]
        if openTags.last == openTag {
            openTags.removeLast()
        } else {
            throw Errors.corruptedChunk(tag)
        }
    }
}

extension String {
    var lines: [String] {
        split(separator: " ").map { $0.trimmingCharacters(in: .whitespaces) }
    }
}

extension Int {
    init?<S: CustomStringConvertible>(_ s: S) {
        guard let int = Int(s.description) else { return nil }
        self = int
    }
}

ScoreIndex.run()
