import Foundation

enum BodyRegion: String, Codable, CaseIterable, Identifiable {
    case fullBody
    case head
    case chest
    case abdomen
    case pelvis
    case leftArm
    case rightArm
    case leftLeg
    case rightLeg

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .fullBody:
            return "Full Body"
        case .head:
            return "Head"
        case .chest:
            return "Chest"
        case .abdomen:
            return "Abdomen"
        case .pelvis:
            return "Pelvis"
        case .leftArm:
            return "Left Arm"
        case .rightArm:
            return "Right Arm"
        case .leftLeg:
            return "Left Leg"
        case .rightLeg:
            return "Right Leg"
        }
    }

    var systemImage: String {
        switch self {
        case .fullBody:
            return "person"
        case .head:
            return "brain.head.profile"
        case .chest:
            return "lungs"
        case .abdomen:
            return "circle.grid.cross"
        case .pelvis:
            return "figure.stand"
        case .leftArm, .rightArm:
            return "hand.raised"
        case .leftLeg, .rightLeg:
            return "figure.walk"
        }
    }
}

struct VaccineRecord: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var date: Date
    var region: BodyRegion
    var provider: String
    var notes: String
}

struct DiagnosticResult: Identifiable, Codable, Equatable {
    let id: UUID
    var testName: String
    var resultSummary: String
    var date: Date
    var region: BodyRegion
    var notes: String
}

enum MedicationKind: String, Codable, CaseIterable, Identifiable {
    case medication
    case supplement

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .medication:
            return "Medication"
        case .supplement:
            return "Supplement"
        }
    }
}

struct MedicationRecord: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var kind: MedicationKind
    var date: Date
    var region: BodyRegion
    var sideEffects: String
    var notes: String
}

enum SampleData {
    static let vaccines: [VaccineRecord] = [
        VaccineRecord(
            id: UUID(),
            name: "Influenza",
            date: Date().addingTimeInterval(-3600 * 24 * 90),
            region: .chest,
            provider: "City Clinic",
            notes: "Seasonal vaccine"
        ),
        VaccineRecord(
            id: UUID(),
            name: "Hepatitis B",
            date: Date().addingTimeInterval(-3600 * 24 * 365 * 2),
            region: .rightArm,
            provider: "Primary Care",
            notes: "Dose 3 of 3"
        ),
        VaccineRecord(
            id: UUID(),
            name: "HPV",
            date: Date().addingTimeInterval(-3600 * 24 * 365 * 4),
            region: .pelvis,
            provider: "Community Health",
            notes: "Series complete"
        )
    ]

    static let diagnostics: [DiagnosticResult] = [
        DiagnosticResult(
            id: UUID(),
            testName: "HIV Antigen/Antibody",
            resultSummary: "Negative",
            date: Date().addingTimeInterval(-3600 * 24 * 180),
            region: .pelvis,
            notes: "Routine screening"
        ),
        DiagnosticResult(
            id: UUID(),
            testName: "Influenza A/B",
            resultSummary: "Negative",
            date: Date().addingTimeInterval(-3600 * 24 * 30),
            region: .chest,
            notes: "Rapid test"
        ),
        DiagnosticResult(
            id: UUID(),
            testName: "CBC",
            resultSummary: "Within normal range",
            date: Date().addingTimeInterval(-3600 * 24 * 365),
            region: .fullBody,
            notes: "Annual check"
        )
    ]

    static let medications: [MedicationRecord] = [
        MedicationRecord(
            id: UUID(),
            name: "Amoxicillin",
            kind: .medication,
            date: Date().addingTimeInterval(-3600 * 24 * 21),
            region: .chest,
            sideEffects: "Mild nausea on day 2",
            notes: "7-day course"
        ),
        MedicationRecord(
            id: UUID(),
            name: "Vitamin D",
            kind: .supplement,
            date: Date().addingTimeInterval(-3600 * 24 * 60),
            region: .fullBody,
            sideEffects: "None",
            notes: "Daily 1000 IU"
        )
    ]
}
