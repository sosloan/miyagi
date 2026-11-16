//
//  AppleCombineFoundationPipeline.swift
//  MySLOANLibrary
//
//  Apple Foundation + Apple Combine Setup & Canonical Apple Emoji Verification
//  Integrates:
//  - Apple Foundation (UnicodeScalar properties, CFStringTransform("\\N{...}"), JSONEncoder/Decoder, NotificationCenter)
//  - Apple Combine (PassthroughSubject, CurrentValueSubject, AnyPublisher, @Published / ObservableObject)
//  - "Voices in Our Code" (🏈 🧮 💻 🎶 🧠 👑 🫧) & Rosetta Loop reactive world publisher
//

import Foundation
#if canImport(Combine)
import Combine
#endif

// MARK: - 1. Apple Emoji & Unicode Scalar Verifier (Apple Foundation + CoreFoundation)

public struct AppleEmojiRecord: Codable, Sendable, Equatable, Identifiable {
    public var id: String { emoji }
    public let emoji: String
    public let roleOrMeaning: String
    public let codepointsHex: [String]
    public let unicodeNames: [String]
    public let isAppleEmojiCompliant: Bool

    public init(emoji: String, roleOrMeaning: String) {
        self.emoji = emoji
        self.roleOrMeaning = roleOrMeaning

        let scalars = Array(emoji.unicodeScalars)
        self.codepointsHex = scalars.map {
            String(format: "U+%04X", $0.value)
        }
        self.unicodeNames = scalars.map { scalar in
            Self.unicodeName(for: scalar)
        }
        self.isAppleEmojiCompliant = Self.validateAppleEmoji(scalars: scalars)
    }

    /// Uses Apple Foundation's `CFStringTransform` (`Any-Name`) to inspect the official Unicode scalar name.
    public static func unicodeName(for scalar: UnicodeScalar) -> String {
        let mutable = NSMutableString(string: String(scalar))
        CFStringTransform(mutable, nil, "Any-Name" as CFString, false)
        let raw = mutable as String
        if raw.hasPrefix("\\N{") && raw.hasSuffix("}") {
            return String(raw.dropFirst(3).dropLast())
        }
        return raw
    }

    /// Verifies that an emoji sequence conforms to Apple Color Emoji / Unicode UTS #51 rules:
    /// - Single presentation emoji (`isEmojiPresentation` or `isEmoji` + `U+FE0F` VS16)
    /// - Emoji modifier sequence (`isEmojiModifierBase` + Fitzpatrick `U+1F3FB...U+1F3FF`)
    /// - Emoji ZWJ sequence joined by `U+200D` (`ZERO WIDTH JOINER`)
    public static func validateAppleEmoji(scalars: [UnicodeScalar]) -> Bool {
        guard !scalars.isEmpty else { return false }
        let hasPrimaryEmoji = scalars.contains {
            $0.properties.isEmoji && ($0.properties.isEmojiPresentation || scalars.contains(UnicodeScalar(0xFE0F)!) || $0.properties.isEmojiModifier)
        }
        let allValidComponents = scalars.allSatisfy { scalar in
            scalar.properties.isEmoji
                || scalar.properties.isEmojiModifier
                || scalar.properties.isVariationSelector
                || scalar.value == 0x200D // ZWJ
        }
        return hasPrimaryEmoji && allValidComponents
    }
}

