class WeatherService
  BASE_URL = "https://api.open-meteo.com/v1/forecast".freeze

  def self.call(latitude:, longitude:)
    new(latitude:, longitude:).call
  end

  def initialize(latitude:, longitude:)
    @latitude = latitude
    @longitude = longitude
  end

  def call
    response = Faraday.get(BASE_URL, {
      latitude: @latitude,
      longitude: @longitude,
      daily: "temperature_2m_max,temperature_2m_min",
      current: "temperature_2m",
      timezone: "auto",
      forecast_days: 8
    })

    body = JSON.parse(response.body)

    return { success: false, error: "Location not found" } unless body

    {
      current_temperature: body.dig("current", "temperature_2m"),
      high_temperature: body.dig("daily", "temperature_2m_max", 0),
      low_temperature: body.dig("daily", "temperature_2m_min", 0),
      extended_forecast: build_extended_forecast(body["daily"]),
      success: true
    }
  end

  private

  def build_extended_forecast(daily_data)
    return [] unless daily_data

    daily_data["time"].each_with_index.filter_map do |date, i|
      next if i.zero?

      {
        date: date,
        high_temperature: daily_data["temperature_2m_max"][i],
        low_temperature: daily_data["temperature_2m_min"][i]
      }
    end
  end
end
