
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
#require 'ruby-prof'

def pause_for_keystroke
  puts 
  puts "Press any key to continue"
  begin
    # save previous state of stty
    old_state = `stty -g`
    # disable echoing and enable raw (not having to press enter)
    system "stty raw -echo"
    c = STDIN.getc.chr
    # gather next two characters of special keys
    if(c=="\e")
      extra_thread = Thread.new{
        c = c + STDIN.getc.chr
        c = c + STDIN.getc.chr
      }
      # wait just long enough for special keys to get swallowed
      extra_thread.join(0.00001)
      # kill thread so not-so-long special keys don't wait on getc
      extra_thread.kill
    end
  rescue => ex
    puts "#{ex.class}: #{ex.message}"
    puts ex.backtrace
  ensure
    # restore previous state of stty
    system "stty #{old_state}"
  end
  return c
end

$cached_calendars = {} #all calenders that are fetched from google calendars

class CoopCalendar < Google::Calendar
  attr_accessor :fetched_events

  def pretty_print
    self.fetched_events = self.fetched_events.sort! {|x, y| x.start_time <=> y.start_time}

    puts "\n" + summary + " Calendar"
    fetched_events.each do |event|
      print event.start_time_object.getlocal.strftime("%a %I:%M%p") + "-" + event.end_time_object.getlocal.strftime("%I:%M%p %Z") + " " + (event.title || 'untitled event')
        puts 
    end
    #pause_for_keystroke()
  end
end

def print_cached_calendars
  #$cached_calendars = $cached_calendars.sort_by { |k, v| v.summary }
  $cached_calendars.each do |key, cal|
    cal.pretty_print
  end  
end

$monday_start = Chronic.parse "monday june 6 8am" #=> 2015-06-08 09:00:00 -0400
five_day_duration = 5*24*60*60-12 #goes to EOD Friday (8pm)
$friday_end = $monday_start + five_day_duration
$daily_ending_time = "3:30pm"

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

  return false if cal.nil?
  #e event_to_check_start_time.getlocal.to_s + " to " + event_to_check_end_time.getlocal.to_s
  cal.fetched_events.each do |event|
    if ((event_to_check.start_time_object >= event.start_time_object && event_to_check.start_time_object < event.end_time_object) || (event_to_check.end_time_object > event.start_time_object && event_to_check.end_time_object <= event.end_time_object))
      return true
    end
  end
  return false
end

def store_special_in_cal_events(special_to_schedule, class_cal, specialist_cal1, specialist_cal2)
  puts "\n" + special_to_schedule.title + 
    " SCHEDULED for " + 
    special_to_schedule.start_time_object.getlocal.strftime("%a %m-%d-%Y %H:%M%p %Z") + 
    " to " + 
    special_to_schedule.end_time_object.getlocal.strftime("%a %m-%d-%Y %H:%M%p %Z") + "\n"

  #All the fetched events from GCal API had status="confirmed", but allowed to write to it
  #special_to_schedule.status = "confirmed" 
  class_cal.fetched_events << special_to_schedule
  specialist_cal1.fetched_events << special_to_schedule
  specialist_cal2.fetched_events << special_to_schedule if specialist_cal2

  #TODO ISSUE #2 If more than one per week, create the rest at the same time for the rest of the week
  #num_per_week = special["num_per_week"].to_i
end

def set_start_time_for_next_day(special_to_schedule, start_time, new_time_of_day, special_duration)
  new_start_time = start_time + 24*60*60 #jump to the next day
  new_start_time_date_only = new_start_time.getlocal.strftime("%Y-%m-%d")
  new_start_time = Chronic.parse("#{new_start_time_date_only} " + new_time_of_day)

  new_special_to_schedule = special_to_schedule
  new_special_to_schedule.start_time_object = new_start_time
  new_special_to_schedule.start_time = new_special_to_schedule.start_time_object
  new_special_to_schedule.end_time_object = new_start_time + special_duration*60
  new_special_to_schedule.end_time = new_special_to_schedule.end_time_object
  #puts 
  #puts "Trying " + new_start_time.strftime("%A")
  return new_special_to_schedule
end

def schedule_specials_for_week(class_cal, specialist_cal1, specialist_cal2, special)
  special_duration = special["duration_in_mins"].to_i
  num_per_week = special["num_per_week"].to_i

  special_to_schedule, special_duration = define_starting_slot(special, $monday_start, class_cal)

  while (num_per_week >= 1)    
    if(!special_to_schedule.nil?)  
      special_to_schedule = find_empty_slot_with_no_conflict(
          special_to_schedule,
          special_duration,
          class_cal, 
          specialist_cal1,
          specialist_cal2
      )

      
      if(!special_to_schedule.nil?)
        store_special_in_cal_events(special_to_schedule, class_cal, specialist_cal1, specialist_cal2)

        break if num_per_week == 1
        special_to_schedule = special_to_schedule.dup
        class << special_to_schedule
          attr_accessor :start_time_object
          attr_accessor :end_time_object
        end
        special_to_schedule.start_time_object = Chronic.parse special_to_schedule.start_time
        special_to_schedule.end_time_object = Chronic.parse special_to_schedule.end_time
        set_start_time_for_next_day(
          special_to_schedule,
          special_to_schedule.start_time_object, 
          "8am",
          special_duration
        ) # last param is "09:45AM"
      else
        puts "========Could not schedule========"

      end
    else
      puts "========Could not schedule========"
    end

    num_per_week -= 1
    #debugger if new_start_time.getlocal.strftime("%H:%M%p") == "09:45AM"
  end
