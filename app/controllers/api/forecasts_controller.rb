class Api::ForecastsController < ApplicationController
  def index
    name = params[:name]

    return render json: { error: "Name parameter is required" }, status: :bad_request if name.blank?

    result = Forecasts::FetchService.call(name)

    return render json: ForecastSerializer.new(result).as_json, status: :ok if result[:success]
    render json: { error: result[:error] }, status: :bad_request
  end
end
