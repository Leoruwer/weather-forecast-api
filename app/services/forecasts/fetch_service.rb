class Forecasts::FetchService
  CACHE_EXPIRATION = 30.minutes

  def self.call(location)
    new(location).call
  end

  def initialize(location)
    @location = location
  end

  def call
    geo = fetch_geocoding
    return error_response(geo[:error]) unless geo[:success]

    cached_forecast = fetch_cached_forecast(geo)
    return cached_forecast if cached_forecast

    weather = fetch_weather(geo)
    return error_response(weather[:error]) unless weather[:success]

    result = {
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

    Rails.cache.write(
      forecast_cache_key_from_coordinates(geo[:latitude], geo[:longitude]),
      result.except(:from_cache),
      expires_in: CACHE_EXPIRATION
    )

    result
  end

  private

  def fetch_geocoding
    Rails.cache.fetch(geocode_cache_key_from_location(@location), expires_in: CACHE_EXPIRATION) do
      GeocodingService.call(@location)
    end
  end

  def fetch_weather(geo)
    WeatherService.call(
      latitude: geo[:latitude],
      longitude: geo[:longitude]
    )
  end

  def forecast_cache_key_from_coordinates(latitude, longitude)
    lat = format("%.4f", latitude)
    lon = format("%.4f", longitude)

    "forecast:#{lat}:#{lon}"
  end

  def fetch_cached_forecast(geo)
    cached_data = Rails.cache.read(
      forecast_cache_key_from_coordinates(geo[:latitude], geo[:longitude])
    )

    cached_data&.merge(from_cache: true)
  end

  def geocode_cache_key_from_location(location)
    normalized_location = location.to_s.strip.downcase
    "geocode:#{normalized_location}"
  end

  def error_response(message)
    { success: false, error: message }
  end
end