end


def define_starting_slot(special, starting_slot, class_cal)
  special_title = "-----" + special["title"].upcase + ": " + class_cal.summary.split("|")[2].strip.upcase + "-----"

  special_duration = special["duration_in_mins"].to_i

  special_to_schedule = Google::Event.new

  class << special_to_schedule
    attr_accessor :start_time_object
    attr_accessor :end_time_object
  end

  special_to_schedule.title = special_title
  special_to_schedule.start_time_object = starting_slot
  special_to_schedule.start_time = special_to_schedule.start_time_object
  special_to_schedule.end_time_object = starting_slot + special_duration*60 
  special_to_schedule.end_time = special_to_schedule.end_time_object

  puts "\n" + "Searching for a " + special["duration_in_mins"] + " slot for " + special_title + " starting with " + special_to_schedule.start_time_object.getlocal.strftime("%a %m-%d-%Y %H:%M%p %Z") + "\n"

  return special_to_schedule, special_duration
end

def find_empty_slot_with_no_conflict(special_to_schedule, special_duration, class_cal_input, specialist_cal_input1, specialist_cal_input2)
  specialist_conflict = class_conflict = true

  while(special_to_schedule.end_time_object < $friday_end)    
    #print Chronic.parse(special_to_schedule.start_time).getlocal.strftime("%H:%M%p %Z") + ", "      
    class_conflict = look_for_conflict(special_to_schedule, class_cal_input)
    if class_conflict == false
      specialist_conflict  = look_for_conflict(special_to_schedule, specialist_cal_input1)
      if specialist_conflict == false
        specialist_conflict  = look_for_conflict(special_to_schedule, specialist_cal_input2)
        if specialist_conflict == false
          return special_to_schedule
        end
      end
    end 
    #Increment every 5 minutes
    new_start_time = special_to_schedule.start_time_object + 5*60 
    new_end_time = special_to_schedule.start_time_object + (special_duration+5)*60
    #debugger if new_start_time.getlocal.strftime("%H:%M%p") == "09:45AM"

    if new_end_time < Chronic.parse(new_start_time.getlocal.strftime("%Y-%m-%d ") + $daily_ending_time)
      special_to_schedule.start_time_object = new_start_time
      special_to_schedule.start_time = special_to_schedule.start_time_object
      special_to_schedule.end_time_object = new_end_time
      special_to_schedule.end_time = new_end_time
    else
      special_to_schedule = set_start_time_for_next_day(special_to_schedule, new_start_time, "8am", special_duration)
    end
  end

end


def fetch_existing_calendar(calendar_id)
  if !$cached_calendars[calendar_id].nil?
    return $cached_calendars[calendar_id]
  end

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
    events = cal.find_events_in_range($monday_start, $friday_end, :expand_recurring_events => true, :max_results => 100)
    events.each do |event|
      class << event
        attr_accessor :start_time_object
        attr_accessor :end_time_object
      end
     
      event.start_time_object = Chronic.parse event.start_time
      event.end_time_object = Chronic.parse event.end_time
    end
    cal.fetched_events = events
    $cached_calendars[calendar_id] = cal
    return cal
  else
    return nil
  end
end

def write_cached_calendars_to_gcal
  puts "Do want to create these calendars to the Google API? (y/n)"
  has_token = $stdin.gets.chomp

  if has_token.downcase == 'y'
    $cached_calendars.each do |key, cal|
      create_new_cal_and_write_to_gcal_api(cal)
      break
    end
  end
end

def create_new_cal_and_write_to_gcal_api(input_cal) 
  output_cal_name = input_cal.summary.gsub("In", "Out")
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
      #output_event = output_cal.create_event
      output_event.title = input_event.title
      output_event.start_time = input_event.start_time_object
      output_event.end_time = input_event.end_time_object
      output_event.location = "40 Brevoort Place, Brooklyn, NY 11216"
      output_event.recurrence = {'freq' => 'weekly', 'byday' => 'mo,tu,we,th,fr'}
      #output_event.save
    end    
  end

  output_cal.fetched_events = input_cal.fetched_events
  return output_cal
end

def get_classes_mapped_to_special(special, class_cals)
  filtered_classes = []
  special["classes"].each do |special_class| 
    filtered_classes += class_cals.select { |cal|  cal["name"] == special_class }
  end
  return filtered_classes
end  

specials_file = File.read('specials.json')
cal_file = File.read('classes.json')
specials = JSON.parse(specials_file)
class_cals = JSON.parse(cal_file)

specials.each do |special|
  cal_specialist_input1 = fetch_existing_calendar(special["teacher1_google_calendar_id"])
  cal_specialist_input2 = fetch_existing_calendar(special["teacher2_google_calendar_id"])
  
  if !cal_specialist_input1.nil?
    applicable_classes = get_classes_mapped_to_special(special, class_cals)
    applicable_classes.each do |class_cal_json|
      cal_class_input = fetch_existing_calendar(class_cal_json["google_calendar_id"])
      schedule_specials_for_week(cal_class_input, cal_specialist_input1, cal_specialist_input2, special)
    end
  end
end

print_cached_calendars()

write_cached_calendars_to_gcal()

