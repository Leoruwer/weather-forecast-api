class Api::ForecastsController < ApplicationController
  def index
    location = params[:name]

    return render json: { error: "Location parameter is required" }, status: :bad_request if location.blank?

    result = Forecasts::FetchService.call(location)

    return render json: ForecastSerializer.new(result).as_json, status: :ok if result[:success]
    render json: { error: result[:error] }, status: :bad_request
  end
end
