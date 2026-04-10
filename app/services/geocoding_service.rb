class GeocodingService
  BASE_URL = "https://geocoding-api.open-meteo.com/v1/search".freeze

  def self.call(location)
    new(location).call
  end

  def initialize(location)
    @location = location
  end

  def call
    response = Faraday.get(BASE_URL, request_params)

    return { success: false, error: "Failed to fetch geocode data" } unless response.success?

    body = JSON.parse(response.body)
    result = body["results"]&.first

    return { success: false, error: "Location not found" } if result.nil?

    {
      name: result["name"],
      country: result["country"],
      latitude: result["latitude"],
      longitude: result["longitude"],
      success: true
    }
  end

  private

  def request_params
    {
      name: @location
    }
  end
end
