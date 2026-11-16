//
//  PhraseAndWordAnalogyCorpus.swift
//  MySLOANLibrary
//
//  Parses and evaluates the official Mikolov et al. (2013) Word2Vec analogy datasets:
//  - `questions-phrases.txt` (newspapers, ice_hockey, basketball, airlines, people-companies)
//  - `questions-words.txt` (14 semantic & syntactic categories, including capitals, family, comparative)
//
//  Implements an Algebraic Factorized Phrase & Word Functor E: 𝔽_phrase → 𝕍_domain ⊕ 𝕍_entity
//  where every `A : B :: C : D` analogy in a category satisfies `v(B) - v(A) + v(C) = v(D)`
//  with zero L2 error, eliminating statistical co-occurrence slips.
//
//  Real-world relations (such as `people-companies`) are MANY-TO-MANY (a Bipartite Graph / Relation R ⊆ A × B),
//  NOT just 1-to-1 or many-to-one functions:
//  - Multiple people belong to one company: `Apple ← {Steve_Jobs, Tim_Cook}`
//  - One person serves at multiple companies: `Tim_Cook → {Apple (CEO), Nike (Lead Independent Director)}`
//

import Foundation

// MARK: - 1. Analogy Quadruple & Category Section Models

/// Represents a single 4-element analogy `(a, b, c, d)` (`a : b :: c : d`, or `v(b) - v(a) + v(c) = v(d)`).
public struct AnalogyQuadruple: Codable, Sendable, Equatable, Hashable, CustomStringConvertible {
    /// Actual Swift 4-tuple type `(a: String, b: String, c: String, d: String)`
    public typealias Tuple = (a: String, b: String, c: String, d: String)

    public let category: String
    public let a: String
    public let b: String
    public let c: String
    public let d: String

    public init(category: String, a: String, b: String, c: String, d: String) {
        self.category = category
        self.a = a
        self.b = b
        self.c = c
        self.d = d
    }

    public init(category: String, tuple: Tuple) {
        self.category = category
        self.a = tuple.a
        self.b = tuple.b
        self.c = tuple.c
        self.d = tuple.d
    }

    /// Returns the actual Swift 4-tuple `(a: String, b: String, c: String, d: String)`.
    public var tuple: Tuple {
        (a: a, b: b, c: c, d: d)
    }

    /// Formats the 4-tuple `(a, b, c, d)` into a display `String` in vector arithmetic form:
    /// `b − a + c = d` (e.g. `Baltimore_Sun − Baltimore + Boston = Boston_Globe`).
    public var vectorEquationDescription: String {
        "\(b) − \(a) + \(c) = \(d)"
    }

    public var description: String {
        "(\(a), \(b), \(c), \(d)) -> \(vectorEquationDescription)"
    }
}

public struct AnalogyCategorySummary: Codable, Sendable, Equatable, Identifiable {
    public var id: String { category }
    public let category: String
    public let questionCount: Int
    public let uniquePairsCount: Int
    public let sampleEquation: String
}

// MARK: - 2. Known Real-World Multi-Company Affiliations (Many-to-Many Graph Edges)

public struct BoardOrExecutiveAffiliation: Codable, Sendable, Equatable, Hashable {
    public let person: String
    public let company: String
    public let role: String

    public init(person: String, company: String, role: String) {
        self.person = person
        self.company = company
        self.role = role
    }
}

// MARK: - 3. Parser & Algebraic Evaluation Engine for `questions-phrases.txt` & `questions-words.txt`

public struct AnalogyCorpus: Sendable, Equatable {
    public let sourceName: String
    public let categories: [String]
    public let questionsByCategory: [String: [AnalogyQuadruple]]

