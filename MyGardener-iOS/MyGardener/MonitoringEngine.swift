import Foundation

enum MonitoringEngine {
    static func evaluate(plants: [Plant], weather: WeatherSnapshot, waterEvents: [WaterEvent], now: Date = Date()) -> [GardenAlert] {
        var out: [GardenAlert] = []
        let next48 = weather.hourly.filter { $0.time >= now && $0.time <= now.addingTimeInterval(48*3600) }
        let next24 = next48.filter { $0.time <= now.addingTimeInterval(24*3600) }
        let min48 = next48.compactMap(\.temperatureF).min()
        let max24 = next24.compactMap(\.temperatureF).max()

        for plant in plants where plant.placement == .outdoors {
            let c = plant.profile?.climate
            let protect = effectiveColdProtectThreshold(plant)
            if let min48, min48 <= protect {
                let hours = next48.filter { ($0.temperatureF ?? 999) <= protect }.count
                let sev: GardenAlert.Severity = min48 <= (c?.coldDamageF ?? protect - 6) ? .critical : .warning
                out.append(.init(id: "cold-\(plant.id)", plantID: plant.id, severity: sev, title: "Cold protection · \(plant.name)", message: "Forecast reaches \(Int(min48.rounded()))°F with about \(hours) hour\(hours == 1 ? "" : "s") at or below this plant's protection threshold of \(Int(protect.rounded()))°F."))
            } else if radiationalFrostRisk(next24), let low = next24.compactMap(\.temperatureF).min(), low <= protect + 8 {
                out.append(.init(id: "frost-\(plant.id)", plantID: plant.id, severity: .watch, title: "Radiational frost watch · \(plant.name)", message: "Clear, calm conditions may cool exposed leaf surfaces below the 2-meter air forecast. Check this plant before sunrise."))
            }

            if let max24, let stress = c?.heatStressF, max24 >= stress {
                out.append(.init(id: "heat-\(plant.id)", plantID: plant.id, severity: max24 >= (c?.severeHeatF ?? stress + 8) ? .warning : .watch, title: "Heat stress · \(plant.name)", message: "Forecast high \(Int(max24.rounded()))°F exceeds this plant's heat-stress threshold. \(plant.profile?.sun.afternoonShadeRecommended == true ? "Prioritize filtered or afternoon shade." : "Check water status and exposure.")"))
            }

            if let nightStress = c?.hotNightStressF {
                let nights = consecutiveWarmNights(hours: weather.hourly, threshold: nightStress)
                if nights >= max(2, c?.hotNightConsecutiveDays ?? 2) {
                    out.append(.init(id: "hotnight-\(plant.id)", plantID: plant.id, severity: .watch, title: "Warm-night stress · \(plant.name)", message: "Night temperatures are remaining above \(Int(nightStress))°F for a sustained sequence. This can reduce recovery, flowering, or fruit set for sensitive plants."))
                }
            }

            if waterloggingRisk(plant: plant, weather: weather) {
                out.append(.init(id: "waterlog-\(plant.id)", plantID: plant.id, severity: .warning, title: "Drainage risk · \(plant.name)", message: "Recent/forecast rain plus this plant's drainage profile suggests prolonged saturation. Hold irrigation and check drainage."))
            }
        }

        for plant in plants {
            for r in plant.reminders where r.isEnabled && !r.isResolved && r.dueDate <= now {
                out.append(.init(id: "reminder-\(r.id)", plantID: plant.id, severity: .info, title: plant.name, message: r.note, dueDate: r.dueDate))
            }
        }
        return out.sorted { $0.severity > $1.severity }
    }

    static func effectiveColdProtectThreshold(_ plant: Plant) -> Double {
        let base = plant.profile?.climate.protectBelowF ?? plant.profile?.climate.coldDamageF ?? 40
        guard plant.culture == .container else { return base + microclimateColdOffset(plant.site) }
        let containerPenalty: Double
        switch plant.site.containerSize { case .small: containerPenalty = 9; case .medium: containerPenalty = 7; case .large: containerPenalty = 5; case .extraLarge: containerPenalty = 3 }
        let exposurePenalty = plant.site.windExposure == .exposed ? 2.0 : plant.site.windExposure == .sheltered ? -1.0 : 0
        return base + max(2, containerPenalty + exposurePenalty) + microclimateColdOffset(plant.site)
    }

