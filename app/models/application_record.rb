class ApplicationRecord < ActiveRecord::Base
  primary_abstract_class
  
  def self.reset_global_variable
    $appointment_type = nil
    $slot_date = nil
    $start_time = nil 
    $person_name = nil 
    $person_number = nil 
    $reason = nil
    $scheduled_slot = nil
  end
end
