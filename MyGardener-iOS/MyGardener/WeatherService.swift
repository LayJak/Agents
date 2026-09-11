import Foundation

actor WeatherService {
    enum WeatherError: LocalizedError {
        case badURL, invalidResponse
        var errorDescription: String? { switch self { case .badURL: return "Could not create weather request."; case .invalidResponse: return "Weather data was unavailable." } }
    }

    func fetch(location: GardenLocation) async throws -> WeatherSnapshot {
        var c = URLComponents(string: "https://api.open-meteo.com/v1/forecast")!
        c.queryItems = [
            .init(name: "latitude", value: String(location.latitude)),
            .init(name: "longitude", value: String(location.longitude)),
            .init(name: "temperature_unit", value: "fahrenheit"),
            .init(name: "wind_speed_unit", value: "mph"),
            .init(name: "precipitation_unit", value: "inch"),
            .init(name: "timezone", value: "auto"),
            .init(name: "forecast_days", value: "10"),
            .init(name: "current", value: "temperature_2m,relative_humidity_2m,weather_code,is_day"),
            .init(name: "hourly", value: "temperature_2m,dew_point_2m,relative_humidity_2m,cloud_cover,wind_speed_10m,wind_gusts_10m,precipitation_probability,precipitation,soil_temperature_6cm,soil_moisture_3_to_9cm,surface_temperature,et0_fao_evapotranspiration,shortwave_radiation"),
            .init(name: "daily", value: "temperature_2m_max,temperature_2m_min,precipitation_sum,et0_fao_evapotranspiration,wind_gusts_10m_max,sunrise,sunset")
        ]
        guard let url = c.url else { throw WeatherError.badURL }
        let (data, response) = try await URLSession.shared.data(from: url)
        guard (response as? HTTPURLResponse)?.statusCode == 200 else { throw WeatherError.invalidResponse }
        let raw = try JSONDecoder().decode(OpenMeteoResponse.self, from: data)
        return raw.snapshot()
    }
}

private struct OpenMeteoResponse: Decodable {
    struct Current: Decodable { let temperature_2m: Double?; let relative_humidity_2m: Double?; let weather_code: Int?; let is_day: Int? }
    struct Hourly: Decodable {
        let time: [String]; let temperature_2m: [Double?]?; let dew_point_2m: [Double?]?; let relative_humidity_2m: [Double?]?; let cloud_cover: [Double?]?; let wind_speed_10m: [Double?]?; let wind_gusts_10m: [Double?]?; let precipitation_probability: [Double?]?; let precipitation: [Double?]?; let soil_temperature_6cm: [Double?]?; let soil_moisture_3_to_9cm: [Double?]?; let surface_temperature: [Double?]?; let et0_fao_evapotranspiration: [Double?]?; let shortwave_radiation: [Double?]?
    }
    struct Daily: Decodable { let time: [String]; let temperature_2m_max: [Double?]?; let temperature_2m_min: [Double?]?; let precipitation_sum: [Double?]?; let et0_fao_evapotranspiration: [Double?]?; let wind_gusts_10m_max: [Double?]?; let sunrise: [String]?; let sunset: [String]? }
    let current: Current?
    let hourly: Hourly?
    let daily: Daily?

    func snapshot() -> WeatherSnapshot {
        let iso = ISO8601DateFormatter()
        let local = DateFormatter(); local.locale = Locale(identifier: "en_US_POSIX"); local.dateFormat = "yyyy-MM-dd'T'HH:mm"
        let dayOnly = DateFormatter(); dayOnly.locale = local.locale; dayOnly.dateFormat = "yyyy-MM-dd"
        func at(_ a: [Double?]?, _ i: Int) -> Double? { guard let a, a.indices.contains(i) else { return nil }; return a[i] }
        var hours: [HourlyWeather] = []
        if let h = hourly {
            for i in h.time.indices {
                guard let d = local.date(from: h.time[i]) ?? iso.date(from: h.time[i]) else { continue }
                hours.append(HourlyWeather(time: d, temperatureF: at(h.temperature_2m,i), dewPointF: at(h.dew_point_2m,i), humidity: at(h.relative_humidity_2m,i), cloudCover: at(h.cloud_cover,i), windMPH: at(h.wind_speed_10m,i), gustMPH: at(h.wind_gusts_10m,i), precipitationProbability: at(h.precipitation_probability,i), precipitationIn: at(h.precipitation,i), soilTemperatureF: at(h.soil_temperature_6cm,i), soilMoisture: at(h.soil_moisture_3_to_9cm,i), surfaceTemperatureF: at(h.surface_temperature,i), et0In: at(h.et0_fao_evapotranspiration,i), shortwaveRadiation: at(h.shortwave_radiation,i)))
            }
        }
        var days: [DailyWeather] = []
        if let d = daily {
            for i in d.time.indices {
                guard let date = dayOnly.date(from: d.time[i]) else { continue }
                func strDate(_ a: [String]?) -> Date? { guard let a, a.indices.contains(i) else { return nil }; return local.date(from: a[i]) }
                days.append(DailyWeather(date: date, highF: at(d.temperature_2m_max,i), lowF: at(d.temperature_2m_min,i), precipitationIn: at(d.precipitation_sum,i), et0In: at(d.et0_fao_evapotranspiration,i), windGustMPH: at(d.wind_gusts_10m_max,i), sunrise: strDate(d.sunrise), sunset: strDate(d.sunset)))
            }
        }
        return WeatherSnapshot(currentTemperatureF: current?.temperature_2m, currentHumidity: current?.relative_humidity_2m, weatherCode: current?.weather_code, isDay: current?.is_day != 0, dailyHighF: days.first?.highF, dailyLowF: days.first?.lowF, dailyPrecipitationIn: days.first?.precipitationIn, dailyET0In: days.first?.et0In, hourly: hours, daily: days)
    }
}
