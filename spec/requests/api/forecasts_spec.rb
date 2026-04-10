require "rails_helper"
require "webmock/rspec"

RSpec.describe "Api::Forecasts", type: :request do
  describe "GET /api/forecasts" do
    before do
      stub_request(:get, GeocodingService::BASE_URL).with(query: geo_params).to_return(geocoding_api_response)
      stub_request(:get, WeatherService::BASE_URL).with(query: weather_params).to_return(weather_api_response)

      allow(Forecasts::FetchService).to receive(:call).and_call_original
    end

    subject { get "/api/forecasts", params: params }

    let(:geocoding_api_response) { {} }
    let(:weather_api_response) { {} }
    let(:params) { {} }
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
        let(:params) { { name: "10001" } }

        it "returns status ok" do
          subject

          expect(response).to have_http_status(:ok)
        end

        it "returns json content type" do
          subject

          expect(response.content_type).to eq("application/json; charset=utf-8")
        end

        it "returns the forecast location data" do
          subject

          body = JSON.parse(response.body)

          expect(body["data"]["location"]).to include(
            "location_name" => "New York, United States",
            "latitude" => 40.7128,
            "longitude" => -74.0060
          )
        end

        it "returns the forecast data" do
          subject

          body = JSON.parse(response.body)

          expect(body["data"]).to include(
            "current_temperature" => 23,
            "high_temperature" => 30,
            "low_temperature" => 15,
            "extended_forecast" => [
              { "date" => "2026-04-10", "high_temperature" => 31, "low_temperature" => 16 },
              { "date" => "2026-04-11", "high_temperature" => 32, "low_temperature" => 17 },
              { "date" => "2026-04-12", "high_temperature" => 33, "low_temperature" => 18 }
            ],
            "from_cache" => false
          )
        end

        it "calls the fetch service" do
          subject

          expect(Forecasts::FetchService).to have_received(:call).with("10001")
        end
      end

      context "when location is city name" do
        let(:params) { { name: "New York" } }

        it "returns status ok" do
          subject

          expect(response).to have_http_status(:ok)
        end

        it "returns json content type" do
          subject

          expect(response.content_type).to eq("application/json; charset=utf-8")
        end

        it "returns the forecast location data" do
          subject

          body = JSON.parse(response.body)

          expect(body["data"]["location"]).to include(
            "location_name" => "New York, United States",
            "latitude" => 40.7128,
            "longitude" => -74.0060
          )
        end

        it "returns the forecast data" do
          subject

          body = JSON.parse(response.body)

          expect(body["data"]).to include(
            "current_temperature" => 23,
            "high_temperature" => 30,
            "low_temperature" => 15,
            "extended_forecast" => [
              { "date" => "2026-04-10", "high_temperature" => 31, "low_temperature" => 16 },
              { "date" => "2026-04-11", "high_temperature" => 32, "low_temperature" => 17 },
              { "date" => "2026-04-12", "high_temperature" => 33, "low_temperature" => 18 }
            ],
            "from_cache" => false
          )
        end

        it "calls the fetch service" do
          subject

          expect(Forecasts::FetchService).to have_received(:call).with("New York")
        end
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

      let(:params) { { name: "Invalid Location" } }

      it "returns status bad request" do
        subject

        expect(response).to have_http_status(:bad_request)
      end

      it "returns error message" do
        subject

        body = JSON.parse(response.body)

        expect(body).to include(
          "error" => "Location not found"
        )
      end
    end

    context "when location parameter is missing" do
      let(:params) { {} }

      it "returns status bad request" do
        subject

        expect(response).to have_http_status(:bad_request)
      end

      it "returns error message" do
        subject

        body = JSON.parse(response.body)

        expect(body).to include(
          "error" => "Location parameter is required"
        )
      end
    end

    context "when service raises exception" do
      before do
        allow(Forecasts::FetchService).to receive(:call).and_raise(StandardError.new("Something went wrong"))
      end

      let(:params) { { name: "10001" } }

      it "returns error message" do
        expect { subject }.to raise_error(StandardError, "Something went wrong")
      end
    end
  end
end