    static func rootZoneCapacityIn(_ plant: Plant) -> Double {
        let awc: Double
        switch plant.site.soilTexture { case .sand: awc = 0.06; case .clay: awc = 0.17; case .loam, .unknown: awc = 0.12 }
        let depth: Double
        if let d = plant.site.rootDepthOverrideInches { depth = d }
        else if plant.culture == .container {
            switch plant.site.containerSize { case .small: depth = 6; case .medium: depth = 10; case .large: depth = 16; case .extraLarge: depth = 22 }
        } else {
            let cat = plant.profile?.primaryCategory?.lowercased() ?? ""
            if cat.contains("tree") { depth = 30 } else if cat.contains("shrub") { depth = 22 } else if cat.contains("annual") { depth = 8 } else { depth = 14 }
        }
        return max(0.15, awc * depth)
    }

    static func effectiveRain(_ rain: Double, intensityInPerHour: Double?, plant: Plant, saturation: Double = 0.4) -> Double {
        let drainageFactor: Double = plant.site.drainage == .fast ? 0.78 : plant.site.drainage == .slow ? 0.9 : 0.86
        let soilFactor: Double = plant.site.soilTexture == .clay ? 0.82 : plant.site.soilTexture == .sand ? 0.88 : 0.92
        let intensity = intensityInPerHour ?? 0.25
        let intensityFactor = max(0.45, min(1.0, 1.05 - max(0, intensity - 0.4) * 0.28))
        let saturationFactor = max(0.35, 1 - max(0, saturation - 0.65) * 1.5)
        return rain * drainageFactor * soilFactor * intensityFactor * saturationFactor
    }

    static func plantDemandET0(_ plant: Plant, et0In: Double) -> Double {
        let kc = plant.profile?.water.referenceEtCoefficient ?? defaultKc(plant)
        return et0In * kc
    }

    private static func defaultKc(_ plant: Plant) -> Double {
        let drought = plant.profile?.water.droughtTolerance?.lowercased() ?? ""
        if drought == "high" { return 0.45 }
        if drought == "low" { return 0.9 }
        return 0.7
    }

    private static func microclimateColdOffset(_ s: SiteConditions) -> Double {
        var x = 0.0
        if s.exposure == .frostPocket { x += 4 }
        if s.exposure == .protectedPatio || s.exposure == .canopy { x -= 1.5 }
        if s.thermalContext == .masonry { x -= 1.5 }
        if s.windExposure == .exposed { x += 1 }
        return x
    }

    private static func radiationalFrostRisk(_ hours: [HourlyWeather]) -> Bool {
        guard !hours.isEmpty else { return false }
        return hours.contains { h in
            guard let t = h.temperatureF else { return false }
            let cloud = h.cloudCover ?? 50, wind = h.windMPH ?? 8
            let surface = h.surfaceTemperatureF ?? t
            let dew = h.dewPointF ?? t - 8
            let frostPointNear = t - dew <= 8
            let radiative = cloud < 30 && wind < 5 && surface <= t - 2
            return t <= 42 && (radiative || frostPointNear)
        }
    }

    private static func consecutiveWarmNights(hours: [HourlyWeather], threshold: Double) -> Int {
        let cal = Calendar.current
        let grouped = Dictionary(grouping: hours) { cal.startOfDay(for: $0.time) }
        var count = 0, best = 0
        for day in grouped.keys.sorted() {
            let lows = grouped[day]!.compactMap(\.temperatureF)
            if let low = lows.min(), low >= threshold { count += 1; best = max(best, count) } else { count = 0 }
        }
        return best
    }

    private static func waterloggingRisk(plant: Plant, weather: WeatherSnapshot) -> Bool {
        guard (plant.profile?.water.waterloggingTolerance ?? "moderate").lowercased() == "low" else { return false }
        let rain48 = weather.hourly.prefix(48).compactMap(\.precipitationIn).reduce(0,+)
        return rain48 >= 1.5 && (plant.site.drainage == .slow || plant.site.soilTexture == .clay)
    }
}