/// Complete catalog of emojis used across Compositional Emoji Semantics, Timeless Identity, and Voices in Our Code.
public enum AppleEmojiCatalog {
    /// "XII. The Voices in Our Code" (`IX. In Functional Programming, We Don't ...`)
    public static let voicesInOurCode: [AppleEmojiRecord] = [
        AppleEmojiRecord(emoji: "🏈", roleOrMeaning: "UCLA Football (Scholar-Athlete Spirit: Glen, Brian, every teammate)"),
        AppleEmojiRecord(emoji: "🧮", roleOrMeaning: "DeepMind London (Research Heritage: Dennis, formal rigor)"),
        AppleEmojiRecord(emoji: "💻", roleOrMeaning: "Steve Jobs (Art & Technology Bridge: liberal arts + computing)"),
        AppleEmojiRecord(emoji: "🎶", roleOrMeaning: "PreSonus ATOM (Music as Mathematics: rhythm & structure)"),
        AppleEmojiRecord(emoji: "🧠", roleOrMeaning: "UCLA Brain Sport (Neuroscience meets Athletics)"),
        AppleEmojiRecord(emoji: "👑", roleOrMeaning: "Crown Operator (Meta-level Monarch reasoning)"),
        AppleEmojiRecord(emoji: "🫧", roleOrMeaning: "Bubbles (Liminal foam between raven and monarch)"),
        AppleEmojiRecord(emoji: "🦁", roleOrMeaning: "Lion Identity (prince_compose_male_idempotent: XX ∘ AKA = 🦁)")
    ]

    /// Base and composed emojis from Compositional Emoji Semantics (`Σ`).
    public static let compositionalSemantics: [AppleEmojiRecord] = [
        AppleEmojiRecord(emoji: "👸", roleOrMeaning: "Princess [+royalty, +female, +human]"),
        AppleEmojiRecord(emoji: "🤴", roleOrMeaning: "Prince [+royalty, +male, +human]"),
        AppleEmojiRecord(emoji: "👸🏽", roleOrMeaning: "Princess + Medium Skin Tone (👸 ∘ 🏽)"),
        AppleEmojiRecord(emoji: "🤴🏽", roleOrMeaning: "Prince + Medium Skin Tone (🤴 ∘ 🏽)"),
        AppleEmojiRecord(emoji: "👩‍🔬", roleOrMeaning: "Woman Scientist ZWJ Sequence (👩 ⊗ 🔬)"),
        AppleEmojiRecord(emoji: "👩🏽‍🔬", roleOrMeaning: "Woman Scientist + Medium Skin Tone (👩 ∘ 🏽 ⊗ 🔬)"),
        AppleEmojiRecord(emoji: "♀️", roleOrMeaning: "Female Sign with Emoji Presentation Selector (U+2640 U+FE0F)"),
        AppleEmojiRecord(emoji: "♂️", roleOrMeaning: "Male Sign with Emoji Presentation Selector (U+2642 U+FE0F)"),
        AppleEmojiRecord(emoji: "⚧️", roleOrMeaning: "Transgender Symbol with Emoji Presentation Selector (U+26A7 U+FE0F)")
    ]

    public static var allRecords: [AppleEmojiRecord] {
        compositionalSemantics + voicesInOurCode
    }

    public static var allAreValidAppleEmojis: Bool {
        allRecords.allSatisfy(\.isAppleEmojiCompliant)
    }

    /// Exports the verified emoji catalog as formatted JSON using Apple `Foundation.JSONEncoder`.
    public static func exportVerifiedCatalogJSON() throws -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        let data = try encoder.encode(allRecords)
        return String(decoding: data, as: UTF8.self)
    }
}

// MARK: - 2. Guiding Numbers & Voices in Our Code (Section XI & XII)

public enum GuidingNumbers {
    /// Golden Ratio `φ = (1 + √5) / 2 ≈ 1.618033988749895`
    public static let phi: Double = (1.0 + 5.0.squareRoot()) / 2.0
    public static let phiInverse: Double = phi - 1.0

    public static let edgeWeights: [Double] = [
        phiInverse,
        1.0,
        phi,
        phi * phi,
        phiInverse * phiInverse
    ]
}

// MARK: - 3. Apple Combine + Apple Foundation Reactive Pipeline

#if canImport(Combine)
/// Reactive Combine + Foundation coordinator that streams:
/// 1. `FeatureAction` reductions into `VerifiedEmojiState` via `CurrentValueSubject`
/// 2. `SmartReplyThreadContext` updates & long-form expansions via `PassthroughSubject`
/// 3. `NotificationCenter.Publisher` events bridged through Apple Foundation
public final class SLOANCombineCoordinator: ObservableObject {
    public static let stateDidChangeNotification = Notification.Name("MySLOANLibrary.VerifiedEmojiStateDidChange")

