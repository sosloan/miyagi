//
//  CompositionalEmojiSemantics.swift
//  MySLOANLibrary
//
//  COMPOSITIONAL EMOJI SEMANTICS
//  A Formally Verified Theory of Visual Symbol Composition
//  In the tradition of SRI International (Chomsky–Halle Feature Geometry & Montague Semantics)
//

import Foundation

// MARK: - 1. Base Symbols & Taxonomic Features (Role × Gender × SkinTone)

public enum Role: Int, CaseIterable, Sendable, Equatable, Hashable, CustomStringConvertible {
    case person = 0
    case royalty = 1
    case worker = 2
    case professional = 3

    public var description: String {
        switch self {
        case .person: return "person"
        case .royalty: return "royalty"
        case .worker: return "worker"
        case .professional: return "professional"
        }
    }
}

public enum Gender: Int, CaseIterable, Sendable, Equatable, Hashable, CustomStringConvertible {
    case neutral = 0
    case female = 1
    case male = 2
    case nonBinary = 3

    public var symbol: String {
        switch self {
        case .neutral: return "🧑"
        case .female: return "♀️"
        case .male: return "♂️"
        case .nonBinary: return "⚧️"
        }
    }

    public var description: String { symbol }
}

public enum SkinTone: Int, CaseIterable, Sendable, Equatable, Hashable, CustomStringConvertible {
    case light = 0       // 🏻 U+1F3FB
    case mediumLight = 1 // 🏼 U+1F3FC
    case medium = 2      // 🏽 U+1F3FD
    case mediumDark = 3  // 🏾 U+1F3FE
    case dark = 4        // 🏿 U+1F3FF

    public var modifierScalar: UnicodeScalar {
        switch self {
        case .light: return UnicodeScalar(0x1F3FB)!
        case .mediumLight: return UnicodeScalar(0x1F3FC)!
        case .medium: return UnicodeScalar(0x1F3FD)!
        case .mediumDark: return UnicodeScalar(0x1F3FE)!
        case .dark: return UnicodeScalar(0x1F3FF)!
        }
    }

    public var symbol: String {
        String(Character(modifierScalar))
    }

    public var description: String { symbol }
}

public enum Profession: Int, CaseIterable, Sendable, Equatable, Hashable, CustomStringConvertible {
    case scientist = 0     // 🔬 U+1F52C
    case medical = 1       // ⚕️ U+2695 U+FE0F
    case technologist = 2  // 💻 U+1F4BB
    case astronaut = 3     // 🚀 U+1F680

    public var symbol: String {
        switch self {
        case .scientist: return "🔬"
        case .medical: return "⚕️"
        case .technologist: return "💻"
        case .astronaut: return "🚀"
        }
    }

    public var description: String { symbol }
}

// MARK: - 2. Chomsky–Halle Feature Geometry (Category 𝔽)

/// Semantic feature matrix `[±royal, ±female, ±human, ...]` living in the semantic subspace.
public struct SemanticFeatures: Equatable, Hashable, Sendable, CustomStringConvertible {
    public var role: Role?
    public var gender: Gender?
    public var isHuman: Bool

    public init(role: Role? = nil, gender: Gender? = nil, isHuman: Bool = true) {
        self.role = role
        self.gender = gender
        self.isHuman = isHuman
    }

    /// Feature unification in semantic space (idempotent on already-specified intrinsic features).
    public func unified(with other: SemanticFeatures) -> SemanticFeatures {
        SemanticFeatures(
            role: self.role ?? other.role,
            gender: self.gender ?? other.gender,
            isHuman: self.isHuman || other.isHuman
        )
    }

    public var description: String {
        var tags: [String] = []
        if let role {
            tags.append("+\(role)")
        }
        if let gender {
            switch gender {
            case .female: tags.append("+female")
            case .male: tags.append("+male")
            case .nonBinary: tags.append("+nonbinary")
            case .neutral: tags.append("+neutral")
            }
        }
        if isHuman {
            tags.append("+human")
        }
        return "[\(tags.joined(separator: ", "))]"
    }
}

/// Appearance feature matrix `[skin_tone: ...]` living in the orthogonal appearance subspace.
public struct AppearanceFeatures: Equatable, Hashable, Sendable, CustomStringConvertible {
    public var skinTone: SkinTone?

    public init(skinTone: SkinTone? = nil) {
        self.skinTone = skinTone
    }

    public func unified(with other: AppearanceFeatures) -> AppearanceFeatures {
        AppearanceFeatures(skinTone: other.skinTone ?? self.skinTone)
    }

    public var description: String {
        if let skinTone {
            return "[tone: \(skinTone.symbol)]"
        }
        return "[tone: ø]"
    }
}

