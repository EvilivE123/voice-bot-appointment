class BookSlotAiService
  include Utils::Formatting

  REASON = %w[cold cough headache fever others]

  def initialize(message_content: )
    @message_content = message_content
  end

  def call_actions
    set_or_get_appointment_type if $appointment_type.blank?

    if $appointment_type == "schedule"
      message = schedule_appointment_process
    elsif $appointment_type == "reschedule"
      message = reschedule_appointment_process
    elsif $appointment_type == "cancel"
      message = cancel_appointment_process
    else
      message = "I apologize, but I haven't understood."
    end
  end

  def set_or_get_appointment_type
    ["schedule:schedule", "reschedule:reschedule", "cancel:cancel", "book:schedule"].each do |colon_data|
      key, value = colon_data.split(':')
      if @message_content.downcase.include?(key)
        $appointment_type = value
      end
    end
  end

  def schedule_appointment_process
    if $slot_date.blank?
      message = assign_date 
      return message if message.present?
    end

    if $start_time.blank?
      message = assign_time
      return message if message.present?
    end

    if $person_name.blank?
      message = assign_name
      return message if message.present?
    end

    if $person_number.blank?
      message = assign_number
      return message if message.present?
    end

    if $reason.blank?
      message = assign_reason
      return message if message.present?
    end

    schedule_appointment
  end

  def assign_date
    date = (Date.parse(@message_content) rescue [])
    date_slots = TimeSlot.where("is_booked = false AND slot_date >= ? AND start_time > ?", Date.current, Time.now)
    formatted_date_slots = (date_slots.pluck(:slot_date).uniq.collect{|date| format_date(date)} rescue [])
    if date.present?
      is_slot_available = date_slots.where(slot_date: date.to_date).present? 
      if is_slot_available
        $slot_date = date
        return nil
      else
        return "There are no available date slots on #{format_date(date)}. Can you tell me the next available date?"
      end
    elsif formatted_date_slots.present?
      return "I have the following date slots available #{formatted_date_slots.join(', ')}, to schedule an appointment"
    else
      return "We currently have no date slots available."
    end
  end

  def assign_time
    time = (Time.parse(@message_content) rescue [])
    time_slots = TimeSlot.where("is_booked = false AND slot_date = ? AND start_time > ?", $slot_date.to_date, Time.now)
    formatted_time_slots = (time_slots.pluck(:start_time).uniq.collect{|time| format_time(time)} rescue [])
    if time.present?
      is_time_slot_available = (time_slots.where(start_time: DateTime.parse("#{$slot_date} #{format_time(time)}")).present? rescue false)
      if is_time_slot_available
        $start_time = format_time(time)
        return nil
      elsif formatted_time_slots.present?
        return "I have the following time slots available for scheduling an appointment: #{formatted_time_slots.join(',')}"
      else
        return  "There are no available time slots."
      end
    elsif formatted_time_slots.present?
      return "I have time slots at #{formatted_time_slots.join(' and ')}"
    else
      given_slot_date = $slot_date
      $slot_date = nil
      return "All time slots are booked for #{format_date(given_slot_date)}"
    end
  end

  def assign_name
    name_regex = /([A-Z][a-z]+)\s?([A-Z][a-z]+)?\s?([A-Z][a-z]+)?/
    name_match = @message_content.match(name_regex)
    if name_match
      first_name = name_match[1]
      middle_initial = name_match[2] ? name_match[2].strip : ''
      last_name = name_match[3] ? name_match[3].strip : ''
      
      full_name = "#{first_name} #{middle_initial} #{last_name}"
      full_name = full_name.strip
      $person_name = full_name
      return nil
    else
      return "May I please have your name and phone number?"
    end
  end

  def assign_number
    fetch_number = @message_content.gsub(/\D/, "")
    if fetch_number
      number_regex = /\d{10}/
      number_match = fetch_number.match(number_regex)
      if number_match
        $person_number = fetch_number
        return nil
      else
        return "We encountered an issue while retrieving your mobile number. Could you please repeat it?"
      end
    else
      return "Please enter a valid phone number."
    end
  end

  def assign_reason
    REASON.each do |reason|
      if @message_content.downcase.include?(reason)
        $reason = reason
        return nil
      end
    end
    return "kindly select the reasons from the following: #{REASON.join(', ')}"
  end

  def schedule_appointment
    if @message_content.downcase.include?("confirm slot")
      time_slot = TimeSlot.where("is_booked = false AND slot_date = ? AND start_time = ?", $slot_date.to_date, DateTime.parse("#{$slot_date.to_date} #{$start_time}")).first
      if time_slot.present?
        time_slot.update!(is_booked: true, person_name: $person_name, person_number: $person_number, reason: $reason, status: "booked")
        ApplicationRecord.reset_global_variable
        return "Great! I have you scheduled for that time. To cancel or reschedule, please call us again. We look forward to seeing you soon!"
      else
        ApplicationRecord.reset_global_variable
        return "Unfortunately, it appears someone else has booked this slot just before you. Please try selecting a different time slot."
      end
    elsif @message_content.downcase.include?("cancel booking slot")
      ApplicationRecord.reset_global_variable
      return "Your appointment details have been cleared."
    else
      return "You've selected a slot for '#{format_date($slot_date)}' at '#{format_time($start_time)}' with the name '#{$person_name}', mobile number '#{format_mobile_number($person_number)}' and the reason for '#{$reason}'. To confirm, say 'confirm slot'. To reset the data, say 'cancel booking slot'"
    end
  end

  def reschedule_appointment_process
    if $person_name.blank?
      message = assign_name
      return message if message.present?
    end

    if $person_number.blank?
      message = assign_number
      return message if message.present?
    end

    if $scheduled_slot.blank?
      message = select_scheduled_slot('rescheduling')
      return message if message.present?
    end

    if $slot_date.blank?
      message = assign_date 
      return message if message.present?
    end

    if $start_time.blank?
      message = assign_time
      return message if message.present?
    end

    if $reason.blank?
      message = assign_reason
      return message if message.present?
    end

    reschedule_appointment
  end

  def reschedule_appointment
    if @message_content.downcase.include?("confirm slot")
      time_slot = TimeSlot.where("is_booked = false AND slot_date = ? AND start_time = ?", $slot_date.to_date, DateTime.parse("#{$slot_date.to_date} #{$start_time}")).first
      if time_slot.present?
        time_slot.update!(is_booked: true, person_name: $person_name, person_number: $person_number, reason: $reason, status: "booked")
        $scheduled_slot.update!(is_booked: false, person_name: nil, person_number: nil, reason: nil, status: "open")
        ApplicationRecord.reset_global_variable
        return "Great! Your appointment has been rescheduled for that time. To cancel or reschedule in the future, please call us again. We look forward to seeing you soon!"
      else
        ApplicationRecord.reset_global_variable
        return "Unfortunately, it appears someone else has booked this slot just before you. Please select a new slot for your appointment."
      end
    elsif @message_content.downcase.include?("cancel booking slot")
      ApplicationRecord.reset_global_variable
      return "Your previous appointment selection has been cleared. Please choose a new slot to reschedule."
    else
      return "Your appointment has been rescheduled. The original slot was on #{format_date_and_time($scheduled_slot.slot_date, $scheduled_slot.start_time)}. The new slot is confirmed for '#{format_date($slot_date)}' at '#{format_time($start_time)}' with the name '#{$person_name}', mobile number '#{format_mobile_number($person_number)}' and the reason for '#{$reason}'. To confirm this rescheduling, say 'confirm slot.' To reset the information and reschedule again, say 'cancel booking slot.'"
    end
  end

  def select_scheduled_slot(appointment_type)
    scheduled_date = (Date.parse(@message_content) rescue [])
    scheduled_time = (Time.parse(@message_content) rescue [])
    date_slots = TimeSlot.where(person_name: $person_name, person_number: $person_number)
    if scheduled_date.present? && scheduled_time.present?
      slot = date_slots.where("slot_date = ? AND start_time = ?", scheduled_date.to_date, DateTime.parse("#{scheduled_date.to_date} #{format_time(scheduled_time)}")).first
      is_valid_slot = slot.present?
      if is_valid_slot
        $scheduled_slot = slot
        @message_content = nil
        return nil
      else
        return "Unfortunately, a slot matching the provided information is unavailable. Please provide the desired date and time for rescheduling your appointment."
      end
    elsif date_slots.present? 
      formatted_scheduled_data = (date_slots.select(:slot_date, :start_time).uniq.collect{|rec| format_date_and_time(rec.slot_date, rec.start_time) } rescue [])
      return "Please select one of the following scheduled slots for #{appointment_type} '#{formatted_scheduled_data.join(', ')}'"
    else
      ApplicationRecord.reset_global_variable
      return "Unfortunately, we couldn't find any appointments booked under your name and phone number. If you believe you have an appointment, please contact our admin team for assistance. We are clearing any temporary data stored for scheduling."
    end
  end

  def cancel_appointment_process
    if $person_name.blank?
      message = assign_name
      return message if message.present?
    end

    if $person_number.blank?
      message = assign_number
      return message if message.present?
    end

    if $scheduled_slot.blank?
      message = select_scheduled_slot('cancellation')
      return message if message.present?
    end

    cancel_appointment
  end

  def cancel_appointment
    if @message_content.downcase.include?("cancel slot")
      $scheduled_slot.update!(is_booked: false, person_name: nil, person_number: nil, reason: nil, status: "open")
      ApplicationRecord.reset_global_variable
      return "We regret to inform you that your appointment has been cancelled. To schedule or reschedule, please call us again. We look forward to seeing you soon."
    else
      return "You have selected a slot for '#{format_date($scheduled_slot.slot_date)}' at '#{format_time($scheduled_slot.start_time)}' with the name '#{$scheduled_slot.person_name}', mobile number '#{format_mobile_number($scheduled_slot.person_number)}'. Would you like to cancel it? To confirm, say 'cancel slot'."
    end
  end
end