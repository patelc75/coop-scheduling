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


class CoopCalendar < Google::Calendar
  attr_accessor :fetched_events

  def pretty_print
    puts "\n" + summary + " Calendar"
    fetched_events.each do |event|
      print Chronic.parse(event.start_time).getlocal.strftime("%a %H:%M%p") + "-" + Chronic.parse(event.end_time).getlocal.strftime("%H:%M%p %Z") + " " + event.title
        puts 
    end
  end
end

$monday_start = Chronic.parse "monday june 22 8am" #=> 2015-06-08 09:00:00 -0400
five_day_duration = 5*24*60*60-12 #goes to EOD Friday (8pm)
$friday_end = $monday_start + five_day_duration
$daily_ending_hour = 16

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
  puts "\n" + cal.summary
  puts "TOTAL EVENTS: #{events.count}"
  puts "DATE RANGE: #{start_date.getlocal.strftime("%a %m-%d-%Y %H:%M%p %Z")} to #{end_date.getlocal.strftime("%a %m-%d-%Y %H:%M%p %Z")}"
  puts 
end

def look_for_conflict(event_to_check, cal)

  event_to_check_start_time = Chronic.parse event_to_check.start_time
  event_to_check_end_time = Chronic.parse event_to_check.end_time
#e event_to_check_start_time.getlocal.to_s + " to " + event_to_check_end_time.getlocal.to_s
  cal.fetched_events.each do |event|
    event_start_time = Chronic.parse event.start_time
    event_end_time = Chronic.parse event.end_time
    if ((event_to_check_start_time >= event_start_time && event_to_check_start_time <= event_end_time) || (event_to_check_end_time >= event_start_time && event_to_check_end_time <= event_end_time))
      return true
    end
  end
  
  return false
end

def store_special_in_cal_events(special_to_schedule, class_cal, specialist_cal)
  puts "\n" + special_to_schedule.title + " SCHEDULED for " + Chronic.parse(special_to_schedule.start_time).getlocal.strftime("%a %m-%d-%Y %H:%M%p %Z") + " to " + Chronic.parse(special_to_schedule.end_time).getlocal.strftime("%a %m-%d-%Y %H:%M%p %Z") + "\n"

  #All the fetched events from GCal API had status="confirmed", but allowed to write to it
  #special_to_schedule.status = "confirmed" 

  class_cal.fetched_events << special_to_schedule
  specialist_cal.fetched_events << special_to_schedule
  # This is to write a single event to a calendar 
  # class_cal_output.create_event do |output_event|
  #   output_event.title = special_to_schedule.title
  #   output_event.start_time = special_to_schedule.start_time
  #   output_event.end_time = special_to_schedule.end_time
  # end
  # specialist_cal_output.create_event do |output_event|
  #   output_event.title = special_to_schedule.title
  #   output_event.start_time = special_to_schedule.start_time
  #   output_event.end_time = special_to_schedule.end_time
  # end   

  #TODO ISSUE #2 If more than one per week, create the rest at the same time for the rest of the week
  #num_per_week = special["num_per_week"].to_i

end

def get_new_start_time_for_next_day(new_start_time, special_to_schedule)
  new_start_time = new_start_time + 24*60*60 #jump to the next day
  date_only_no_time = new_start_time.getlocal.strftime("%Y-%m-%d")
  new_start_time = Chronic.parse "#{date_only_no_time} 8am" 
  special_to_schedule.start_time = new_start_time
  special_to_schedule.end_time = Chronic.parse(special_to_schedule.start_time) + special_duration*60

  puts 
  puts "Trying " + new_start_time.strftime("%A")
  return special_to_schedule
end

def define_starting_slot(special)
  special_title = special["title"]+ " #" + 1.to_s
  special_duration = special["duration_in_mins"].to_i

  special_to_schedule = Google::Event.new
  special_to_schedule.title = special_title
  special_to_schedule.start_time = $monday_start
  special_to_schedule.end_time = $monday_start + special_duration*60 #add 30 mins

  puts "\n" + "Searching for a " + special["duration_in_mins"] + " slot for " + special_title + " starting with " + Chronic.parse(special_to_schedule.start_time).getlocal.strftime("%a %m-%d-%Y %H:%M%p %Z") + "\n"
  print "Trying "

  return special_to_schedule, special_duration
