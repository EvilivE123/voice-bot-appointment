module Utils::Formatting
  
  # Converts to 14th March 24
  def format_date(date=Date.current)
    date.to_date.strftime("#{date.day.ordinalize} %B %y")
  end

  # Converts to 3pm
  def format_time(time=Time.now)
    time.to_time.strftime("%l%P").gsub(" ", "")
  end

  # Converts to 932-443-2946
  def format_mobile_number(number='9999999999')
    number[0..-8] + '-' + number[-7..-5] + '-' + number[-4..-1]
  end

  # Converts to 14th March 24 at 3pm
  def format_date_and_time(date=Date.current, time=Time.now)
    "#{format_date(date)} at #{format_time(time)}"
  end
end