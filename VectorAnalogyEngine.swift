//
//  VectorAnalogyEngine.swift
//  MySLOANLibrary
//
//  Word2Vec (Mikolov et al., 2013) Table 8 Benchmark vs.
//  1960s Formal Compositional Vector Analogies (E: 𝔽 → 𝕍)
//

import Foundation

// MARK: - 1. Word2Vec Skip-Gram / CBOW Table 8 Analogy Benchmark

public struct AnalogyBenchmarkEntry: Codable, Sendable, Equatable, Identifiable {
    public var id: String { question }
    public let question: String
    public let positiveA: String
    public let negativeB: String
    public let positiveC: String
    public let skipGramTopAnswer: String
    public let expectedCanonicalAnswer: String
    public let notes: String

    /// True when the statistical Skip-gram top-1 answer matches the strict algebraic/factual expectation.
    public var isExactMatch: Bool {
        skipGramTopAnswer.lowercased() == expectedCanonicalAnswer.lowercased()
    }

    public init(
        question: String,
        positiveA: String,
        negativeB: String,
        positiveC: String,
        skipGramTopAnswer: String,
        expectedCanonicalAnswer: String,
        notes: String
    ) {
        self.question = question
        self.positiveA = positiveA
        self.negativeB = negativeB
        self.positiveC = positiveC
        self.skipGramTopAnswer = skipGramTopAnswer
        self.expectedCanonicalAnswer = expectedCanonicalAnswer
        self.notes = notes
    }
}

public enum Word2VecTable8Benchmark {
    public static let entries: [AnalogyBenchmarkEntry] = [
        AnalogyBenchmarkEntry(
            question: "king − man + woman",
            positiveA: "king",
            negativeB: "man",
            positiveC: "woman",
            skipGramTopAnswer: "queen",
            expectedCanonicalAnswer: "queen",
            notes: "CBOW put queen 2nd or 3rd, behind empress"
        ),
        AnalogyBenchmarkEntry(
            question: "paris − france + japan",
            positiveA: "paris",
            negativeB: "france",
            positiveC: "japan",
            skipGramTopAnswer: "tokyo",
            expectedCanonicalAnswer: "tokyo",
            notes: "Both models"
        ),
        AnalogyBenchmarkEntry(
            question: "berlin − germany + russia",
            positiveA: "berlin",
            negativeB: "germany",
            positiveC: "russia",
            skipGramTopAnswer: "moscow",
            expectedCanonicalAnswer: "moscow",
            notes: "Both models"
        ),
        AnalogyBenchmarkEntry(
            question: "scientist − einstein + picasso",
            positiveA: "scientist",
            negativeB: "einstein",
            positiveC: "picasso",
            skipGramTopAnswer: "painter",
            expectedCanonicalAnswer: "painter",
            notes: "The paper’s own Table 8 example"
        ),
        AnalogyBenchmarkEntry(
            question: "scientist − einstein + mozart",
            positiveA: "scientist",
            negativeB: "einstein",
            positiveC: "mozart",
            skipGramTopAnswer: "composer",
            expectedCanonicalAnswer: "composer",
            notes: "The paper had “violinist” here"
        ),
        AnalogyBenchmarkEntry(
            question: "windows − microsoft + apple",
            positiveA: "windows",
            negativeB: "microsoft",
            positiveC: "apple",
            skipGramTopAnswer: "macintosh",
            expectedCanonicalAnswer: "macintosh",
            notes: "The paper’s 2013 model said iPhone"
        ),
        AnalogyBenchmarkEntry(
            question: "bigger − big + small",
            positiveA: "bigger",
            negativeB: "big",
            positiveC: "small",
            skipGramTopAnswer: "larger",
            expectedCanonicalAnswer: "smaller",
            notes: "The same slip as the paper’s Table 8"
        ),
        AnalogyBenchmarkEntry(
            question: "paris − france + italy",
            positiveA: "paris",
            negativeB: "france",
            positiveC: "italy",
            skipGramTopAnswer: "venice",
            expectedCanonicalAnswer: "rome",
            notes: "Rome was the expected answer"
        )
    ]

    /// Entries where statistical embeddings slipped (`bigger − big + small = larger`, `paris − france + italy = venice`).
    public static var statisticalSlips: [AnalogyBenchmarkEntry] {
        entries.filter { !$0.isExactMatch }
    }
}

// MARK: - 2. Exact Algebraic Analogy Solver in 𝕍 (1960s Formal Rigor)

public struct AlgebraicAnalogyResult: Sendable, Equatable {
    public let expression: String
    public let targetVector: EmojiVector
    public let resolvedBundle: FeatureBundle
    public let l2ErrorSquared: Double

    public var isExactZeroError: Bool {
        l2ErrorSquared <= 1e-24
    }
}

/// Solves vector analogies `v(A) - v(B) + v(C)` in our orthogonal feature embedding space `𝕍`.
/// Because `Role`, `Gender`, `SkinTone`, and `Profession` occupy mutually orthogonal subspaces,
/// parallelogram analogies hold with **exact zero L2 error** (`||v(A) - v(B) + v(C) - v(D)||² == 0`).
public struct AlgebraicAnalogySolver: Sendable {
    public let functor: EmbeddingFunctor
    public let vocabulary: [FeatureBundle]

    public init(functor: EmbeddingFunctor = EmbeddingFunctor()) {
        self.functor = functor
        var vocab: [FeatureBundle] = [
            .princess, .prince, .woman, .man, .person
        ]
        for tone in SkinTone.allCases {
            vocab.append(FeatureBundle.princess.composed(with: .tone(tone)))
            vocab.append(FeatureBundle.prince.composed(with: .tone(tone)))
            vocab.append(FeatureBundle.woman.composed(with: .tone(tone)))
            vocab.append(FeatureBundle.man.composed(with: .tone(tone)))
        }
        for prof in Profession.allCases {
            vocab.append(FeatureBundle.woman.zwjComposed(with: prof))
            vocab.append(FeatureBundle.man.zwjComposed(with: prof))
            vocab.append(FeatureBundle.woman.composed(with: .tone(.medium)).zwjComposed(with: prof))
            vocab.append(FeatureBundle.man.composed(with: .tone(.medium)).zwjComposed(with: prof))
        }
        self.vocabulary = vocab
    }

    /// Computes `target = v(a) - v(b) + v(c)` and finds the closest bundle `d` in `vocabulary`.
    public func solve(
        _ a: FeatureBundle,
        minus b: FeatureBundle,
        plus c: FeatureBundle
    ) -> AlgebraicAnalogyResult {
        let target = (functor.embed(a) - functor.embed(b)) + functor.embed(c)

        var bestBundle = a
        var bestError = Double.infinity

        for candidate in vocabulary {
            let err = (functor.embed(candidate) - target).normSquared
            if err < bestError {
                bestError = err
                bestBundle = candidate
            }
        }

        return AlgebraicAnalogyResult(
            expression: "\(a.emoji) − \(b.emoji) + \(c.emoji) = \(bestBundle.emoji)",
            targetVector: target,
            resolvedBundle: bestBundle,
            l2ErrorSquared: bestError
        )
    }
}
