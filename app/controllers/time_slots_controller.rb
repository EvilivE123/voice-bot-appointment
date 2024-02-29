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
  
        if params["allow_recurrance"]
          time_interval = params['recurrance_interval']
          st = start_time
          et = end_time
          eod_time = "24:00"
          while st < eod_time && et < eod_time do
            time_slot = TimeSlot.create!(
              slot_date: slot_date,
              start_time: st,
              end_time: et
            )
            st_hours, st_minutes = st.split(":")
            et_hours, et_minutes = et.split(":")
            
            new_st_hours = et_hours.to_i + time_interval.to_i
            new_et_hours = (et_hours.to_i + time_interval.to_i) + time_interval.to_i
  
            st = "#{new_st_hours}".length == 1 ? "0#{new_st_hours}:#{st_minutes}" : "#{new_st_hours}:#{st_minutes}"
            et = "#{new_et_hours}".length == 1 ? "0#{new_et_hours}:#{et_minutes}" : "#{new_et_hours}:#{et_minutes}"
          end
        else
          time_slot = TimeSlot.create!(
            slot_date: slot_date,
            start_time: start_time,
            end_time: end_time
          )
        end
  
        render_success_response("Time Slot(s) created successfully")
      end
    rescue => exception
      render_error(exception, 422)
    end
  end

  # DELETE - /time_slots/22
  def destroy
    time_slot = TimeSlot.find(params['id'])
    time_slot.destroy
    render_success_response("Time Slot destroyed successfully")
  end

  private

  def validate_payload_structure
    {
      "slot_date" => "Date",
      "start_time" => "Time",
      "end_time" => "Time",
      "allow_recurrance" => "Boolean",
      "recurrance_interval" => "Integer"
    }.each do |key, value|
      raise "#{key} cannot be blank" if params.keys.exclude?(key)

      begin
        if value == "Date"
          params[key].to_date 
        elsif value == "Time"
          hours, min = params[key].split(":")
          raise if hours.length != 2
          raise if hours.to_f >= 24
          raise if min.to_f >= 60
        elsif value == "Boolean"
          raise if [true ,"1","true", false,"0","false"].exclude?(params[key])
        elsif value == "Integer"
          raise unless params[key].is_a? Integer
          if params['allow_recurrance']
            raise if params[key] <= 0
          end
        else
          raise "Something is wrong!!"
        end
      rescue
        raise "#{key} is invalid"
      end
    end
  end
end
