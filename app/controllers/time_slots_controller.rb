class TimeSlotsController < ApplicationController

  before_action :validate_payload_structure, only: :create

  # GET - time_slots?slot_date=01-03-2024&page=2
  def index
    set_pagination_params(params)
    slot_date = params['slot_date'].present? ? params['slot_date'].to_date : Date.current.to_date
    time_slots = TimeSlot.where("slot_date = ?", slot_date)
    time_slots = time_slots.page(@current_page).per(@per_page)
    render_collection(time_slots, TimeSlotsSerializer)
  end

  # GET - time_slots/22
  def show
    time_slot = TimeSlot.find(params['id'])
    render_resource(time_slot, TimeSlotsSerializer)
  end

  # POST - /time_slots
  def create
    begin
      ActiveRecord::Base.transaction do
        slot_date = params['slot_date'].to_date
        start_time = params['start_time']
        end_time = params['end_time']
        time_slot = TimeSlot.new(
          slot_date: slot_date
        )
        time_slot.start_time = DateTime.parse("#{slot_date} #{start_time}")
        time_slot.end_time = DateTime.parse("#{slot_date} #{end_time}")
        time_slot.save!
        render_success_response("Time Slot(s) created successfully")
      end
    rescue => exception
      render_error(exception, 422)
    end
  end

  # DELETE - /time_slots/22
  def destroy
    time_slot = TimeSlot.find(params['id'])
    if time_slot.open?
      time_slot.destroy
      render_success_response("Time Slot destroyed successfully")
    else
      render_error("Booked slot cannot be destroyed", 422)
    end
  end

  private

  def validate_payload_structure
    {
      "slot_date" => "Date",
      "start_time" => "Time",
      "end_time" => "Time"
    }.each do |key, value|
      raise "#{key} cannot be blank" if params.keys.exclude?(key)

      begin
        if value == "Date"
          params[key].to_date 
        elsif value == "Time"
          hours = params[key][/\d+/]
          am_or_pm = params[key][/\D+/]
          raise if (hours.length > 2 || hours.length < 1) 
          raise if hours.to_f >= 24
          raise if am_or_pm.blank?
          raise if (params[key].length > 4 || params[key].length < 3)
        else
          raise "Something is wrong!!"
        end
      rescue
        raise "#{key} is invalid"
      end
    end
  end
end
