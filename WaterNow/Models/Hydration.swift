import Foundation

struct HydrationEntry: Identifiable, Codable, Hashable {
    let id: UUID
    var amountML: Int          // milliliters
    var loggedAt: Date
    var beverage: BeverageType

    init(id: UUID = UUID(), amountML: Int, loggedAt: Date = Date(), beverage: BeverageType = .water) {
        self.id = id
        self.amountML = amountML
        self.loggedAt = loggedAt
        self.beverage = beverage
    }
}

enum BeverageType: String, Codable, CaseIterable, Identifiable {
    case water, tea, coffee, juice, sparkling, other

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .water:     return "Water"
        case .tea:       return "Tea"
        case .coffee:    return "Coffee"
        case .juice:     return "Juice"
        case .sparkling: return "Sparkling"
        case .other:     return "Other"
        }
    }

    var emoji: String {
        switch self {
        case .water:     return "💧"
        case .tea:       return "🍵"
        case .coffee:    return "☕"
        case .juice:     return "🧃"
        case .sparkling: return "🥤"
        case .other:     return "🥛"
        }
    }
}

enum CupSize: Int, CaseIterable, Identifiable {
    case sip = 100
    case glass = 250
    case bottle = 500
    case largeBottle = 1000

    var id: Int { rawValue }

    var displayName: String {
        switch self {
        case .sip:         return "Sip (100 ml)"
        case .glass:       return "Glass (250 ml)"
        case .bottle:      return "Bottle (500 ml)"
        case .largeBottle: return "Large bottle (1 L)"
        }
    }
}
