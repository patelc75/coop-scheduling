#
# Uncomment the LOAD_PATH lines if you want to run against the
# local version of the gem.
#
# $LOAD_PATH.unshift(File.join(File.dirname(__FILE__), 'lib'))
# $LOAD_PATH.unshift(File.dirname(__FILE__))

require 'rubygems'
require 'google_calendar'
require 'json'
require 'chronic'

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

def find_slot_in_class_cal(cal)
  monday_gcal = Chronic.parse "last monday 8am" #=> 2015-06-08 09:00:00 -0400
  friday_gcal = monday_gcal + (5*24*60*60)
  events = cal.find_events_in_range(monday_gcal, friday_gcal, :expand_recurring_events => true)
  puts "TOTAL EVENTS: #{events.count} from #{monday_gcal.to_s} to #{friday_gcal.to_s}"
  #puts cal_bumblebee.events
end

def setup_calendar(calendar_id)
  cal = Google::Calendar.new(
                             :client_id     => "419624150549-7plpq38mughrvbnt3jde6vf5urge64ga.apps.googleusercontent.com",
                             :client_secret => "4TJFhxJ1QrS8Ev8jM57DYemb",
                             :calendar      => calendar_id,
                             :redirect_url  => "urn:ietf:wg:oauth:2.0:oob" # this is what Google uses for 'applications'
                             )

  #Uncomment only if hard coded refresh token doesn't work
  #prompt_for_refresh_token(cal)

  refresh_token = "1/-JJFnXmK-2Wyb0ImBpXwvaapSIf_JQ89OfSW8ARO5wU"
  #cal.login_with_auth_code
  cal.login_with_refresh_token(refresh_token)
  return cal
  # Query events
  #cal_bumblebee.find_events('your search string')
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
  num_per_week.times do |num|
    class_cals.each do |class_cal|
      cal_bumblebee = setup_calendar(class_cal["calendar_id"])
      find_slot_in_class_cal(cal_bumblebee)
      #TODO: instead of hard coding to the first event, write a method to loop through all the events pulled from gcal ('events') and make sure period_start_monday doesn't
      #date_only_no_time = Time.parse(events[0].start_time).getlocal.strftime("%Y-%m-%d")
      #first_event = Chronic.parse "#{date_only_no_time} #{period_start}" #=> 2015-06-08 09:00:00 -0400

      #gcal_event = Time.parse(events[0].start_time).getlocal
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



