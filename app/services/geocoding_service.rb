class GeocodingService
  BASE_URL = "https://geocoding-api.open-meteo.com/v1/search".freeze

  def self.call(location)
    new(location).call
  end

  def initialize(location)
    @location = location
  end

  def call
    response = Faraday.get(BASE_URL, {
      name: @location
    })

    body = JSON.parse(response.body)

    result = body["results"].first
    return { success: false, error: "Location not found" } unless result

    {
      name: result["name"],
      country: result["country"],
      latitude: result["latitude"],
      longitude: result["longitude"],
      success: true
    }
  end
end
