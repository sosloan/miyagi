//
//  FoodTruckMissionFactory.swift
//  MySLOANLibrary
//
//  Configurable Food Truck Mission Factory:
//  - Generic `MissionFactory` protocol (`Input`, `Output`)
//  - Discriminated `MissionKind` (`.standardActivity`, `.foodTruckService`)
//  - Food-truck service metadata (truckName, serviceName, day, serviceWindow, location, expectedCovers, permitStatus, powerSource)
//  - Automatic generation of operational summary, risk level, `go` / `watch` status,
//    reduced-menu & relocation fallback plan, regulatory & logistics research guidance,
//    six-item readiness checklist, and mission snapshot facts.
//

import Foundation

// MARK: - 1. Generic MissionFactory Abstraction

public protocol MissionFactory<Input, Output>: Sendable {
    associatedtype Input: Sendable
    associatedtype Output: Sendable

    func createMission(from input: Input) -> Output
}

// MARK: - 2. Domain Model & Discriminated Mission Types

public enum PermitStatus: String, Codable, CaseIterable, Sendable, Equatable, Hashable {
    case approved
    case pending
    case required
}

public enum PowerSource: String, Codable, CaseIterable, Sendable, Equatable, Hashable {
    case shorePower = "shore_power"
    case generator = "generator"
    case batteryInverter = "battery_inverter"

    public var displayName: String {
        switch self {
        case .shorePower: return "Shore power"
        case .generator: return "Generator"
        case .batteryInverter: return "Battery inverter"
        }
    }
}

public enum MissionRiskLevel: String, Codable, CaseIterable, Sendable, Equatable, Hashable {
    case low
    case medium
    case high
}

public enum MissionOperationalStatus: String, Codable, CaseIterable, Sendable, Equatable, Hashable {
    case go
    case watch
}

public enum ReadinessCategory: String, Codable, CaseIterable, Sendable, Equatable, Hashable {
    case permits = "Permits"
    case commissaryPreparation = "Commissary preparation"
    case inventory = "Inventory"
    case power = "Power"
    case posAndConnectivity = "POS and connectivity"
    case sanitationAndWaste = "Sanitation and waste"
}

public struct ReadinessChecklistItem: Codable, Sendable, Equatable, Hashable, Identifiable {
    public var id: ReadinessCategory { category }
    public let category: ReadinessCategory
    public let detail: String
    public var isReady: Bool

    public init(category: ReadinessCategory, detail: String, isReady: Bool) {
        self.category = category
        self.detail = detail
        self.isReady = isReady
    }
}

public struct StandardActivityMetadata: Codable, Sendable, Equatable, Hashable {
    public let title: String
    public let day: String
    public let window: String
    public let location: String
    public let notes: String

    public init(title: String, day: String, window: String, location: String, notes: String = "") {
        self.title = title
        self.day = day
        self.window = window
        self.location = location
        self.notes = notes
    }
}

public struct FoodTruckServiceMetadata: Codable, Sendable, Equatable, Hashable {
    public let truckName: String
    public let serviceName: String
    public let day: String
    public let serviceWindow: String
    public let location: String
    public let expectedCovers: Int
    public let permitStatus: PermitStatus
    public let powerSource: PowerSource

    public init(
        truckName: String,
        serviceName: String,
        day: String,
        serviceWindow: String,
        location: String,
        expectedCovers: Int,
        permitStatus: PermitStatus,
        powerSource: PowerSource
    ) {
        self.truckName = truckName
        self.serviceName = serviceName
        self.day = day
        self.serviceWindow = serviceWindow
        self.location = location
        self.expectedCovers = max(0, expectedCovers)
        self.permitStatus = permitStatus
        self.powerSource = powerSource
    }
}

/// Discriminated union of mission types: Standard activity vs. Food-truck service.
public enum MissionKind: Codable, Sendable, Equatable, Hashable {
    case standardActivity(StandardActivityMetadata)
    case foodTruckService(FoodTruckServiceMetadata)
}

public struct MissionSnapshotFact: Codable, Sendable, Equatable, Hashable {
    public let label: String
    public let value: String

    public init(label: String, value: String) {
        self.label = label
        self.value = value
    }
}

public struct PlannedMission: Codable, Sendable, Equatable, Hashable {
    public let kind: MissionKind
    public let operationalSummary: String
    public let riskLevel: MissionRiskLevel
    public let status: MissionOperationalStatus
    public let fallbackPlan: String
    public let researchGuidance: [String]
    public let readinessChecklist: [ReadinessChecklistItem]
    public let snapshotFacts: [MissionSnapshotFact]

