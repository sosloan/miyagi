//
//  SmartReplyContext.swift
//  MySLOANLibrary
//
//  Adopting Smart Reply in your messaging or email app
//  Cross-platform model + eligibility verifier + UIKit conversation context builders.
//

import Foundation

// MARK: - 1. Domain Models for Mail & Messaging Conversation Contexts

public enum ConversationEntryKind: String, Sendable, Equatable {
    case personal
    case automated
    case notification
}

public struct MailConversationEntry: Sendable, Equatable, Identifiable {
    public var id: String
    public var text: String
    public var senderIdentifier: String
    public var primaryRecipientIdentifiers: Set<String>
    public var ccRecipientIdentifiers: Set<String>
    public var bccRecipientIdentifiers: Set<String>
    public var sentDate: Date
    public var kind: ConversationEntryKind

    public init(
        id: String,
        text: String,
        senderIdentifier: String,
        primaryRecipientIdentifiers: Set<String>,
        ccRecipientIdentifiers: Set<String> = [],
        bccRecipientIdentifiers: Set<String> = [],
        sentDate: Date = Date(),
        kind: ConversationEntryKind = .personal
    ) {
        self.id = id
        self.text = text
        self.senderIdentifier = senderIdentifier
        self.primaryRecipientIdentifiers = primaryRecipientIdentifiers
        self.ccRecipientIdentifiers = ccRecipientIdentifiers
        self.bccRecipientIdentifiers = bccRecipientIdentifiers
        self.sentDate = sentDate
        self.kind = kind
    }
}

public struct MessageConversationEntry: Sendable, Equatable, Identifiable {
    public var id: String
    public var text: String
    public var senderIdentifier: String
    public var primaryRecipientIdentifiers: Set<String>
    public var sentDate: Date
    public var isTextOnly: Bool

    public init(
        id: String,
        text: String,
        senderIdentifier: String,
        primaryRecipientIdentifiers: Set<String>,
        sentDate: Date = Date(),
        isTextOnly: Bool = true
    ) {
        self.id = id
        self.text = text
        self.senderIdentifier = senderIdentifier
        self.primaryRecipientIdentifiers = primaryRecipientIdentifiers
        self.sentDate = sentDate
        self.isTextOnly = isTextOnly
    }
}

public struct SmartReplyThreadContext: Sendable, Equatable {
    public var threadIdentifier: String
    public var participantNameByIdentifier: [String: PersonNameComponents]
    public var selfIdentifiers: Set<String>
    public var responsePrimaryRecipientIdentifiers: Set<String>
    public var mailEntries: [MailConversationEntry]
    public var messageEntries: [MessageConversationEntry]

    public init(
        threadIdentifier: String,
        participantNameByIdentifier: [String: PersonNameComponents],
        selfIdentifiers: Set<String>,
        responsePrimaryRecipientIdentifiers: Set<String>,
        mailEntries: [MailConversationEntry] = [],
        messageEntries: [MessageConversationEntry] = []
    ) {
        self.threadIdentifier = threadIdentifier
        self.participantNameByIdentifier = participantNameByIdentifier
        self.selfIdentifiers = selfIdentifiers
        self.responsePrimaryRecipientIdentifiers = responsePrimaryRecipientIdentifiers
        self.mailEntries = mailEntries
        self.messageEntries = messageEntries
    }

    /// Builds a mail conversation context from thread entries following Apple's Smart Reply specification.
    public static func mailConversationContext(
        threadIdentifier: String,
        entries: [MailConversationEntry],
        senderIdentifier: String,
        senderGivenName: String,
        recipientIdentifier: String,
        recipientGivenName: String
    ) -> SmartReplyThreadContext {
        var senderName = PersonNameComponents()
        senderName.givenName = senderGivenName

        var recipientName = PersonNameComponents()
        recipientName.givenName = recipientGivenName

        return SmartReplyThreadContext(
            threadIdentifier: threadIdentifier,
            participantNameByIdentifier: [
                senderIdentifier: senderName,
                recipientIdentifier: recipientName
            ],
            selfIdentifiers: [senderIdentifier],
            responsePrimaryRecipientIdentifiers: [recipientIdentifier],
            mailEntries: entries
        )
    }

    /// Evaluates whether a messaging conversation satisfies the system's Smart Reply generation conditions:
    /// - The input field is empty.
    /// - The last message in the conversation is from the recipient, not the person sending messages.
    /// - The preceding messages in the conversation are text (not images or emojis-only).
    /// - The preceding messages are recent.
    public func canGenerateMessagingSmartReply(
        currentInputText: String,
        referenceDate: Date = Date(),
        recencyWindow: TimeInterval = 3600
    ) -> Bool {
        guard currentInputText.isEmpty,
              let lastMessage = messageEntries.last else {
            return false
        }
        let lastFromOtherParticipant = !selfIdentifiers.contains(lastMessage.senderIdentifier)
        let allText = messageEntries.allSatisfy { $0.isTextOnly && !$0.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        let isRecent = abs(referenceDate.timeIntervalSince(lastMessage.sentDate)) <= recencyWindow
        return lastFromOtherParticipant && allText && isRecent
    }

    /// Evaluates whether a mail conversation satisfies the system's Smart Reply generation conditions:
    /// - The person is the direct recipient of the email, and is not in the CC or BCC list.
    /// - The person has not already replied to the email.
    /// - The sender and recipient of the email have different email addresses.
    public func canGenerateMailSmartReply() -> Bool {
        guard let latestEmail = mailEntries.last else {
            return false
        }
        let isDirectRecipient = !selfIdentifiers.isDisjoint(with: latestEmail.primaryRecipientIdentifiers)
        let isInCCOrBCC = !selfIdentifiers.isDisjoint(with: latestEmail.ccRecipientIdentifiers)
            || !selfIdentifiers.isDisjoint(with: latestEmail.bccRecipientIdentifiers)
        let hasAlreadyReplied = mailEntries.dropLast().contains { entry in
            selfIdentifiers.contains(entry.senderIdentifier) && entry.sentDate >= latestEmail.sentDate
        } || selfIdentifiers.contains(latestEmail.senderIdentifier)
        let distinctAddresses = !selfIdentifiers.contains(latestEmail.senderIdentifier)

        return isDirectRecipient && !isInCCOrBCC && !hasAlreadyReplied && distinctAddresses
    }
}

// MARK: - 2. Long-Form Smart Reply Expander

public protocol SmartReplyLongFormModel: Sendable {
    func response(from smartReply: String, context: SmartReplyThreadContext) -> String
}

public struct DefaultSmartReplyExpander: SmartReplyLongFormModel {
    public init() {}

    public func response(from smartReply: String, context: SmartReplyThreadContext) -> String {
        let recipientID = context.responsePrimaryRecipientIdentifiers.first ?? ""
        let recipientName = context.participantNameByIdentifier[recipientID]?.givenName ?? "there"
        let senderID = context.selfIdentifiers.first ?? ""
        let senderName = context.participantNameByIdentifier[senderID]?.givenName ?? "Best"

        return """
        Hi \(recipientName),

        \(smartReply)

        Best regards,
        \(senderName)
        """
    }
}
