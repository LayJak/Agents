import Foundation

enum Placement: String, Codable, CaseIterable, Identifiable {
    case outdoors = "Outdoors"
    case indoors = "Indoors"
    case greenhouse = "Greenhouse"
    var id: String { rawValue }
}

enum Culture: String, Codable, CaseIterable, Identifiable {
    case inGround = "In ground"
    case container = "Container"
    case raisedBed = "Raised bed"
    var id: String { rawValue }
}

enum SoilTexture: String, Codable, CaseIterable, Identifiable {
    case unknown = "Unknown", clay = "Clay", loam = "Loam", sand = "Sand"
    var id: String { rawValue }
}

enum Drainage: String, Codable, CaseIterable, Identifiable {
    case slow = "Slow", normal = "Normal", fast = "Fast"
    var id: String { rawValue }
}

enum MicroExposure: String, Codable, CaseIterable, Identifiable {
    case open = "Open yard", protectedPatio = "Protected patio", canopy = "Under canopy", frostPocket = "Frost pocket"
    var id: String { rawValue }
}

enum ThermalContext: String, Codable, CaseIterable, Identifiable {
    case openGround = "Open ground", masonry = "Near masonry", concrete = "Concrete / patio", woodDeck = "Wood deck"
    var id: String { rawValue }
}

enum WindExposure: String, Codable, CaseIterable, Identifiable {
    case sheltered = "Sheltered", normal = "Normal", exposed = "Exposed"
    var id: String { rawValue }
}

enum ContainerSize: String, Codable, CaseIterable, Identifiable {
    case small = "Small", medium = "Medium", large = "Large", extraLarge = "Extra large"
    var id: String { rawValue }
}

enum ReminderIntegration: String, Codable, CaseIterable, Identifiable {
    case appOnly = "Plant Watch only"
    case reminders = "Apple Reminders"
    case calendar = "Apple Calendar"
    case both = "Both"
    var id: String { rawValue }
}

struct GardenLocation: Codable, Equatable {
    var label: String = "McKinney, TX 75072"
    var latitude: Double = 33.1972
    var longitude: Double = -96.6398
    var zip: String = "75072"
}

struct SiteConditions: Codable, Equatable {
    var soilTexture: SoilTexture = .unknown
    var drainage: Drainage = .normal
    var exposure: MicroExposure = .open
    var thermalContext: ThermalContext = .openGround
    var orientation: String = ""
    var windExposure: WindExposure = .normal
    var containerSize: ContainerSize = .medium
    var rootDepthOverrideInches: Double? = nil
}

struct PlantJournalNote: Identifiable, Codable, Equatable {
    var id = UUID()
    var text: String
    var createdAt: Date = Date()
    var editedAt: Date? = nil
}

struct PlantReminder: Identifiable, Codable, Equatable {
    var id = UUID()
    var note: String
    var dueDate: Date
    var isEnabled: Bool = true
    var isResolved: Bool = false
    var integration: ReminderIntegration = .appOnly
    var appleReminderIdentifier: String? = nil
    var appleCalendarIdentifier: String? = nil
}

struct PestDiseaseItem: Identifiable, Codable, Equatable {
    var id = UUID()
    var name: String
    var risk: String = ""
    var season: String = ""
    var monitorFor: String = ""
    var regionalRelevance: String = ""
    var locationSpecific: Bool = false
}

struct ClimateProfile: Codable, Equatable {
    var usdaHardinessZoneMin: Double?
    var usdaHardinessZoneMax: Double?
    var ahsHeatZoneMin: Double?
    var ahsHeatZoneMax: Double?
    var protectBelowF: Double?
    var coldDamageF: Double?
    var lethalColdF: Double?
    var heatStressF: Double?
    var severeHeatF: Double?
    var lethalHeatF: Double?
    var preferredNightMaxF: Double?
    var hotNightStressF: Double?
    var hotNightFailureF: Double?
    var hotNightConsecutiveDays: Int?
    var chillHoursMin: Double?
    var chillHoursMax: Double?
}

struct WaterProfile: Codable, Equatable {
    var weeklyWaterInches: Double?
    var referenceEtCoefficient: Double?
    var droughtTolerance: String?
    var waterloggingTolerance: String?
    var summerAdjustmentPercent: Double?
    var winterAdjustmentPercent: Double?
}

struct SunProfile: Codable, Equatable {
    var preferredExposure: [String] = []
    var afternoonShadeRecommended: Bool = false
}

struct CareProfile: Codable, Equatable {
    var fertilizerType: String?
    var fertilizerFrequency: String?
    var fertilizerNotes: String?
    var pruningMethod: String?
    var pruningNotes: String?
    var pests: [PestDiseaseItem] = []
    var diseases: [PestDiseaseItem] = []
}

struct SeasonalProfile: Codable, Equatable {
    var seedStartIndoorsStart: String?
    var seedStartIndoorsEnd: String?
    var directSowStart: String?
    var directSowEnd: String?
    var transplantOutsideStart: String?
    var transplantOutsideEnd: String?
    var moveOutsideStart: String?
    var moveOutsideEnd: String?
    var moveInsideStart: String?
    var moveInsideEnd: String?
    var fertilizeStart: String?
    var fertilizeEnd: String?
    var pruneStart: String?
    var pruneEnd: String?
    var floweringStart: String?
    var floweringEnd: String?
    var harvestStart: String?
    var harvestEnd: String?
}