    public init(
        kind: MissionKind,
        operationalSummary: String,
        riskLevel: MissionRiskLevel,
        status: MissionOperationalStatus,
        fallbackPlan: String,
        researchGuidance: [String],
        readinessChecklist: [ReadinessChecklistItem],
        snapshotFacts: [MissionSnapshotFact]
    ) {
        self.kind = kind
        self.operationalSummary = operationalSummary
        self.riskLevel = riskLevel
        self.status = status
        self.fallbackPlan = fallbackPlan
        self.researchGuidance = researchGuidance
        self.readinessChecklist = readinessChecklist
        self.snapshotFacts = snapshotFacts
    }
}

// MARK: - 3. Configurable Food Truck Mission Factory Implementation

public struct ConfigurableFoodTruckMissionFactory: MissionFactory {
    public typealias Input = FoodTruckServiceMetadata
    public typealias Output = PlannedMission

    public let highVolumeCoverThreshold: Int
    public let moderateVolumeCoverThreshold: Int

    public init(
        highVolumeCoverThreshold: Int = 200,
        moderateVolumeCoverThreshold: Int = 100
    ) {
        self.highVolumeCoverThreshold = highVolumeCoverThreshold
        self.moderateVolumeCoverThreshold = moderateVolumeCoverThreshold
    }

    public func createMission(from input: FoodTruckServiceMetadata) -> PlannedMission {
        let riskLevel = evaluateRiskLevel(for: input)
        let status: MissionOperationalStatus = (input.permitStatus == .approved && riskLevel != .high) ? .go : .watch

        let summary = "\(input.truckName) — \(input.serviceName) (\(input.day), \(input.serviceWindow)) at \(input.location) for \(input.expectedCovers) expected covers [Permit: \(input.permitStatus.rawValue), Power: \(input.powerSource.displayName)]."

        let fallbackPlan = "If service throughput or site conditions degrade at \(input.location), switch \(input.truckName) to the reduced-menu high-efficiency line and relocate to the pre-vetted backup staging lot."

        let researchGuidance: [String] = [
            "Verify municipal mobile food vending permit (\(input.permitStatus.rawValue)) and health department inspection window for \(input.location).",
            "Confirm commissary load-out schedule, cold-chain logs, and \(input.powerSource.displayName.lowercased()) hookup or fuel reserves for \(input.expectedCovers) covers."
        ]

        let checklist: [ReadinessChecklistItem] = [
            ReadinessChecklistItem(
                category: .permits,
                detail: "Mobile food facility permit & site authorization (\(input.permitStatus.rawValue)) for \(input.location)",
                isReady: input.permitStatus == .approved
            ),
            ReadinessChecklistItem(
                category: .commissaryPreparation,
                detail: "Commissary prep, potable water fill, and cold-storage staging for \(input.serviceName)",
                isReady: true
            ),
            ReadinessChecklistItem(
                category: .inventory,
                detail: "Stocked primary + reduced-menu par levels for \(input.expectedCovers) expected covers",
                isReady: input.expectedCovers > 0
            ),
            ReadinessChecklistItem(
                category: .power,
                detail: "Validated \(input.powerSource.displayName) capacity for \(input.serviceWindow) service window",
                isReady: true
            ),
            ReadinessChecklistItem(
                category: .posAndConnectivity,
                detail: "POS terminals charged, cellular hotspot tested, and offline store-and-forward enabled",
                isReady: true
            ),
            ReadinessChecklistItem(
                category: .sanitationAndWaste,
                detail: "Handwashing station, sanitizer test strips, greywater tank capacity, and waste receptacles ready",
                isReady: true
            )
        ]

        let snapshotFacts: [MissionSnapshotFact] = [
            MissionSnapshotFact(label: "Truck", value: input.truckName),
            MissionSnapshotFact(label: "Service", value: input.serviceName),
            MissionSnapshotFact(label: "Schedule", value: "\(input.day) • \(input.serviceWindow)"),
            MissionSnapshotFact(label: "Location", value: input.location),
            MissionSnapshotFact(label: "Expected Covers", value: "\(input.expectedCovers)"),
            MissionSnapshotFact(label: "Permit Status", value: input.permitStatus.rawValue),
            MissionSnapshotFact(label: "Power Source", value: input.powerSource.displayName)
        ]

        return PlannedMission(
            kind: .foodTruckService(input),
            operationalSummary: summary,
            riskLevel: riskLevel,
            status: status,
            fallbackPlan: fallbackPlan,
            researchGuidance: researchGuidance,
            readinessChecklist: checklist,
            snapshotFacts: snapshotFacts
        )
    }

    private func evaluateRiskLevel(for input: FoodTruckServiceMetadata) -> MissionRiskLevel {
        if input.permitStatus == .required || (input.permitStatus == .pending && input.expectedCovers >= highVolumeCoverThreshold) {
            return .high
        }
        if input.permitStatus == .pending || input.expectedCovers >= highVolumeCoverThreshold {
            return .medium
        }
        if input.expectedCovers >= moderateVolumeCoverThreshold && input.powerSource == .batteryInverter {
            return .medium
        }
        return .low
    }
}
