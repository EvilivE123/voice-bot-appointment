class TimeSlotsSerializer < ActiveModel::Serializer
  attributes :id, :slot_date, :start_time, :end_time, :is_booked, :person_name, :person_number

  def slot_date
    object.slot_date.to_date.strftime("%d-%m-%Y")
  end

  def start_time
    object.start_time.to_time.strftime("%I:%M %p")
  end

  def end_time
    object.end_time.to_time.strftime("%I:%M %p")
  end
end
