require "rails_helper"

RSpec.describe Forecasts::FetchService do
  describe ".call" do
    subject { described_class.call(params) }

    before do
      allow(GeocodingService).to receive(:call).and_return(geocoding_response)
      allow(WeatherService).to receive(:call).and_return(weather_response)

      allow(Rails.cache).to receive(:fetch).and_yield
      allow(Rails.cache).to receive(:read).and_return(nil)
      allow(Rails.cache).to receive(:write)
    end

    let(:geocoding_response) do
      {
        name: "New York",
        country: "United States",
        latitude: 40.7128,
        longitude: -74.0060,
        success: true
      }
    end

    let(:weather_response) do
      {
        current_temperature: 23,
        high_temperature: 30,
        low_temperature: 15,
        extended_forecast: [
          { date: "2026-04-10", high_temperature: 31, low_temperature: 16 },
          { date: "2026-04-11", high_temperature: 32, low_temperature: 17 },
          { date: "2026-04-12", high_temperature: 33, low_temperature: 18 }
        ],
        success: true
      }
    end

    let(:forecast_cache_key) do
      CacheHelper.forecast_cache_key(
        geocoding_response[:latitude],
        geocoding_response[:longitude]
      )
    end

    let(:cached_data) do
      {
        location_query: "10001",
        location_name: "New York, United States",
        latitude: 40.7128,
        longitude: -74.0060,
        current_temperature: 23,
        high_temperature: 30,
        low_temperature: 15,
        extended_forecast: [
          { date: "2026-04-10", high_temperature: 31, low_temperature: 16 },
          { date: "2026-04-11", high_temperature: 32, low_temperature: 17 },
          { date: "2026-04-12", high_temperature: 33, low_temperature: 18 }
        ],
        success: true
      }
    end

    context "when geocoding and weather services succeed" do
      let(:params) { "10001" }

      it "returns combined forecast data" do
        expect(subject).to eq(
          location_query: "10001",
          location_name: "New York, United States",
          latitude: 40.7128,
          longitude: -74.0060,
          current_temperature: 23,
          high_temperature: 30,
          low_temperature: 15,
          extended_forecast: [
            { date: "2026-04-10", high_temperature: 31, low_temperature: 16 },
            { date: "2026-04-11", high_temperature: 32, low_temperature: 17 },
            { date: "2026-04-12", high_temperature: 33, low_temperature: 18 }
          ],
          from_cache: false,
          success: true
        )
      end

      it "calls weather service with geocoding results" do
        subject

        expect(WeatherService).to have_received(:call).with(
          latitude: 40.7128,
          longitude: -74.0060
        )
      end

      it "writes combined data to cache" do
        subject

        expect(Rails.cache).to have_received(:write).with(
          forecast_cache_key,
          {
            location_query: "10001",
            location_name: "New York, United States",
            latitude: 40.7128,
            longitude: -74.0060,
            current_temperature: 23,
            high_temperature: 30,
            low_temperature: 15,
            extended_forecast: [
              { date: "2026-04-10", high_temperature: 31, low_temperature: 16 },
              { date: "2026-04-11", high_temperature: 32, low_temperature: 17 },
              { date: "2026-04-12", high_temperature: 33, low_temperature: 18 }
            ],
            success: true
          },
          expires_in: described_class::CACHE_EXPIRATION
        )
      end
    end

    context "when forecast is cached" do
      let(:params) { "10001" }

      before do
        allow(Rails.cache).to receive(:read).with(forecast_cache_key).and_return(cached_data)
      end

      it "returns cached forecast" do
        expect(subject).to eq(cached_data.merge(from_cache: true))
      end

      it "does not call weather service" do
        subject

        expect(WeatherService).not_to have_received(:call)
      end
    end

    context "when geocoding fails" do
      let(:params) { "Invalid Location" }

      before do
        allow(GeocodingService).to receive(:call).with(params).and_return(
          { success: false, error: "Location not found" }
        )
      end

      it "returns an error response" do
        expect(subject).to eq(
          success: false,
          error: "Location not found"
        )
      end

      it "does not call weather service" do
        subject

        expect(WeatherService).not_to have_received(:call)
      end

      it "does not write to cache" do
        subject

        expect(Rails.cache).not_to have_received(:write)
      end
    end

    context "when weather service fails" do
      let(:params) { "10001" }

      before do
        allow(WeatherService).to receive(:call).and_return(
          { success: false, error: "Failed to fetch weather data" }
        )
      end

      it "returns an error response" do
        expect(subject).to eq(
          success: false,
          error: "Failed to fetch weather data"
        )
      end

      it "does not write to cache" do
        subject

        expect(Rails.cache).not_to have_received(:write)
      end
    end
  end
end
