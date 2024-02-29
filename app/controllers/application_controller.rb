class ApplicationController < ActionController::Base
  require 'csv'
  protect_from_forgery with: :null_session
  respond_to :json
  rescue_from Exception, with: :handle_exception  
  include Rails.application.routes.url_helpers

  def render_unprocessable_entity(ex)
    render json: {error: ex.message}, status: 500
  end

  def render_success_response(message = '', status = 200)
    render json: { success: true, message: message}, status: status
  end

  def render_error message, status
    render json: { error: message }, status: status
  end

  def render_collection resources, serializer
    render json: resources, each_serializer: serializer,  meta: pagination_meta(resources), adapter: :json
  end

  def set_pagination_params(params)
    @current_page = (params[:page].present? ? params[:page] : 1)
    @per_page = (params[:per_page].present? ? params[:per_page] : 10)
  end

  def render_resource resource, serializer
    render json: resource, serializer: serializer
  end

  def pagination_meta(object)
    {
      current_page: (object.current_page rescue 0),
      next_page: (object.next_page.to_i rescue 0),
      prev_page: (object.prev_page.to_i rescue 0),
      total_pages: (object.total_pages rescue 0),
      total_count: (object.total_count rescue 0)
    }
  end

  private

  def handle_exception(exception)
    if exception.class ==  NoMethodError
      render_unprocessable_entity(exception)
    elsif exception.class == ActiveRecord::RecordNotUnique
      render json: { error: "Record already created" }, status: :unprocessable_entity
    elsif exception.class == ActionController::RoutingError
      render json: { error: 'Route not found' }, status: :not_found
    elsif exception.class == ActiveRecord::RecordNotFound
      render json: { error: "Not Found" }, status: 404
    elsif exception.class == ActiveRecord::RecordInvalid
      render json: { error: exception.message }, status: 422
    else
      Rails.logger.error(exception.message)
      render json: { error: exception.message }, status: 500
    end
  end

end