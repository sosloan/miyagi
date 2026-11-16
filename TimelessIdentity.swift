//
//  TimelessIdentity.swift
//  MySLOANLibrary
//
//  "Under Pressure: How the City of Light Crystallizes Identity Through Time"
//  & Nathan C. Schaeffer's "Thinking and Learning to Think":
//    "Man's vocal organs are correlated with his brain; they are co-operative.
//     Man is a thinking being, whether he will or no.
//     All he can do is to turn his thoughts the best way."
//
//  PRESSURE + TIME + CARBON = DIAMOND
//  OBSERVATION + DURATION + IDENTITY = PARIS
//  THOUGHT + CORRELATION + INVARIANCE = PURE IDENTITY (🦁)
//

import Foundation

/// Computes Euclidean spectral distance between two eigenvalue spectra.
public func spectralDistance(_ a: [Double], _ b: [Double]) -> Double {
    let n = min(a.count, b.count)
    guard n > 0 else { return 0.0 }
    let sumSq = (0..<n).reduce(0.0) { acc, i in
        let diff = a[i] - b[i]
        return acc + diff * diff
    }
    return (sumSq / Double(n)).squareRoot()
}

// MARK: - 1. Crystallized Identity & Timeless Transform

public struct CrystallizedIdentity<Essence: Sendable>: Sendable, Equatable where Essence: Equatable {
    public let essence: Essence
    public let pressureApplied: TimelessTransform<Essence>.Pressure
    public let timeElapsed: TimelessTransform<Essence>.Duration
    public let preservedEigenvalues: [Double]
    public let crystallinePurity: Double

    public init(
        essence: Essence,
        pressureApplied: TimelessTransform<Essence>.Pressure,
        timeElapsed: TimelessTransform<Essence>.Duration,
        preservedEigenvalues: [Double],
        crystallinePurity: Double
    ) {
        self.essence = essence
        self.pressureApplied = pressureApplied
        self.timeElapsed = timeElapsed
        self.preservedEigenvalues = preservedEigenvalues
        self.crystallinePurity = crystallinePurity
    }
}

public struct TimelessTransform<Essence: Sendable>: Sendable where Essence: Equatable {
    public let initial: Essence
    public let pressure: Pressure
    public let duration: Duration
    public let eigenvalues: [Double]

    public struct Pressure: Sendable, Equatable {
        public let magnitude: Double
        public let type: PressureType

        public enum PressureType: String, Sendable, Equatable {
            case geological
            case biological
            case historical
            case observational
            case existential
        }

        public init(magnitude: Double, type: PressureType) {
            self.magnitude = magnitude
            self.type = type
        }
    }

    public struct Duration: Sendable, Equatable {
        public let span: TimeInterval
        public let epochs: [Epoch]

        public struct Epoch: Sendable, Equatable {
            public let name: String
            public let years: Range<Int>
            public let transformation: String

            public init(name: String, years: Range<Int>, transformation: String) {
                self.name = name
                self.years = years
                self.transformation = transformation
            }
        }

        public var isTimeless: Bool {
            span > 1000.0
        }

        public init(span: TimeInterval, epochs: [Epoch] = []) {
            self.span = span
            self.epochs = epochs
        }
    }

    public init(initial: Essence, pressure: Pressure, duration: Duration, eigenvalues: [Double]) {
        self.initial = initial
        self.pressure = pressure
        self.duration = duration
        self.eigenvalues = eigenvalues
    }

    public func crystallize() -> CrystallizedIdentity<Essence> {
        CrystallizedIdentity(
            essence: initial,
            pressureApplied: pressure,
            timeElapsed: duration,
            preservedEigenvalues: eigenvalues,
            crystallinePurity: computePurity()
        )
    }

    private func computePurity() -> Double {
        let pressureFactor = min(1.0, pressure.magnitude / 1e6)
        let timeFactor = duration.isTimeless ? 1.0 : duration.span / 1000.0
        return (pressureFactor + timeFactor) / 2.0
    }
}

// MARK: - 2. Nathan C. Schaeffer — "Thinking and Learning to Think" Correlation

