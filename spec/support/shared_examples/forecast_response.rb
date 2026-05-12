RSpec.shared_examples "a successful forecast response" do |location_name|
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

    expect(Forecasts::FetchService).to have_received(:call).with(location_name)
  end
end
