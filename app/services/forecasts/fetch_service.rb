class Forecasts::FetchService
  def self.call(location)
    new(location).call
  end

  def initialize(location)
    @location = location
  end

  def call
    geo = GeocodingService.call(@location)

    return { success: false, error: geo[:error] } unless geo[:success]

    weather = WeatherService.call(
      latitude: geo[:latitude],
      longitude: geo[:longitude]
    )

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
