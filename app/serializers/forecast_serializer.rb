class ForecastSerializer
  def initialize(forecast_data)
    @forecast_data = forecast_data
  end

  def as_json(*)
    {
      data: {
        location: {
          city: @forecast_data.city,
          state: @forecast_data.state,
          country: @forecast_data.country,
          latitude: @forecast_data.latitude,
          longitude: @forecast_data.longitude
        },
        current_temperature: @forecast_data.current_temperature,
        high_temperature: @forecast_data.high_temperature,
        low_temperature: @forecast_data.low_temperature,
        extended_forecast: serialized_extended_forecast,
        from_cache: @forecast_data.from_cache
      }
    }
  end

  private

  def serialized_extended_forecast
    @forecast_data.extended_forecast.map do |forecast|
      {
        date: forecast.date,
        high_temperature: forecast.high_temperature,
        low_temperature: forecast.low_temperature,
        description: forecast.description
      }
    end
  end
end