end

def find_empty_slot_with_no_conflict(special, class_cal_input, specialist_cal_input)
  special_to_schedule, special_duration = define_starting_slot(special)

  specialist_conflict = class_conflict = true

  while(Chronic.parse(special_to_schedule.end_time) < $friday_end)    
    print Chronic.parse(special_to_schedule.start_time).getlocal.strftime("%H:%M%p %Z") + ", "      
    class_conflict = look_for_conflict(special_to_schedule, class_cal_input)
    if class_conflict == false
      specialist_conflict  = look_for_conflict(special_to_schedule, specialist_cal_input)
      if specialist_conflict == false
        store_special_in_cal_events(special_to_schedule, class_cal_input, specialist_cal_input)
        break        
      end
    end 

    #Increment every 5 minutes
    new_start_time = Chronic.parse(special_to_schedule.start_time) + 5*60 
    new_end_time = Chronic.parse(special_to_schedule.start_time) + (special_duration+5)*60
    #debugger if new_start_time.getlocal.strftime("%H:%M%p") == "09:45AM"

    if new_end_time.getlocal.hour <= $daily_ending_hour #4pm
      special_to_schedule.start_time = new_start_time
      special_to_schedule.end_time = new_end_time
    else
      special_to_schedule = get_new_start_time_for_next_day(new_start_time)
    end
  end
end


def fetch_existing_calendar(calendar_id)
  if (calendar_id)
    cal = CoopCalendar.new(
             :client_id     => ENV["GCAL_CLIENT_ID"],
             :client_secret => ENV["GCAL_CLIENT_SECRET"],
             :calendar      => calendar_id,
             :redirect_url  => ENV["GCAL_REDIRECT_URL"]
          )

    #Uncomment only if hard coded refresh token doesn't work
    #prompt_for_refresh_token(cal)

    cal.login_with_refresh_token(ENV["GCAL_REFRESH_TOKEN"])

    events = cal.find_events_in_range($monday_start, $friday_end, :expand_recurring_events => true)
    cal.fetched_events = events
    return cal
  else
    return nil
  end
end

def setup_new_calendar(input_cal) 
  output_cal_name = input_cal.summary + " Filled"
  output_cal = CoopCalendar.create(
                 :client_id     => ENV["GCAL_CLIENT_ID"],
                 :client_secret => ENV["GCAL_CLIENT_SECRET"],
                 :summary => output_cal_name,
                 :redirect_url => ENV["GCAL_REDIRECT_URL"],
                 :refresh_token => ENV["GCAL_REFRESH_TOKEN"] # this is what Google uses 
               )
  
  #prompt_for_refresh_token(output_cal)

  puts "Calendar created: " + output_cal_name
  input_cal.fetched_events.each do |input_event|
    output_cal.create_event do |output_event|
      output_event.title = input_event.title
      output_event.start_time = input_event.start_time
      output_event.end_time = input_event.end_time
    end    
  end

  output_cal.fetched_events = input_cal.fetched_events
  return output_cal
end

specials_file = File.read('specials.json')
cal_file = File.read('classes.json')
specials = JSON.parse(specials_file)
class_cals = JSON.parse(cal_file)

specials.each do |special|
  cal_specialist_input = fetch_existing_calendar(special["google_calendar_id"])

  if !cal_specialist_input.nil?
    #cal_specialist_output = setup_new_calendar(cal_specialist_input)
    class_cals.each do |class_cal_json|
      cal_class_input = fetch_existing_calendar(class_cal_json["class_calendar_id"])
      #cal_class_output = setup_new_calendar(cal_class_input)
      cal_class_input.pretty_print()
      cal_specialist_input.pretty_print()
      find_empty_slot_with_no_conflict(
          special,
          cal_class_input, 
          cal_specialist_input
      )
      
      cal_class_input.fetched_events = cal_class_input.fetched_events.sort! {|x, y| x.start_time <=> y.start_time}
      cal_class_input.pretty_print()
    end
  end
end

