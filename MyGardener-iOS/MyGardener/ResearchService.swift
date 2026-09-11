import Foundation

actor ResearchService {
    static let shared = ResearchService()
    static let keychainKey = "mygardener.gemini.apiKey"

    enum ResearchError: LocalizedError { case noKey, invalidResponse; var errorDescription: String? { self == .noKey ? "Save your Gemini API key in More first." : "Plant research could not be completed." } }

    func research(plant: Plant, location: GardenLocation) async throws -> ResearchProfile {
        guard let key = KeychainStore.get(Self.keychainKey), !key.isEmpty else { throw ResearchError.noKey }
        let prompt = """
        Return JSON only. Create a practical horticultural profile for MyGardener at \(location.label) (\(location.latitude), \(location.longitude)). Plant: \(plant.name) \(plant.scientificName).
        Include: scientificName, cultivar, family, primaryCategory, plantGroups, useCategories; climate {usdaHardinessZoneMin, usdaHardinessZoneMax, ahsHeatZoneMin, ahsHeatZoneMax, protectBelowF, coldDamageF, lethalColdF, heatStressF, severeHeatF, lethalHeatF, preferredNightMaxF, hotNightStressF, hotNightFailureF, hotNightConsecutiveDays, chillHoursMin, chillHoursMax}; water {weeklyWaterInches, referenceEtCoefficient, droughtTolerance, waterloggingTolerance, summerAdjustmentPercent, winterAdjustmentPercent}; sun {preferredExposure, afternoonShadeRecommended}; care {fertilizerType, fertilizerFrequency, fertilizerNotes, pruningMethod, pruningNotes, pests, diseases}; seasonal {seedStartIndoorsStart, seedStartIndoorsEnd, directSowStart, directSowEnd, transplantOutsideStart, transplantOutsideEnd, moveOutsideStart, moveOutsideEnd, moveInsideStart, moveInsideEnd, fertilizeStart, fertilizeEnd, pruneStart, pruneEnd, floweringStart, floweringEnd, harvestStart, harvestEnd}; biology {floweringCapable, fruitingCapable, fruitingTypicalInUserContext, harvestRelevant, evergreen, deciduous, growthHabit}; locationSummary, summerNotes, winterNotes, wateringNotes, soilNotes, microclimateNotes, researchDate, confidence. Seasonal dates are MM-DD. Use null rather than invented values. Distinguish biological fruiting capability from harvest relevance. Pests/diseases must be host- and location-specific with name, risk, season, monitorFor, regionalRelevance, locationSpecific.
        """
        let models = ["gemini-3.5-flash", "gemini-3.5-flash-lite"]
        var last: Error = ResearchError.invalidResponse
        for model in models {
            do {
                var c = URLComponents(string: "https://generativelanguage.googleapis.com/v1beta/models/\(model):generateContent")!
                c.queryItems = [.init(name: "key", value: key)]
                var req = URLRequest(url: c.url!); req.httpMethod = "POST"; req.setValue("application/json", forHTTPHeaderField: "Content-Type")
                let body: [String: Any] = ["contents": [["parts": [["text": prompt]]]], "generationConfig": ["responseMimeType": "application/json"]]
                req.httpBody = try JSONSerialization.data(withJSONObject: body)
                let (data, response) = try await URLSession.shared.data(for: req)
                guard (response as? HTTPURLResponse)?.statusCode == 200 else { throw ResearchError.invalidResponse }
                let root = try JSONSerialization.jsonObject(with: data) as? [String: Any]
                let candidates = root?["candidates"] as? [[String: Any]]
                let content = candidates?.first?["content"] as? [String: Any]
                let parts = content?["parts"] as? [[String: Any]]
                guard let text = parts?.compactMap({ $0["text"] as? String }).joined(), let json = text.data(using: .utf8) else { throw ResearchError.invalidResponse }
                var profile = try JSONDecoder().decode(ResearchProfile.self, from: json)
                profile.rawJSON = text
                return profile
            } catch { last = error }
        }
        throw last
    }
}
