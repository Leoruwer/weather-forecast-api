require "rails_helper"

RSpec.describe WeatherService do
  subject { described_class.call(latitude: latitude, longitude: longitude) }

  let(:latitude) { 40.7128 }
  let(:longitude) { -74.0060 }

  let(:response_body) do
    {
      current: {
        temperature_2m: 23
      },
      daily: {
        time: [ "2026-04-09", "2026-04-10", "2026-04-11", "2026-04-12" ],
        temperature_2m_max: [ 30, 31, 32, 33 ],
        temperature_2m_min: [ 15, 16, 17, 18 ]
      }
    }.to_json
  end

  before do
    stub_request(:get, described_class::BASE_URL)
      .with(
        query: {
          latitude: latitude.to_s,
          longitude: longitude.to_s,
          daily: "temperature_2m_max,temperature_2m_min",
          current: "temperature_2m",
          timezone: "auto",
          forecast_days: "8"
        }
      )
      .to_return(
        status: 200,
        headers: { "Content-Type" => "application/json" },
        body: response_body
      )
  end

  describe ".call" do
    context "when API call is successful" do
      it "returns weather data" do
        expect(subject).to eq(
          current_temperature: 23,
          high_temperature: 30,
          low_temperature: 15,
          extended_forecast: [
            { date: "2026-04-10", high_temperature: 31, low_temperature: 16 },
            { date: "2026-04-11", high_temperature: 32, low_temperature: 17 },
            { date: "2026-04-12", high_temperature: 33, low_temperature: 18 }
          ],
          success: true
        )
      end

      it "calls weather API with the correct params" do
        subject

        expect(
          stub_request(:get, described_class::BASE_URL)
            .with(
              query: {
                latitude: latitude.to_s,
                longitude: longitude.to_s,
                daily: "temperature_2m_max,temperature_2m_min",
                current: "temperature_2m",
                timezone: "auto",
                forecast_days: "8"
              }
            )
        ).to have_been_requested
      end
    end

    context "when API call fails" do
      before do
        stub_request(:get, described_class::BASE_URL)
          .with(
            query: {
              latitude: latitude.to_s,
              longitude: longitude.to_s,
              daily: "temperature_2m_max,temperature_2m_min",
              current: "temperature_2m",
              timezone: "auto",
              forecast_days: "8"
            }
          )
          .to_return(status: 500)
      end

      it "returns an error message" do
        expect(subject).to eq({ success: false, error: "Failed to fetch weather data" })
      end
    end
  end
end
