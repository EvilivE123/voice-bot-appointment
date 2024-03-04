class BookSlotsController < ApplicationController
  respond_to :html, only: :index

  def index
    if params['message_content'].present?
      message = BookSlotAiService.new(message_content: params['message_content']).call_actions
      respond_to do |format|
        format.html # Handle the initial HTML request
        format.json do
          render json: { message_content: message } 
        end
      end
    else
      ApplicationRecord.reset_global_variable
    end
  end

end
