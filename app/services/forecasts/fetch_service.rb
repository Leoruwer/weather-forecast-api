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
    return error_response(geo[:data][:error]) unless geo[:data][:success]

    weather = fetch_weather(geo[:data])
    return error_response(weather[:data][:error]) unless weather[:data][:success]

    build_response(geo[:data], weather[:data], geo[:from_cache] || weather[:from_cache])
  end

  private

  def build_response(geo, weather, from_cache)
    {
      location_query: @location,
      location_name: [ geo[:name], geo[:country] ].compact.join(", "),
      latitude: geo[:latitude],
      longitude: geo[:longitude],
      current_temperature: weather[:current_temperature],
      high_temperature: weather[:high_temperature],
      low_temperature: weather[:low_temperature],
      extended_forecast: weather[:extended_forecast],
      from_cache: from_cache,
      success: true
    }
  end

  def fetch_geocoding
    cache_key = CacheHelper.geocode_cache_key(@location)

    cached_response = Rails.cache.read(cache_key)
    return { data: cached_response, from_cache: true } if cached_response

    result = GeocodingService.call(@location)

    if result[:success]
      Rails.cache.write(cache_key, result, expires_in: CACHE_EXPIRATION)
    end

    { data: result, from_cache: false }
  end

  def fetch_weather(geo)
    cache_key = CacheHelper.weather_cache_key(geo[:latitude], geo[:longitude])

    cached_response = Rails.cache.read(cache_key)
    return { data: cached_response, from_cache: true } if cached_response

    result = WeatherService.call(latitude: geo[:latitude], longitude: geo[:longitude])

    if result[:success]
      Rails.cache.write(cache_key, result, expires_in: CACHE_EXPIRATION)
    end

    { data: result, from_cache: false }
  end

  def error_response(message)
    { success: false, error: message }
  end
end