/// Formalizes Nathan C. Schaeffer's principle from *Thinking and Learning to Think*:
/// - "Man’s vocal organs are correlated with his brain. They are co-operative."
/// - "Man is a thinking being, whether he will or no. All he can do is to turn his thoughts the best way."
/// - Even when peripheral/vocal organs face biological pressure, the brain's thought vector
///   and intrinsic identity (`prince_compose_male_idempotent: XX ∘ AKA = 🦁`) remain invariant.
public struct SchaefferThinkingCorrelation: Sendable, Equatable {
    public static let epigraph = """
    "Man’s vocal organs are correlated with his brain. They are co-operative. \
    Man is a thinking being, whether he will or no. All he can do is to turn his thoughts the best way."
    — Nathan C. Schaeffer, Thinking and Learning to Think (Project Gutenberg)
    """

    /// Fundamental cognitive/identity spectrum `[2.37, 1.83, 1.41, 0.92, 0.61]`
    public let brainThoughtEigenvalues: [Double]
    /// Vocal / expressive channel eigenvalues (co-operative projection of thought)
    public let vocalOrganEigenvalues: [Double]
    /// Direction unit vector ("turn his thoughts the best way")
    public let thoughtDirection: [Double]

    public init(
        brainThoughtEigenvalues: [Double] = [2.37, 1.83, 1.41, 0.92, 0.61],
        vocalOrganEigenvalues: [Double] = [2.37, 1.83, 1.41, 0.92, 0.61],
        thoughtDirection: [Double] = [1.0, 0.0, 0.0, 0.0, 0.0]
    ) {
        self.brainThoughtEigenvalues = brainThoughtEigenvalues
        self.vocalOrganEigenvalues = vocalOrganEigenvalues
        self.thoughtDirection = thoughtDirection
    }

    /// Pearson / cosine co-operation correlation between brain and expressive channel.
    public var cooperativeCorrelation: Double {
        let num = zip(brainThoughtEigenvalues, vocalOrganEigenvalues).reduce(0.0) { $0 + $1.0 * $1.1 }
        let normA = brainThoughtEigenvalues.reduce(0.0) { $0 + $1 * $1 }.squareRoot()
        let normB = vocalOrganEigenvalues.reduce(0.0) { $0 + $1 * $1 }.squareRoot()
        guard normA > 0, normB > 0 else { return 0.0 }
        return num / (normA * normB)
    }

    /// Verifies `prince_compose_male_idempotent: XX ∘ AKA = 🦁` (intrinsic male gender idempotence).
    public static func verifyPrinceMaleIdempotence() -> (bundle: FeatureBundle, isIdempotent: Bool, lionSymbol: String) {
        let prince = FeatureBundle.prince
        let maleMarker = FeatureBundle.genderMarker(.male)
        let composed = prince.composed(with: maleMarker)
        return (composed, composed == prince, "🦁")
    }
}

// MARK: - 3. Paris & Diamond Isospectral Verification

public struct Paris: Sendable {
    public let founded: Int = -250
    public let currentYear: Int = 2025
    public var age: Int { currentYear - founded }

    public let eigenvalues: [Double] = [
        3.14159, // λ₀: Beauty (π)
        2.71828, // λ₁: Life (e)
        1.61803, // λ₂: Proportion (φ)
        1.41421, // λ₃: Reason (√2)
        0.57721  // λ₄: Memory (γ)
    ]

    public let epochs: [TimelessTransform<String>.Duration.Epoch] = [
        .init(name: "Lutetia Romana", years: -250..<486, transformation: "Roman settlement → Gallo-Roman city"),
        .init(name: "Medieval Paris", years: 486..<1328, transformation: "Frankish capital → Gothic cathedral city"),
        .init(name: "Renaissance", years: 1328..<1589, transformation: "Medieval walls → Renaissance palace culture"),
        .init(name: "Absolutism", years: 1589..<1789, transformation: "City of kings → Versailles shadow"),
        .init(name: "Revolutionary", years: 1789..<1799, transformation: "Royal capital → Republic birthplace (Bastille falls)"),
        .init(name: "Napoleonic", years: 1799..<1815, transformation: "Revolution chaos → Imperial grandeur (Arc de Triomphe)"),
        .init(name: "Haussmann", years: 1853..<1870, transformation: "Medieval warren → Modern boulevards (radical surgery)"),
        .init(name: "Belle Époque", years: 1871..<1914, transformation: "War-scarred → Cultural zenith (Eiffel Tower, Métro)"),
        .init(name: "World Wars", years: 1914..<1945, transformation: "Open city → Occupied → Liberated"),
        .init(name: "Les Trente Glorieuses", years: 1945..<1975, transformation: "War ruins → Modern prosperity (Pompidou, La Défense)"),
        .init(name: "Contemporary", years: 1975..<2025, transformation: "Industrial → Post-industrial (Louvre Pyramid, Notre-Dame fire)")
    ]

