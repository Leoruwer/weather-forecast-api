class Api::ForecastsController < ApplicationController
  def show
    location = params[:location]

    return render json: { error: "Location parameter is required" }, status: :bad_request if location.blank?

    result = ForecastService.fetch_forecast(location)

    render json: ForecastSerializer.new(result).as_json, status: :ok if result.success?
    render json: { error: result.error_message }, status: :bad_request

  rescue StandardError => e
    render json: { error: "An unexpected error occurred: #{e.message}" }, status: :unprocessable_entity
  end
end
