#
# Uncomment the LOAD_PATH lines if you want to run against the
# local version of the gem.
#
# $LOAD_PATH.unshift(File.join(File.dirname(__FILE__), 'lib'))
# $LOAD_PATH.unshift(File.dirname(__FILE__))

require 'rubygems'
require 'json'

#require specfic gem installations
require 'google_calendar'
require 'chronic'
require 'time_difference'

$monday_start = Chronic.parse "last monday 8am" #=> 2015-06-08 09:00:00 -0400
five_day_duration = 5*24*60*60-12 #goes to EOD Friday (8pm)
$friday_end = $monday_start + five_day_duration
$daily_ending_hour = 16
$calendar_hash = {}

def prompt_for_refresh_token(cal)
  puts "Do you already have a refresh token? (y/n)"
  has_token = $stdin.gets.chomp

  if has_token.downcase != 'y'

    # A user needs to approve access in order to work with their calendars.
    puts "Visit the following web page in your browser and approve access."
    puts cal.authorize_url
    puts "\nCopy the code that Google returned and paste it here:"

    # Pass the ONE TIME USE access code here to login and get a refresh token that you can use for access from now on.
    refresh_token = cal.login_with_auth_code( $stdin.gets.chomp )

    puts "\nMake sure you SAVE YOUR REFRESH TOKEN so you don't have to prompt the user to approve access again."
    puts "your refresh token is:\n\t#{refresh_token}\n"
    puts "Press return to continue"
    $stdin.gets.chomp

  else

    puts "Enter your refresh token"
    refresh_token = $stdin.gets.chomp
    cal.login_with_refresh_token(refresh_token)

    # Note: You can also pass your refresh_token to the constructor and it will login at that time.
  end
end



def print_event_info (cal, events, start_date, end_date)
  puts cal.summary
  puts "TOTAL EVENTS: #{events.count}"
  puts "DATE RANGE: #{start_date.getlocal.strftime("%a %m-%d-%Y %H:%M%p %Z")} to #{end_date.getlocal.strftime("%a %m-%d-%Y %H:%M%p %Z")}"
  puts 
end

def look_for_conflict(event_to_check, cal)
  #events = cal.find_events_in_range($monday_start, $friday_end, :expand_recurring_events => true)
  #print_event_info(cal, events, $monday_start, $friday_end)
  events = $calendar_hash[cal.cal_id]

  event_to_check_start_time = Chronic.parse event_to_check.start_time
  event_to_check_end_time = Chronic.parse event_to_check.end_time
#e event_to_check_start_time.getlocal.to_s + " to " + event_to_check_end_time.getlocal.to_s
  events.each do |event|
    event_start_time = Chronic.parse event.start_time
    event_end_time = Chronic.parse event.end_time
    if ((event_to_check_start_time >= event_start_time && event_to_check_start_time < event_end_time) || (event_to_check_end_time > event_start_time && event_to_check_end_time <= event_end_time))
      return true
    end
  end
  
  return false
end


def find_empty_slot_with_no_conflict(class_cal, specialist_cal, special_title)
  #print_event_info(class_cal, class_events, $monday_start, $friday_end)

  special_to_schedule = Google::Event.new
  special_to_schedule.start_time = $monday_start
  special_to_schedule.end_time = $monday_start + 30*60 #add 30 mins
  specialist_conflict = class_conflict = true
  #e Chronic.parse(special_to_schedule.start_time).getlocal.to_s + " to " + Chronic.parse(special_to_schedule.end_time).getlocal.to_s

  while(Chronic.parse(special_to_schedule.end_time) < $friday_end)
    puts special_title + ": " + Chronic.parse(special_to_schedule.start_time).getlocal.strftime("%a %m-%d-%Y %H:%M%p %Z") + " to " + Chronic.parse(special_to_schedule.end_time).getlocal.strftime("%a %m-%d-%Y %H:%M%p %Z")      
    class_conflict = look_for_conflict(special_to_schedule, class_cal)  
    if class_conflict == false
      specialist_conflict  = look_for_conflict(special_to_schedule, specialist_cal)
      if specialist_conflict == false
        debugger
        puts "WE FOUND A SLOT! (todo: schedule a special in gcal via code)"
        break        
      end
    end

    new_start_time = Chronic.parse(special_to_schedule.start_time) + 15*60
    new_end_time = Chronic.parse(special_to_schedule.start_time) + 45*60
    if new_end_time.getlocal.hour <= $daily_ending_hour #4pm
      special_to_schedule.start_time = Chronic.parse(special_to_schedule.start_time) + 15*60
      special_to_schedule.end_time = Chronic.parse(special_to_schedule.start_time) + 30*60
    else
      new_start_time = new_start_time + 24*60*60 #jump to the next day
      date_only_no_time = new_start_time.getlocal.strftime("%Y-%m-%d")
      new_start_time = Chronic.parse "#{date_only_no_time} 8am" 
      special_to_schedule.start_time = new_start_time
      special_to_schedule.end_time = Chronic.parse(special_to_schedule.start_time) + 30*60
      puts 
      puts "Trying " + new_start_time.strftime("%A")
    end
  end
end

def fetch_calendar(calendar_id)
  cal = Google::Calendar.new(
                             :client_id     => "419624150549-7plpq38mughrvbnt3jde6vf5urge64ga.apps.googleusercontent.com",
                             :client_secret => "4TJFhxJ1QrS8Ev8jM57DYemb",
                             :calendar      => calendar_id,
                             :redirect_url  => "urn:ietf:wg:oauth:2.0:oob" # this is what Google uses for 'applications'
                             )

  #Uncomment only if hard coded refresh token doesn't work
  #prompt_for_refresh_token(cal)
  refresh_token = "1/-JJFnXmK-2Wyb0ImBpXwvaapSIf_JQ89OfSW8ARO5wU"
  cal.login_with_refresh_token(refresh_token)

  class << cal
    attr_accessor :cal_id
  end
  cal.cal_id = calendar_id
  events = cal.find_events_in_range($monday_start, $friday_end, :expand_recurring_events => true)
  $calendar_hash[cal.cal_id] = events

  return cal
  #cal.find_events('your search string')
end

specials_file = File.read('specials.json')
cal_file = File.read('classes.json')
specials = JSON.parse(specials_file)
class_cals = JSON.parse(cal_file)

=begin
periods_file = File.read('periods.json')
periods = JSON.parse(periods_file)
    periods.each do |period|
      period_start = period["start_time"]
      period_end = period["end_time"]
=end

specials.each do |special|
  num_per_week = special["num_per_week"].to_i

  cal_specialist = fetch_calendar(special["google_calendar_id"])
  num_per_week.times do |num|
    class_cals.each do |class_cal_json|
      #TODO: cache bumblebee cal since it will be created 5 times
      cal_bumblebee = fetch_calendar(class_cal_json["calendar_id"])
      find_empty_slot_with_no_conflict(cal_bumblebee, cal_specialist, special["title"]+ " #" +(num+1).to_s)
    end
  end
end


# event = cal_bumblebee.create_event do |e|
#   e.title = 'A Cool Event'
#   e.start_time = Time.now
#   e.end_time = Time.now + (60 * 60) # seconds * min
# end

# puts event

# event = cal_bumblebee.find_or_create_event_by_id(event.id) do |e|
#   e.title = 'An Updated Cool Event'
#   e.end_time = Time.now + (60 * 60 * 2) # seconds * min * hours
#   e.color_id = 3  # google allows colors 0-11
# end



