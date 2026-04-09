class Forecasts::FetchService
  def self.call(location)
    new(location).call
  end

  def initialize(location)
    @location = location
  end

  def call
    geo = GeocodingService.call(@location)
    weather = WeatherService.call(
      latitude: geo[:latitude],
      longitude: geo[:longitude]
    )

    return { success: false, error: "Location not found" } unless geo[:success] && weather[:success]

    {
      location_query: @location,
      location_name: [ geo[:name], geo[:country] ].compact.join(", "),
      latitude: geo[:latitude],
      longitude: geo[:longitude],
      current_temperature: weather[:current_temperature],
      high_temperature: weather[:high_temperature],
      low_temperature: weather[:low_temperature],
      extended_forecast: weather[:extended_forecast],
      from_cache: false,
      success: true
    }
  end
end
