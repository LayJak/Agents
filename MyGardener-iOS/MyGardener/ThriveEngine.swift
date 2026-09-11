import Foundation

struct ThriveResult: Equatable {
    var zone: Int
    var seasonal: Bool
    var label: String
    var limiter: String
    var summary: String
    var confidence: String
    var code: String { "T\(zone)" + (seasonal ? "-S" : "") }
}

struct LocalClimateVector {
    var usdaZone: Double
    var ahsZone: Double
    var extremeMinF: Double
    var warmestMonthMeanMaxF: Double
    var warmestMonthMeanMinF: Double
    var summerVPDhPa: Double
    var summerRH: Double

    static func approximate(for location: GardenLocation) -> LocalClimateVector? {
        if abs(location.latitude - 33.1972) < 1.0 && abs(location.longitude + 96.6398) < 1.5 {
            return .init(usdaZone: 8, ahsZone: 9, extremeMinF: 12, warmestMonthMeanMaxF: 94, warmestMonthMeanMinF: 76, summerVPDhPa: 18, summerRH: 55)
        }
        return nil
    }
}

enum ThriveEngine {
    static func evaluate(plant: Plant, location: GardenLocation) -> ThriveResult? {
        guard let profile = plant.profile, let climate = LocalClimateVector.approximate(for: location) else { return nil }
        let c = profile.climate
        var components: [(String, Double)] = []
        if let damage = c.coldDamageF, let lethal = c.lethalColdF {
            components.append(("Winter cold", lowerScore(climate.extremeMinF, good: damage, fail: lethal)))
        } else if let minZone = c.usdaHardinessZoneMin {
            components.append(("Winter cold", climate.usdaZone >= minZone ? 100 : max(0, 100 - (minZone-climate.usdaZone)*35)))
        }
        if let maxAHS = c.ahsHeatZoneMax, climate.ahsZone > maxAHS {
            components.append(("Chronic heat", max(0, 100 - (climate.ahsZone-maxAHS)*30)))
        } else if let heatStress = c.heatStressF {
            components.append(("Daytime heat", upperScore(climate.warmestMonthMeanMaxF, good: heatStress, fail: c.severeHeatF ?? heatStress+10)))
        } else { components.append(("Chronic heat", 90)) }
        if let night = c.hotNightStressF { components.append(("Warm nights", upperScore(climate.warmestMonthMeanMinF, good: night, fail: c.hotNightFailureF ?? night+8))) }
        guard !components.isEmpty else { return nil }
        let worst = components.min(by: {$0.1 < $1.1})!
        let cold = components.first(where: {$0.0 == "Winter cold"})?.1
        let portable = plant.culture == .container && (profile.primaryCategory?.lowercased().contains("houseplant") == true || profile.plantGroups.map{$0.lowercased()}.contains(where:{ $0.contains("tropical") || $0.contains("aroid") }) || (c.usdaHardinessZoneMin ?? 0) >= 9.5)
        let warm = components.filter{$0.0 != "Winter cold"}.map{$0.1}.reduce(0,+) / Double(max(1, components.filter{$0.0 != "Winter cold"}.count))
        if let cold, cold < 15, portable {
            let z = warm >= 88 ? 5 : warm >= 75 ? 4 : warm >= 58 ? 3 : 2
            return .init(zone:z,seasonal:true,label:z>=5 ? "Core seasonal" : z==4 ? "Suitable seasonal" : z==3 ? "Conditional seasonal" : "Marginal seasonal",limiter:"Winter cold",summary:"Warm-season outdoor conditions are favorable, but this plant is not reliably winter-hardy here. Move it to protected conditions before damaging cold.",confidence:"Moderate")
        }
        let z = worst.1 >= 85 ? 5 : worst.1 >= 72 ? 4 : worst.1 >= 50 ? 3 : worst.1 >= 25 ? 2 : 1
        let label = [1:"Unsuitable",2:"Marginal",3:"Conditional",4:"Suitable",5:"Core"][z]!
        return .init(zone:z,seasonal:false,label:label,limiter:worst.0,summary:z>=4 ? "The long-term climate is broadly compatible with this plant." : "\(worst.0) is the primary long-term climate constraint at this location.",confidence:"Moderate")
    }

    private static func lowerScore(_ x:Double, good:Double, fail:Double)->Double { if x>=good{return 100};if x<=fail{return 0};let t=(x-fail)/(good-fail);return 100*t*t*(3-2*t) }
    private static func upperScore(_ x:Double, good:Double, fail:Double)->Double { if x<=good{return 100};if x>=fail{return 0};let t=(fail-x)/(fail-good);return 100*t*t*(3-2*t) }
}