    public struct PressureEvent: Sendable {
        public let year: Int
        public let name: String
        public let magnitude: Double
        public let description: String
    }

    public let pressureEvents: [PressureEvent] = [
        .init(year: 1789, name: "French Revolution", magnitude: 1e6, description: "Monarchy abolished, Bastille destroyed"),
        .init(year: 1871, name: "Paris Commune", magnitude: 0.8e6, description: "Civil war, Hôtel de Ville burned"),
        .init(year: 1940, name: "Nazi Occupation", magnitude: 0.9e6, description: "Four years under occupation"),
        .init(year: 1853, name: "Haussmann's Renovation", magnitude: 0.7e6, description: "60% of buildings demolished"),
        .init(year: 2019, name: "Notre-Dame Fire", magnitude: 0.5e6, description: "850-year-old cathedral burns")
    ]

    public init() {}

    public func verifyTimelessIdentity() -> TimelessVerification {
        var verification = TimelessVerification(entity: "Paris", baselineEigenvalues: eigenvalues, epochs: [])
        for epoch in epochs {
            let measured = measureEigenvalues(atYear: epoch.years.upperBound)
            let distance = spectralDistance(measured, eigenvalues)
            verification.epochs.append(
                .init(
                    name: epoch.name,
                    years: epoch.years,
                    spectralDistance: distance,
                    preserved: distance < 0.25,
                    transformation: epoch.transformation
                )
            )
        }
        return verification
    }

    private func measureEigenvalues(atYear year: Int) -> [Double] {
        let stress = pressureEvents
            .filter { abs($0.year - year) < 50 }
            .map { $0.magnitude / 1e6 }
            .reduce(0, +)
        return eigenvalues.map { $0 * (1.0 - stress * 0.05) }
    }

    public struct TimelessVerification: Sendable {
        public let entity: String
        public let baselineEigenvalues: [Double]
        public var epochs: [EpochVerification]

        public struct EpochVerification: Sendable {
            public let name: String
            public let years: Range<Int>
            public let spectralDistance: Double
            public let preserved: Bool
            public let transformation: String
        }

        public var allEpochsPreserved: Bool {
            epochs.allSatisfy(\.preserved)
        }
    }
}

public struct DiamondFormation: Sendable {
    public let initialCarbon: Carbon
    public let depth: Double = 150_000
    public let pressure: Double = 725_000
    public let temperature: Double = 1200
    public let duration: Double = 1e9

    public struct Carbon: Sendable, Equatable {
        public let atoms: Int
        public let structure: Structure

        public enum Structure: Sendable, Equatable {
            case graphite
            case amorphous
            case diamond
        }

        public init(atoms: Int, structure: Structure) {
            self.atoms = atoms
            self.structure = structure
        }

        public var eigenvalues: [Double] {
            switch structure {
            case .graphite: return [2.37, 1.83, 1.41, 0.92, 0.61]
            case .amorphous: return [2.35, 1.85, 1.39, 0.94, 0.59]
            case .diamond: return [2.37, 1.83, 1.41, 0.92, 0.61]
            }
        }
    }

    public init(initialCarbon: Carbon) {
        self.initialCarbon = initialCarbon
    }

    public func crystallize() -> Diamond {
        Diamond(
            carbon: initialCarbon,
            clarity: 1.0,
            eigenvalues: initialCarbon.eigenvalues,
            ageInBillionYears: duration / 1e9
        )
    }

    public struct Diamond: Sendable, Equatable {
        public let carbon: Carbon
        public let clarity: Double
        public let eigenvalues: [Double]
        public let ageInBillionYears: Double

        public var isPerfect: Bool { clarity > 0.99 }

        public func verifyIdentity() -> Bool {
            spectralDistance(
                eigenvalues,
                Carbon(atoms: carbon.atoms, structure: .graphite).eigenvalues
            ) < 0.01
        }
    }
}
