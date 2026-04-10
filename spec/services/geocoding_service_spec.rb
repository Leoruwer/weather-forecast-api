require "rails_helper"

RSpec.describe GeocodingService do
  subject { described_class.call(name) }

  let(:name) { "New York" }

  let(:response_body) do
    {
      results: [
        {
          name: "New York",
          country: "United States",
          latitude: 40.7128,
          longitude: -74.0060
        }
      ]
    }.to_json
  end

  before do
    stub_request(:get, described_class::BASE_URL)
      .with(query: { name: name })
      .to_return(
        status: 200,
        headers: { "Content-Type" => "application/json" },
        body: response_body
      )
  end

  describe ".call" do
    context "when API call is successful" do
      it "returns geocode data" do
        expect(subject).to eq(
          name: "New York",
          country: "United States",
          latitude: 40.7128,
          longitude: -74.0060,
          success: true
        )
      end

      it "calls geocoding API with the correct params" do
        subject

        expect(
          stub_request(:get, described_class::BASE_URL)
            .with(query: { name: name })
        ).to have_been_requested
      end
    end

    context "when location is not found" do
      let(:name) { "Invalid Location" }

      before do
        stub_request(:get, described_class::BASE_URL)
          .with(query: { name: name })
          .to_return(
            status: 200,
            headers: { "Content-Type" => "application/json" },
            body: { results: [] }.to_json
          )
      end

      it "returns an error message" do
        expect(subject).to eq({ success: false, error: "Location not found" })
      end
    end

    context "when API call fails" do
      before do
        stub_request(:get, described_class::BASE_URL)
          .with(query: { name: name })
          .to_return(status: 500)
      end

      it "returns an error message" do
        expect(subject).to eq({ success: false, error: "Failed to fetch geocode data" })
      end
    end
  end
end