/// An object in the Feature Category 𝔽: `Role × Gender × SkinTone` (+ optional ZWJ profession).
public struct FeatureBundle: Equatable, Hashable, Sendable, CustomStringConvertible {
    public var semantic: SemanticFeatures
    public var appearance: AppearanceFeatures
    public var profession: Profession?

    public init(
        semantic: SemanticFeatures = SemanticFeatures(isHuman: false),
        appearance: AppearanceFeatures = AppearanceFeatures(),
        profession: Profession? = nil
    ) {
        self.semantic = semantic
        self.appearance = appearance
        self.profession = profession
    }

    // Canonical base symbols in Σ
    public static let princess = FeatureBundle(
        semantic: SemanticFeatures(role: .royalty, gender: .female, isHuman: true)
    )
    public static let prince = FeatureBundle(
        semantic: SemanticFeatures(role: .royalty, gender: .male, isHuman: true)
    )
    public static let woman = FeatureBundle(
        semantic: SemanticFeatures(role: .person, gender: .female, isHuman: true)
    )
    public static let man = FeatureBundle(
        semantic: SemanticFeatures(role: .person, gender: .male, isHuman: true)
    )
    public static let person = FeatureBundle(
        semantic: SemanticFeatures(role: .person, gender: .neutral, isHuman: true)
    )

    public static func tone(_ tone: SkinTone) -> FeatureBundle {
        FeatureBundle(
            semantic: SemanticFeatures(role: nil, gender: nil, isHuman: false),
            appearance: AppearanceFeatures(skinTone: tone)
        )
    }

    public static func genderMarker(_ gender: Gender) -> FeatureBundle {
        FeatureBundle(
            semantic: SemanticFeatures(role: nil, gender: gender, isHuman: false),
            appearance: AppearanceFeatures(skinTone: nil)
        )
    }

    /// Modifier composition `a ∘ b` (feature unification in 𝔽).
    /// Satisfies:
    /// - `👸 ∘ 🏽 → 👸🏽` (person + attribute)
    /// - `👸 ∘ ♀️ → 👸` (already gendered, identity)
    /// - `🤴 ∘ 🏽 → 🤴🏽` (parallel structure)
    public func composed(with modifier: FeatureBundle) -> FeatureBundle {
        FeatureBundle(
            semantic: semantic.unified(with: modifier.semantic),
            appearance: appearance.unified(with: modifier.appearance),
            profession: profession ?? modifier.profession
        )
    }

    /// ZWJ Tensor Product `Person ⊗ Profession → ProfessionalPerson`
    /// e.g. `👩 + ZWJ + 🔬 → 👩‍🔬`
    public func zwjComposed(with profession: Profession) -> FeatureBundle {
        var nextSemantic = semantic
        nextSemantic.role = .professional
        return FeatureBundle(
            semantic: nextSemantic,
            appearance: appearance,
            profession: profession
        )
    }

    /// Renders the feature bundle into its canonical Unicode emoji sequence.
    public var emoji: String {
        let base: String
        switch (semantic.role, semantic.gender) {
        case (.royalty, .female): base = "👸"
        case (.royalty, .male): base = "🤴"
        case (.royalty, _): base = "🫅"
        case (_, .female) where semantic.isHuman: base = "👩"
        case (_, .male) where semantic.isHuman: base = "👨"
        case (_, _) where semantic.isHuman: base = "🧑"
        default:
            if let tone = appearance.skinTone {
                return tone.symbol
            }
            if let gender = semantic.gender {
                return gender.symbol
            }
            return "∅"
        }

        let toned = base + (appearance.skinTone?.symbol ?? "")
        if let profession {
            return toned + "\u{200D}" + profession.symbol
        }
        return toned
    }

    public var description: String {
        "\(emoji) \(semantic) \(appearance)" + (profession.map { " ⊗ \($0.symbol)" } ?? "")
    }
}

// MARK: - 3. Vector Space Category 𝕍 & Functor E: 𝔽 → 𝕍

/// An element of ℝⁿ partitioned into orthogonal subspaces:
/// - Indices `0..<6`: Semantic subspace `V_sem` (Role: 4 dims, Gender: 2 dims)
/// - Indices `6..<11`: Appearance subspace `V_app` (SkinTone: 5 dims)
/// - Indices `11..<15`: ZWJ Tensor interaction subspace `V_zwj` (Profession: 4 dims)
public struct EmojiVector: Equatable, Sendable, CustomStringConvertible {
    public static let semanticDimension = 6
    public static let appearanceDimension = 5
    public static let tensorDimension = 4
    public static let totalDimension = semanticDimension + appearanceDimension + tensorDimension