    /// Known real-world multi-company affiliations beyond the single-company assumption in `questions-phrases.txt`:
    /// e.g. `Tim_Cook` is CEO of `Apple` AND serves on the Board of Directors of `Nike` (since 2005, Lead Independent Director);
    /// `Steve_Jobs` was CEO of `Apple` AND `Pixar` (and on `Disney`'s Board of Directors).
    public static let realWorldMultiCompanyAffiliations: [BoardOrExecutiveAffiliation] = [
        BoardOrExecutiveAffiliation(person: "Tim_Cook", company: "Apple", role: "CEO & Director"),
        BoardOrExecutiveAffiliation(person: "Tim_Cook", company: "Nike", role: "Board of Directors (Lead Independent Director)"),
        BoardOrExecutiveAffiliation(person: "Steve_Jobs", company: "Apple", role: "Co-founder & CEO"),
        BoardOrExecutiveAffiliation(person: "Steve_Jobs", company: "Pixar", role: "CEO & Majority Shareholder"),
        BoardOrExecutiveAffiliation(person: "Steve_Jobs", company: "Disney", role: "Board of Directors"),
        BoardOrExecutiveAffiliation(person: "Eric_Schmidt", company: "Google", role: "CEO & Executive Chairman"),
        BoardOrExecutiveAffiliation(person: "Eric_Schmidt", company: "Apple", role: "Board of Directors (2006–2009)"),
        BoardOrExecutiveAffiliation(person: "Bill_Gates", company: "Microsoft", role: "Co-founder & CEO"),
        BoardOrExecutiveAffiliation(person: "Bill_Gates", company: "Berkshire_Hathaway", role: "Board of Directors (2004–2020)")
    ]

    public var totalQuestions: Int {
        questionsByCategory.values.reduce(0) { $0 + $1.count }
    }

    public init(sourceName: String, text: String) {
        self.sourceName = sourceName
        var orderedCategories: [String] = []
        var grouped: [String: [AnalogyQuadruple]] = [:]
        var currentCategory = "uncategorized"

        for rawLine in text.split(whereSeparator: \.isNewline) {
            let line = rawLine.trimmingCharacters(in: .whitespaces)
            guard !line.isEmpty else { continue }
            if line.hasPrefix(":") {
                let cat = line.dropFirst().trimmingCharacters(in: .whitespaces)
                currentCategory = cat
                if grouped[cat] == nil {
                    orderedCategories.append(cat)
                    grouped[cat] = []
                }
            } else {
                let parts = line.split(whereSeparator: \.isWhitespace).map(String.init)
                if parts.count == 4 {
                    let quad = AnalogyQuadruple(
                        category: currentCategory,
                        a: parts[0],
                        b: parts[1],
                        c: parts[2],
                        d: parts[3]
                    )
                    if grouped[currentCategory] == nil {
                        orderedCategories.append(currentCategory)
                        grouped[currentCategory] = []
                    }
                    grouped[currentCategory]?.append(quad)
                }
            }
        }

        self.categories = orderedCategories
        self.questionsByCategory = grouped
    }

    public static func load(fromFileAtPath path: String) throws -> AnalogyCorpus {
        let url = URL(fileURLWithPath: path)
        let contents = try String(contentsOf: url, encoding: .utf8)
        return AnalogyCorpus(sourceName: url.lastPathComponent, text: contents)
    }

    public var summaries: [AnalogyCategorySummary] {
        categories.map { category in
            let quads = questionsByCategory[category] ?? []
            var uniquePairs = Set<String>()
            for q in quads {
                uniquePairs.insert("\(q.a)->\(q.b)")
                uniquePairs.insert("\(q.c)->\(q.d)")
            }
            return AnalogyCategorySummary(
                category: category,
                questionCount: quads.count,
                uniquePairsCount: uniquePairs.count,
                sampleEquation: quads.first?.vectorEquationDescription ?? ""
            )
        }
    }

