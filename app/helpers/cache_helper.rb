module CacheHelper
  def self.geocode_cache_key(location)
    normalized_location = location.to_s.strip.downcase
    "geocode:#{normalized_location}"
  end

  def self.forecast_cache_key(latitude, longitude)
    lat = format("%.4f", latitude)
    lon = format("%.4f", longitude)

    "forecast:#{lat}:#{lon}"
  end
end