    /// Current verified emoji reducer state (`CurrentValueSubject` publisher).
    public let emojiStateSubject: CurrentValueSubject<VerifiedEmojiState, Never>

    /// Stream of `FeatureAction` events (`PassthroughSubject`).
    public let actionSubject = PassthroughSubject<FeatureAction, Never>()

    /// Stream of incoming `MailConversationEntry` events for Smart Reply.
    public let incomingMailSubject = PassthroughSubject<MailConversationEntry, Never>()

    /// Published log of verified state transitions & Smart Reply outputs.
    @Published public private(set) var transitionHistory: [VerifiedEmojiState] = []
    @Published public private(set) var latestSmartReply: String?

    private let functor: EmbeddingFunctor
    private let notificationCenter: NotificationCenter
    private var cancellables = Set<AnyCancellable>()

    public var statePublisher: AnyPublisher<VerifiedEmojiState, Never> {
        emojiStateSubject.eraseToAnyPublisher()
    }

    public var bowTieMetricsPublisher: AnyPublisher<BowTieMetrics, Never> {
        emojiStateSubject
            .map(\.metrics)
            .removeDuplicates()
            .eraseToAnyPublisher()
    }

    public init(
        initialBundle: FeatureBundle = .princess,
        functor: EmbeddingFunctor = EmbeddingFunctor(),
        notificationCenter: NotificationCenter = .default
    ) {
        self.functor = functor
        self.notificationCenter = notificationCenter
        let initialState = VerifiedEmojiState(bundle: initialBundle, functor: functor)
        self.emojiStateSubject = CurrentValueSubject(initialState)
        self.transitionHistory = [initialState]

        setupCombinePipelines()
    }

    private func setupCombinePipelines() {
        // 1. Functional world-building reducer pipeline:
        //    Describe the next world; only commit if compositional invariants hold.
        actionSubject
            .scan(emojiStateSubject.value) { [functor] currentState, action in
                var candidateWorld = currentState
                let invariantsHold = candidateWorld.reduce(action, functor: functor)
                return invariantsHold ? candidateWorld : currentState
            }
            .sink { [weak self] newState in
                guard let self else { return }
                self.emojiStateSubject.send(newState)
                self.transitionHistory.append(newState)
                self.notificationCenter.post(
                    name: Self.stateDidChangeNotification,
                    object: self,
                    userInfo: ["emoji": newState.bundle.emoji, "health": newState.metrics.structuralHealth]
                )
            }
            .store(in: &cancellables)

        // 2. Smart Reply reactive pipeline:
        //    Transforms incoming MailConversationEntry items into verified SmartReplyThreadContext & long-form reply.
        incomingMailSubject
            .map { entry in
                SmartReplyThreadContext.mailConversationContext(
                    threadIdentifier: "combine-thread-\(entry.id)",
                    entries: [entry],
                    senderIdentifier: entry.primaryRecipientIdentifiers.first ?? "sloan@sri.com",
                    senderGivenName: "Sloan",
                    recipientIdentifier: entry.senderIdentifier,
                    recipientGivenName: "Montague"
                )
            }
            .filter { $0.canGenerateMailSmartReply() }
            .map { context in
                DefaultSmartReplyExpander().response(
                    from: "We don't mutate broken worlds — we describe new worlds and verify their invariants.",
                    context: context
                )
            }
            .sink { [weak self] reply in
                self?.latestSmartReply = reply
            }
            .store(in: &cancellables)
    }

    /// Dispatches a `FeatureAction` through the Combine pipeline.
    public func send(_ action: FeatureAction) {
        actionSubject.send(action)
    }

    /// Dispatches an incoming `MailConversationEntry` through the Combine pipeline.
    public func receiveMail(_ entry: MailConversationEntry) {
        incomingMailSubject.send(entry)
    }

    /// Returns a Foundation `NotificationCenter.Publisher` for verified emoji state changes.
    public func notificationPublisher() -> NotificationCenter.Publisher {
        notificationCenter.publisher(for: Self.stateDidChangeNotification, object: self)
    }
}
#endif
