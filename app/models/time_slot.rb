class TimeSlot < ApplicationRecord

  enum status: { "open": "open", "booked": "booked" }, _prefix: true, _default: "open"

  validate :validate_person_number, if: Proc.new { self.person_number.present? }
  validate :validate_slot_overlap, if: Proc.new { self.new_record? }
  validate :validate_slot_date

  def validate_person_number
    # Check and raise error if the phone number is a string and not empty
    errors.add(:person_number, "phone number must be present")  unless person_number.is_a?(String) && !person_number.empty?

    # Check and raise error if the digits are 10 characters long
    errors.add(:person_number, "phone number is invalid") if person_number.length != 10
  end

  def validate_slot_overlap
    time_slots = TimeSlot.where(slot_date: self.slot_date)
    
    # Check and raise error if start time is overlapping with other time slots
    overlap_start_time_slots = time_slots.where(["? Between start_time AND end_time", self.start_time])
    errors.add(:start_time, "is overlapping")  if overlap_start_time_slots.present?

    # Check and raise error if end time is overlapping  with other time slots
    overlap_end_time_slot = time_slots.where(["? Between start_time AND end_time", self.end_time])
    errors.add(:end_time, "is overlapping")  if overlap_end_time_slot.present?
  end

  def validate_slot_date
    # Check and raise if slot date is from past or current
    errors.add(:slot_date, "shoud have future date") if self.slot_date.to_date <= Date.current
  end

end
