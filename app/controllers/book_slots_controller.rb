class BookSlotsController < ApplicationController
  respond_to :html, only: :index

  def index
    if params['script'].present?
      respond_to do |format|
        format.html # Handle the initial HTML request
        format.json do
          render json: { message: "Hello from the server!" }
        end
      end
    end
  end

  def book_slot

  end

  def reschedule

  end

end
