import Foundation

enum BodyProfile: String, CaseIterable, Identifiable, Codable {
    case male
    case female
    case other
    case realistic

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .male:
            return "Male"
        case .female:
            return "Female"
        case .other:
            return "Other"
        case .realistic:
            return "Realistic"
        }
    }

    var imageName: String {
        switch self {
        case .male:
            return "BodyMale"
        case .female:
            return "BodyFemale"
        case .other:
            return "BodyOther"
        case .realistic:
            return "BodyRealistic"
        }
    }
}