struct BiologyProfile: Codable, Equatable {
    var floweringCapable: Bool?
    var fruitingCapable: Bool?
    var fruitingTypicalInUserContext: Bool?
    var harvestRelevant: Bool?
    var evergreen: Bool?
    var deciduous: Bool?
    var growthHabit: [String] = []
}

struct ResearchProfile: Codable, Equatable {
    var scientificName: String?
    var cultivar: String?
    var family: String?
    var primaryCategory: String?
    var plantGroups: [String] = []
    var useCategories: [String] = []
    var climate = ClimateProfile()
    var water = WaterProfile()
    var sun = SunProfile()
    var care = CareProfile()
    var seasonal = SeasonalProfile()
    var biology = BiologyProfile()
    var locationSummary: String?
    var summerNotes: String?
    var winterNotes: String?
    var wateringNotes: String?
    var soilNotes: String?
    var microclimateNotes: String?
    var researchDate: String?
    var confidence: String?
    var rawJSON: String? = nil
}

struct Plant: Identifiable, Codable, Equatable {
    var id = UUID()
    var name: String
    var scientificName: String = ""
    var placement: Placement = .outdoors
    var culture: Culture = .inGround
    var monitoringSince: Date = Date()
    var imageURL: String = ""
    var site = SiteConditions()
    var profile: ResearchProfile? = nil
    var notes: [PlantJournalNote] = []
    var reminders: [PlantReminder] = []
    var irrigationZoneID: UUID? = nil
}

struct DeceasedPlant: Identifiable, Codable, Equatable {
    var id: UUID { plant.id }
    var plant: Plant
    var deathDate: Date
    var deathNote: String = ""
}

struct IrrigationZone: Identifiable, Codable, Equatable {
    var id = UUID()
    var name: String
    var precipitationRateInchesPerHour: Double = 0.5
    var minutesPerRun: Int = 20
    var weekdays: Set<Int> = []
    var hour: Int = 6
    var minute: Int = 0
}

struct WaterEvent: Identifiable, Codable, Equatable {
    enum Source: String, Codable { case rain, manual, irrigation }
    var id = UUID()
    var date: Date = Date()
    var inches: Double
    var source: Source
    var plantID: UUID? = nil
    var zoneID: UUID? = nil
}

struct AppSettings: Codable, Equatable {
    var location = GardenLocation()
    var useMetric = false
    var didSeedDemo = false
}

struct AppState: Codable, Equatable {
    var plants: [Plant] = []
    var plantHistory: [DeceasedPlant] = []
    var irrigationZones: [IrrigationZone] = []
    var waterEvents: [WaterEvent] = []
    var settings = AppSettings()
}

struct WeatherSnapshot: Equatable {
    var currentTemperatureF: Double?
    var currentHumidity: Double?
    var weatherCode: Int?
    var isDay: Bool = true
    var dailyHighF: Double?
    var dailyLowF: Double?
    var dailyPrecipitationIn: Double?
    var dailyET0In: Double?
    var hourly: [HourlyWeather] = []
    var daily: [DailyWeather] = []
}

struct HourlyWeather: Identifiable, Equatable {
    var id: Date { time }
    var time: Date
    var temperatureF: Double?
    var dewPointF: Double?
    var humidity: Double?
    var cloudCover: Double?
    var windMPH: Double?
    var gustMPH: Double?
    var precipitationProbability: Double?
    var precipitationIn: Double?
    var soilTemperatureF: Double?
    var soilMoisture: Double?
    var surfaceTemperatureF: Double?
    var et0In: Double?
    var shortwaveRadiation: Double?
}

struct DailyWeather: Identifiable, Equatable {
    var id: Date { date }
    var date: Date
    var highF: Double?
    var lowF: Double?
    var precipitationIn: Double?
    var et0In: Double?
    var windGustMPH: Double?
    var sunrise: Date?
    var sunset: Date?
}

struct GardenAlert: Identifiable, Equatable {
    enum Severity: Int, Comparable {
        case info = 0, watch = 1, warning = 2, critical = 3
        static func < (lhs: Severity, rhs: Severity) -> Bool { lhs.rawValue < rhs.rawValue }
    }
    var id: String
    var plantID: UUID?
    var severity: Severity
    var title: String
    var message: String
    var dueDate: Date? = nil
}

struct CalendarEvent: Identifiable, Equatable {
    enum Kind: String, CaseIterable, Identifiable {
        case planting = "Planting"
        case seedSow = "Seed sow"
        case transplant = "Transplant"
        case flowering = "Flowering"
        case harvest = "Harvest"
        case pruning = "Pruning"
        case fertilize = "Fertilize"
        case moveProtect = "Move / protect"
        var id: String { rawValue }
        var symbol: String {
            switch self {
            case .planting: return "leaf.fill"
            case .seedSow: return "circle.grid.cross.fill"
            case .transplant: return "arrow.down.to.line.compact"
            case .flowering: return "camera.macro"
            case .harvest: return "basket.fill"
            case .pruning: return "scissors"
            case .fertilize: return "drop.triangle.fill"
            case .moveProtect: return "shippingbox.fill"
            }
        }
    }
    var id: String
    var plantID: UUID
    var plantName: String
    var kind: Kind
    var title: String
    var start: Date
    var end: Date
    var details: String
}