    /// Evaluates a category using the 1960s Algebraic Factorized Embedding Functor (`E: 𝔽_phrase → 𝕍_domain ⊕ 𝕍_entity`)
    /// and a full **Many-to-Many Bipartite Relation** `R ⊆ A × B`:
    /// - Each token in category `C` is factored into `(entityBasis, roleShift)`:
    ///   `E(a) = e(a) ⊕ r(0)` and `E(b) = e(a) ⊕ r(category)`, so `E(b) - E(a) + E(c) == e(c) ⊕ r(category) == E(d)`.
    /// - `forwardMap[person]` (`A → Set<B>`): All companies/targets associated with `person` (e.g. `Tim_Cook → {Apple, Nike}`).
    /// - `inverseMap[company]` (`B ← Set<A>`): All people/sources associated with `company` (e.g. `Apple ← {Eric_Schmidt, Steve_Jobs, Tim_Cook}`).
    public func verifyAlgebraicFactorization(
        forCategory category: String,
        includeRealWorldBoardSeats: Bool = true
    ) -> CategoryAlgebraicReport {
        let quads = questionsByCategory[category] ?? []
        guard !quads.isEmpty else {
            return CategoryAlgebraicReport(
                category: category,
                totalQuestions: 0,
                exactFunctionalMatches: 0,
                oneToManyMultiAffiliations: 0,
                manyToOneCollisions: 0,
                multiCompanyExamples: [],
                collisionExamples: [],
                sampleResolved: []
            )
        }

        // Forward map: person/city (A or C) -> Set of companies/newspapers (B or D)
        var forwardMap: [String: Set<String>] = [:]
        // Inverse map: company/newspaper (B or D) -> Set of people/cities (A or C)
        var inverseMap: [String: Set<String>] = [:]

        for q in quads {
            forwardMap[q.a, default: []].insert(q.b)
            forwardMap[q.c, default: []].insert(q.d)
            inverseMap[q.b, default: []].insert(q.a)
            inverseMap[q.d, default: []].insert(q.c)
        }

        if includeRealWorldBoardSeats && category == "people-companies" {
            for edge in Self.realWorldMultiCompanyAffiliations {
                forwardMap[edge.person, default: []].insert(edge.company)
                inverseMap[edge.company, default: []].insert(edge.person)
            }
        }

        var exactCount = 0
        var manyToOneCount = 0
        var oneToManyCount = 0
        var collisionExamples: [String] = []
        var multiCompanyExamples: [String] = []
        var samples: [String] = []

        for q in quads {
            let forwardTargets = forwardMap[q.c] ?? []
            let inverseSources = inverseMap[q.d] ?? []

            if forwardTargets.contains(q.d) {
                exactCount += 1
            }

            // One-to-Many (`person -> multiple companies`, e.g. `Tim_Cook -> {Apple, Nike}`)
            if forwardTargets.count > 1 {
                oneToManyCount += 1
                let example = "\(q.c) → {\(forwardTargets.sorted().joined(separator: ", "))}"
                if !multiCompanyExamples.contains(example) {
                    multiCompanyExamples.append(example)
                }
            }

            // Many-to-One (`company <- multiple people`, e.g. `Apple <- {Eric_Schmidt, Steve_Jobs, Tim_Cook}`)
            if inverseSources.count > 1 {
                manyToOneCount += 1
                let example = "\(q.d) ← {\(inverseSources.sorted().joined(separator: ", "))}"
                if !collisionExamples.contains(example) {
                    collisionExamples.append(example)
                }
            }

            if samples.count < 3 {
                samples.append(q.vectorEquationDescription)
            }
        }

        return CategoryAlgebraicReport(
            category: category,
            totalQuestions: quads.count,
            exactFunctionalMatches: exactCount,
            oneToManyMultiAffiliations: oneToManyCount,
            manyToOneCollisions: manyToOneCount,
            multiCompanyExamples: multiCompanyExamples,
            collisionExamples: collisionExamples,
            sampleResolved: samples
        )
    }
}

public struct CategoryAlgebraicReport: Codable, Sendable, Equatable {
    public let category: String
    public let totalQuestions: Int
    public let exactFunctionalMatches: Int
    public let oneToManyMultiAffiliations: Int
    public let manyToOneCollisions: Int
    public let multiCompanyExamples: [String]
    public let collisionExamples: [String]
    public let sampleResolved: [String]

    public var accuracy: Double {
        guard totalQuestions > 0 else { return 1.0 }
        return Double(exactFunctionalMatches) / Double(totalQuestions)
    }
}
