require "csv"
require "google/apis/civicinfo_v2"
require "erb"
require "date"

def clean_zipcode(zipcode)
  zipcode.to_s.rjust(5, "0")[0..4]
end

def clean_homephone(phone)
  phone_num = phone.gsub(/\D+/, "").to_s unless phone.nil?
  if phone_num.length == 10
    phone_num
  elsif phone_num.length == 11 && phone_num[0].to_i == 1
    phone_num[1..10]
  else
    ''
  end 
end

def format_homephone(cleaned_number)
  cleaned_number != '' ? cleaned_number[0..2] + "-" + cleaned_number[3..5] + "-" + cleaned_number[6..9] : 'N/A'
end 

def get_hour(reg_time)
  datetime = DateTime.strptime(reg_time, '%m/%d/%y %H:%M')
  datetime.hour
end

def get_day_of_week(reg_time)
  formatted_date = DateTime.strptime(reg_time, '%m/%d/%y %H:%M').to_s
  Date.parse(formatted_date).strftime('%A')
end

def sort_by_frequency(log)
  freq_track = log.inject(Hash.new(0)) { |hash, x| hash[x] += 1; hash }.sort_by { |a, b| -b }
  max = freq_track.first[1]
  freq_track.select { |pair| pair[1] == max }
end

def legislators_by_zipcode(zipcode)
  civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
  civic_info.key = 'AIzaSyClRzDqDh5MsXwnCWi0kOiiBivP6JsSyBw'
  begin
    legislators = civic_info.representative_info_by_address(
      address: zipcode,
      levels: 'country',
      roles: ['legislatorUpperbody', 'legislatorLowerBody']
    )
    legislators = legislators.officials
    legislator_names = legislators.map(&:name)
    legislator_string = legislator_names.join(", ")
  rescue
    "You can find your representatives by visiting www.commoncause.org/take-action/find-elected-officials"
  end
end

def save_thank_you_letter(id, form_letter)
  Dir.mkdir("output") unless Dir.exists?("output")

  filename = "output/thanks_#{id}.html"

  File.open(filename, 'w') do |file|
    file.puts form_letter
  end
end

puts "---*---"
puts "EventManager initialized!"
puts "---*---"
puts ""

contents = CSV.open "event_attendees.csv", headers: true, header_converters: :symbol

template_letter = File.read "form_letter.html.erb"
erb_template = ERB.new template_letter

time_log = []
wday_log = []
contents.each do |row|
  # id = row[0]
  # name = row[:first_name]
  time_log << get_hour(row[:regdate])
  wday_log << get_day_of_week(row[:regdate])
  # phone = format_homephone(clean_homephone(row[:homephone]))
  # zipcode = clean_zipcode(row[:zipcode])
  # legislators = legislators_by_zipcode(zipcode)
  # form_letter = erb_template.result(binding)
  # save_thank_you_letter(id, form_letter)
  # puts "#{name} - #{get_day_of_week(row[:regdate])}"
end

peak_hours = sort_by_frequency(time_log)
puts "PEAK HOUR(S): "
peak_hours.each { |hr| puts hr[0] } 
puts ""
peak_days = sort_by_frequency(wday_log)
puts "PEAK DAY(S):"
peak_days.each { |day| puts day[0] }


