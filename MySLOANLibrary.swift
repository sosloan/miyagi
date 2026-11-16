// The Swift Programming Language
// https://docs.swift.org/swift-book

import Foundation

public func hello() {
    print("Hello, world!")
}

/// Runs a complete interactive demonstration of Compositional Emoji Semantics
/// (Feature Geometry, Functorial Vector Embeddings, ZWJ Tensor Composition, Bow-Tie Metrics)
/// and Smart Reply Conversation Context evaluation.
public func runSLOANDemo() -> String {
    let functor = EmbeddingFunctor()

    // 1. Compositional Grammar Rules
    let princess = FeatureBundle.princess
    let mediumTone = FeatureBundle.tone(.medium)
    let femaleMarker = FeatureBundle.genderMarker(.female)
    let prince = FeatureBundle.prince

    let princessMedium = princess.composed(with: mediumTone)
    let princessFemale = princess.composed(with: femaleMarker)
    let princeMale = prince.composed(with: FeatureBundle.genderMarker(.male))
    let princeMedium = prince.composed(with: mediumTone)
    let womanScientist = FeatureBundle.woman
        .composed(with: mediumTone)
        .zwjComposed(with: .scientist)

    // 2. Vector Space & Orthogonality Verification
    let vPrincess = functor.embed(princess)
    let vMedium = functor.embed(mediumTone)
    let innerProd = vPrincess.dot(vMedium)
    let objectiveLoss = functor.compositionLoss(princess, mediumTone)
    let disentanglement = functor.disentanglementInnerProduct(
        roleFemale: princess,
        roleMale: prince,
        toneA: .medium,
        toneB: .light
    )

    // 3. Verified Reducer & Bow-Tie Topology
    var state = VerifiedEmojiState(bundle: .woman, functor: functor)
    let step1OK = state.reduce(.unifyModifier(mediumTone), functor: functor)
    let step2OK = state.reduce(.applyZWJ(.scientist), functor: functor)

    // 4. Smart Reply Conversation Context
    let now = Date()
    let mailEntry = MailConversationEntry(
        id: "msg-001",
        text: "Want to formalize the category-theoretic version in Lean and test against embeddings?",
        senderIdentifier: "colleague@sri.com",
        primaryRecipientIdentifiers: ["sloan@sri.com"],
        sentDate: now
    )
    let mailContext = SmartReplyThreadContext.mailConversationContext(
        threadIdentifier: "thread-sri-1960",
        entries: [mailEntry],
        senderIdentifier: "sloan@sri.com",
        senderGivenName: "Sloan",
        recipientIdentifier: "colleague@sri.com",
        recipientGivenName: "Montague"
    )
    // 5. Load questions-phrases.txt & questions-words.txt if present in workspace
    let phrasesPath = "/Users/sloan/MySLOANLibrary/questions-phrases.txt"
    let wordsPath = "/Users/sloan/MySLOANLibrary/questions-words.txt"
    let phrasesSection: String
    if let phrasesCorpus = try? AnalogyCorpus.load(fromFileAtPath: phrasesPath) {
        let lines = phrasesCorpus.summaries.map { s in
            let report = phrasesCorpus.verifyAlgebraicFactorization(forCategory: s.category)
            let oneToManyInfo = report.oneToManyMultiAffiliations > 0
                ? " | 1-to-Many (Person→Companies): \(report.multiCompanyExamples.joined(separator: "; "))"
                : ""
            let manyToOneInfo = report.manyToOneCollisions > 0
                ? " | Many-to-1 (Company←People): \(report.collisionExamples.joined(separator: "; "))"
                : ""
            return "     • [\(s.category)] \(s.questionCount) analogies (\(s.uniquePairsCount) pairs) | Algebraic Accuracy: \(String(format: "%.1f%%", report.accuracy * 100.0))\(oneToManyInfo)\(manyToOneInfo) | e.g. \(s.sampleEquation)"
        }.joined(separator: "\n")
        phrasesSection = """
           • Loaded `questions-phrases.txt`: \(phrasesCorpus.totalQuestions) phrase analogies across \(phrasesCorpus.categories.count) categories:
        \(lines)
        """
    } else {
        phrasesSection = "   • `questions-phrases.txt` not found at default path."
    }

    let wordsSection: String
    if let wordsCorpus = try? AnalogyCorpus.load(fromFileAtPath: wordsPath) {
        wordsSection = "   • Loaded `questions-words.txt`: \(wordsCorpus.totalQuestions) word analogies across \(wordsCorpus.categories.count) categories (\(wordsCorpus.categories.joined(separator: ", ")))"
    } else {
        wordsSection = "   • `questions-words.txt` not found at default path."
    }
    let expander = DefaultSmartReplyExpander()
    let expandedReply = expander.response(
        from: "SRI style. Formal verification with engineering discipline. Let's build it properly.",
        context: mailContext
    )

    return """
    ====================================================================
      COMPOSITIONAL EMOJI SEMANTICS & SMART REPLY VERIFICATION SUITE
      In the tradition of SRI International (Menlo Park, California)
    ====================================================================

    1. COMPOSITIONAL GRAMMAR (Chomsky–Halle Feature Geometry)
       • 👸 ∘ 🏽 → \(princessMedium.emoji)   \(princessMedium)
       • 👸 ∘ ♀️ → \(princessFemale.emoji)    (idempotent: \(princessFemale == princess))
       • 🤴 ∘ ♂️ → \(princeMale.emoji)    (prince_compose_male_idempotent: XX ∘ AKA = 🦁 -> \(princeMale == prince))
       • 🤴 ∘ 🏽 → \(princeMedium.emoji)   \(princeMedium)
       • 👩 ∘ 🏽 ⊗ 🔬 → \(womanScientist.emoji)  \(womanScientist)

    2. FUNCTORIAL EMBEDDING E: 𝔽 → 𝕍 & ORTHOGONALITY
       • v(👸)             = \(vPrincess)
       • v(🏽)             = \(vMedium)
       • v(👸🏽)            = \(functor.embed(princessMedium))
       • ⟨v(👸), v(🏽)⟩     = \(innerProd)  (Orthogonal: \(vPrincess.isOrthogonal(to: vMedium)))
       • ||v(👸∘🏽) - (v(👸)+v(🏽))||² = \(objectiveLoss)
       • ⟨v(👸🏽)-v(👸🏻), v(👸)-v(🤴)⟩ = \(disentanglement) (Disentangled!)

    3. VERIFIED REDUCER & BOW-TIE TOPOLOGY
       • State: \(state.bundle.emoji) | Commutes: \(step1OK && step2OK) | \(state.metrics)

    4. SMART REPLY CONVERSATION CONTEXT
       • Thread ID: \(mailContext.threadIdentifier)
       • Mail Smart Reply Eligible: \(mailContext.canGenerateMailSmartReply())
       • Expanded Long-Form Reply:
    \(expandedReply.split(separator: "\n", omittingEmptySubsequences: false).map { "     > " + $0 }.joined(separator: "\n"))

    5. SCHAEFFER'S CO-OPERATIVE THOUGHT & TIMELESS IDENTITY (PARIS / DIAMOND / GLEN)
       • \(SchaefferThinkingCorrelation.epigraph)
       • Co-operative Brain–Vocal Correlation: \(String(format: "%.4f", SchaefferThinkingCorrelation().cooperativeCorrelation))
       • prince_compose_male_idempotent (XX ∘ AKA = 🦁): \(SchaefferThinkingCorrelation.verifyPrinceMaleIdempotence().isIdempotent)
       • Paris Timeless Identity (11 epochs, 2275 yrs): \(Paris().verifyTimelessIdentity().allEpochsPreserved ? "✅ PRESERVED" : "❌")
       • Diamond Isospectral Identity (725,000 psi, 1B yrs): \(DiamondFormation(initialCarbon: .init(atoms: 1_000_000_000, structure: .graphite)).crystallize().verifyIdentity() ? "✅ PRESERVED" : "❌")

    6. APPLE FOUNDATION EMOJI VERIFICATION & APPLE COMBINE PIPELINE
       • All \(AppleEmojiCatalog.allRecords.count) Emojis Verified (Apple Color Emoji / UTS #51): \(AppleEmojiCatalog.allAreValidAppleEmojis ? "✅ YES" : "❌ NO")
    \(AppleEmojiCatalog.allRecords.map { "   • \($0.emoji)  [\($0.codepointsHex.joined(separator: " "))] -> \($0.unicodeNames.joined(separator: " + "))" }.joined(separator: "\n"))

    7. VECTOR ANALOGIES: STATISTICAL SKIP-GRAM (TABLE 8) vs. 1960s ALGEBRAIC FUNCTOR
       • Exact Algebraic Analogies in 𝕍 (Zero L2 Error):
         - \(AlgebraicAnalogySolver(functor: functor).solve(.prince, minus: .man, plus: .woman).expression)  (L2² = \(AlgebraicAnalogySolver(functor: functor).solve(.prince, minus: .man, plus: .woman).l2ErrorSquared))
         - \(AlgebraicAnalogySolver(functor: functor).solve(FeatureBundle.prince.composed(with: mediumTone), minus: .man, plus: .woman).expression)  (L2² = \(AlgebraicAnalogySolver(functor: functor).solve(FeatureBundle.prince.composed(with: mediumTone), minus: .man, plus: .woman).l2ErrorSquared))
         - \(AlgebraicAnalogySolver(functor: functor).solve(womanScientist, minus: .woman, plus: .man).expression)  (L2² = \(AlgebraicAnalogySolver(functor: functor).solve(womanScientist, minus: .woman, plus: .man).l2ErrorSquared))
       • Word2Vec Table 8 Benchmark (8 Queries, \(Word2VecTable8Benchmark.statisticalSlips.count) Statistical Slips Identified):
    \(Word2VecTable8Benchmark.entries.map { "     - \($0.question) → \($0.skipGramTopAnswer) [\($0.isExactMatch ? "✅ exact" : "⚠️ slip (expected \($0.expectedCanonicalAnswer))")] (\($0.notes))" }.joined(separator: "\n"))

    8. PHRASE & WORD ANALOGY CORPORA (`questions-phrases.txt` & `questions-words.txt`)
    \(phrasesSection)
    \(wordsSection)
    ====================================================================
    """
}