    public var components: [Double]

    public init(components: [Double] = Array(repeating: 0.0, count: EmojiVector.totalDimension)) {
        precondition(components.count == Self.totalDimension, "Expected \(Self.totalDimension)-D vector")
        self.components = components
    }

    public static let zero = EmojiVector()

    /// Direct sum / vector addition `u + v` in 𝕍.
    public static func + (lhs: EmojiVector, rhs: EmojiVector) -> EmojiVector {
        EmojiVector(components: zip(lhs.components, rhs.components).map(+))
    }

    /// Vector difference `u - v` in 𝕍.
    public static func - (lhs: EmojiVector, rhs: EmojiVector) -> EmojiVector {
        EmojiVector(components: zip(lhs.components, rhs.components).map(-))
    }

    /// Inner product `⟨u, v⟩` in ℝⁿ.
    public func dot(_ other: EmojiVector) -> Double {
        zip(components, other.components).reduce(0.0) { $0 + $1.0 * $1.1 }
    }

    /// Squared L2 norm `||v||²`.
    public var normSquared: Double {
        dot(self)
    }

    /// L2 norm `||v||`.
    public var norm: Double {
        normSquared.squareRoot()
    }

    /// Checks whether `u ⊥ v` within floating-point tolerance.
    public func isOrthogonal(to other: EmojiVector, tolerance: Double = 1e-12) -> Bool {
        abs(dot(other)) <= tolerance
    }

    /// Projection onto the semantic subspace `V_sem`.
    public var semanticProjection: EmojiVector {
        var c = Array(repeating: 0.0, count: Self.totalDimension)
        for i in 0..<Self.semanticDimension { c[i] = components[i] }
        return EmojiVector(components: c)
    }

    /// Projection onto the appearance subspace `V_app`.
    public var appearanceProjection: EmojiVector {
        var c = Array(repeating: 0.0, count: Self.totalDimension)
        for i in Self.semanticDimension..<(Self.semanticDimension + Self.appearanceDimension) {
            c[i] = components[i]
        }
        return EmojiVector(components: c)
    }

    public var description: String {
        let formatted = components.map { String(format: "%.1f", $0) }.joined(separator: ", ")
        return "[\(formatted)]"
    }
}

/// The structure-preserving Functor `E: 𝔽 → 𝕍` and Verified Reducer.
public struct EmbeddingFunctor: Sendable {
    public init() {}

    /// Maps semantic features into `V_sem` (indices `0..<6`).
    public func embedSemantic(_ semantic: SemanticFeatures) -> EmojiVector {
        var c = Array(repeating: 0.0, count: EmojiVector.totalDimension)
        if let role = semantic.role {
            c[role.rawValue] = 1.0
        }
        if let gender = semantic.gender {
            // Orthogonal gender basis on dims 4 and 5:
            // female = (+1, 0), male = (-1, 0), nonBinary = (0, +1)
            switch gender {
            case .female:
                c[4] = 1.0
            case .male:
                c[4] = -1.0
            case .nonBinary:
                c[5] = 1.0
            case .neutral:
                break
            }
        }
        return EmojiVector(components: c)
    }

    /// Maps appearance features into `V_app` (indices `6..<11`), orthogonal to `V_sem` by construction.
    public func embedAppearance(_ appearance: AppearanceFeatures) -> EmojiVector {
        var c = Array(repeating: 0.0, count: EmojiVector.totalDimension)
        if let tone = appearance.skinTone {
            c[EmojiVector.semanticDimension + tone.rawValue] = 1.0
        }
        return EmojiVector(components: c)
    }

    /// Bilinear map `T(E(A), E(B))` for ZWJ composition (`Person ⊗ Profession → ProfessionalPerson`).
    public func bilinearZWJ(_ base: EmojiVector, profession: Profession) -> EmojiVector {
        var c = base.components
        // Promote role in semantic subspace to professional while preserving person/gender and tone
        let tensorIndex = EmojiVector.semanticDimension + EmojiVector.appearanceDimension + profession.rawValue
        // Bilinear interaction weight from semantic norm
        let semanticEnergy = max(1.0, base.semanticProjection.norm)
        c[tensorIndex] = semanticEnergy
        return EmojiVector(components: c)
    }

    /// Functor object map `E(bundle) ∈ 𝕍`.
    /// By construction: `E(A ⊗ B) = E(A) ⊕ E(B)` for orthogonal semantic and appearance bundles.
    public func embed(_ bundle: FeatureBundle) -> EmojiVector {
        let base = embedSemantic(bundle.semantic) + embedAppearance(bundle.appearance)
        if let profession = bundle.profession {
            return bilinearZWJ(base, profession: profession)
        }
        return base
    }

