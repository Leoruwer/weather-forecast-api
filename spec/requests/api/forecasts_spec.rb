require "rails_helper"
require "webmock/rspec"

RSpec.describe "Api::Forecasts", type: :request do
  describe "GET /api/forecasts" do
    before do
      stub_request(:get, GeocodingService::BASE_URL).with(query: geo_params).to_return(geocoding_api_response)
      stub_request(:get, WeatherService::BASE_URL).with(query: weather_params).to_return(weather_api_response)

      allow(Forecasts::FetchService).to receive(:call).and_call_original
    end

    subject { get "/api/forecasts", params: geo_params }

    let(:geocoding_api_response) { {} }
    let(:weather_api_response) { {} }
    let(:geo_params) { {} }
    let(:weather_params) { {} }

    context "with valid location" do
      let(:geocoding_api_response) do
        {
          status: 200,
          headers: { "Content-Type" => "application/json" },
          body: {
              results: [
                {
                  name: "New York",
                  country: "United States",
                  latitude: 40.7128,
                  longitude: -74.0060
                }
              ]
            }.to_json
          }
      end

      let(:weather_api_response) do
        {
          status: 200,
          headers: { "Content-Type" => "application/json" },
          body: {
            current: {
              temperature_2m: 23
            },
            daily: {
              time: [ "2026-04-09", "2026-04-10", "2026-04-11", "2026-04-12" ],
              temperature_2m_max: [ 30, 31, 32, 33 ],
              temperature_2m_min: [ 15, 16, 17, 18 ]
            }
          }.to_json
        }
      end

      let(:weather_params) do
        {
          latitude: 40.7128,
          longitude: -74.0060,
          daily: "temperature_2m_max,temperature_2m_min",
          current: "temperature_2m",
          timezone: "auto",
          forecast_days: 8
        }
      end

      context "when location is zip code" do
        let(:geo_params) { { name: "10001" } }

        it_behaves_like "a successful forecast response", "10001"
      end

      context "when location is city name" do
        let(:geo_params) { { name: "New York" } }

        it_behaves_like "a successful forecast response", "New York"
      end
    end

    context "with invalid location" do
      let(:geocoding_api_response) do
        {
          status: 400,
          headers: { "Content-Type" => "application/json" },
          body: {
            error: true,
            reason: "Invalid location"
          }.to_json
        }
      end

      let(:geo_params) { { name: "Invalid Location" } }

      it "returns status bad request" do
        subject

        expect(response).to have_http_status(:bad_request)
      end

      it "returns error message" do
        subject

        body = JSON.parse(response.body)

        expect(body).to include(
          "error" => "Failed to fetch geocode data"
        )
      end
    end

    context "when name parameter is missing" do
      let(:geo_params) { {} }

      it "returns status bad request" do
        subject

        expect(response).to have_http_status(:bad_request)
      end

      it "returns error message" do
        subject

        body = JSON.parse(response.body)

        expect(body).to include(
          "error" => "Name parameter is required"
        )
      end
    end

    context "when service raises exception" do
      before do
        allow(Forecasts::FetchService).to receive(:call).and_raise(StandardError.new("Something went wrong"))
      end

      let(:geo_params) { { name: "10001" } }

      it "returns error message" do
        expect { subject }.to raise_error(StandardError, "Something went wrong")
      end
    end
  end
end