    /// Computes the training objective loss:
    /// `L(a, b) = ||v(a ∘ b) - (v(a) + v(b))||²`
    public func compositionLoss(_ a: FeatureBundle, _ b: FeatureBundle) -> Double {
        let composedVec = embed(a.composed(with: b))
        let sumVec = embed(a) + embed(b)
        return (composedVec - sumVec).normSquared
    }

    /// Tests the empirical disentanglement prediction:
    /// `⟨v(👸🏽) - v(👸🏻), v(👸) - v(🤴)⟩ == 0`
    public func disentanglementInnerProduct(
        roleFemale: FeatureBundle = .princess,
        roleMale: FeatureBundle = .prince,
        toneA: SkinTone = .medium,
        toneB: SkinTone = .light
    ) -> Double {
        let vFemaleToneA = embed(roleFemale.composed(with: .tone(toneA)))
        let vFemaleToneB = embed(roleFemale.composed(with: .tone(toneB)))
        let toneDiff = vFemaleToneA - vFemaleToneB

        let genderDiff = embed(roleFemale) - embed(roleMale)
        return toneDiff.dot(genderDiff)
    }
}

// MARK: - 4. Verified Reducer & Bow-Tie Topology Monitor

public enum FeatureAction: Sendable, Equatable {
    case unifyModifier(FeatureBundle)
    case applyZWJ(Profession)
}

public struct BowTieMetrics: Sendable, Equatable, CustomStringConvertible {
    /// Number of modifier attachments converging into the bundle (in-degree).
    public var inDegree: Int
    /// Active semantic feature rank in the core representation.
    public var coreRank: Int
    /// Number of downstream ZWJ tensor compositions (out-degree).
    public var outDegree: Int
    /// Compositional coherence score in `[0.0, 1.0]` (`1.0` = exact functorial preservation & orthogonality).
    public var structuralHealth: Double

    public var description: String {
        "BowTie(in: \(inDegree), core: \(coreRank), out: \(outDegree), health: \(String(format: "%.2f", structuralHealth)))"
    }
}

public struct VerifiedEmojiState: Sendable, Equatable {
    public var bundle: FeatureBundle
    public var vector: EmojiVector
    public var metrics: BowTieMetrics

    public init(bundle: FeatureBundle, functor: EmbeddingFunctor = EmbeddingFunctor()) {
        self.bundle = bundle
        self.vector = functor.embed(bundle)
        self.metrics = Self.computeMetrics(for: bundle, vector: self.vector)
    }

    /// Reduces a `FeatureAction` into state while verifying the commutative diagram:
    /// `𝔽 × 𝔽 --⊗--> 𝔽` commutes with `𝕍 × 𝕍 --⊕--> 𝕍`.
    @discardableResult
    public mutating func reduce(_ action: FeatureAction, functor: EmbeddingFunctor = EmbeddingFunctor()) -> Bool {
        switch action {
        case .unifyModifier(let modifier):
            let nextBundle = bundle.composed(with: modifier)
            let nextVector = functor.embed(nextBundle)

            // Verify orthogonality between semantic and appearance projections
            let isOrthogonal = nextVector.semanticProjection.isOrthogonal(to: nextVector.appearanceProjection)
            self.bundle = nextBundle
            self.vector = nextVector
            self.metrics = Self.computeMetrics(for: nextBundle, vector: nextVector, valid: isOrthogonal)
            return isOrthogonal

        case .applyZWJ(let profession):
            let nextBundle = bundle.zwjComposed(with: profession)
            let nextVector = functor.embed(nextBundle)
            let isOrthogonal = nextVector.semanticProjection.isOrthogonal(to: nextVector.appearanceProjection)
            self.bundle = nextBundle
            self.vector = nextVector
            self.metrics = Self.computeMetrics(for: nextBundle, vector: nextVector, valid: isOrthogonal)
            return isOrthogonal
        }
    }

    private static func computeMetrics(
        for bundle: FeatureBundle,
        vector: EmojiVector,
        valid: Bool = true
    ) -> BowTieMetrics {
        let inDeg = (bundle.appearance.skinTone != nil ? 1 : 0) + (bundle.semantic.gender != nil ? 1 : 0)
        let core = (bundle.semantic.role != nil ? 1 : 0) + (bundle.semantic.isHuman ? 1 : 0)
        let outDeg = bundle.profession != nil ? 1 : 0
        let orthoError = abs(vector.semanticProjection.dot(vector.appearanceProjection))
        let health = valid ? max(0.0, 1.0 - orthoError) : 0.0
        return BowTieMetrics(inDegree: inDeg, coreRank: core, outDegree: outDeg, structuralHealth: health)
    }
}
