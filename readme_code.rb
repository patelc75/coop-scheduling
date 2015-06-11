#
# Uncomment the LOAD_PATH lines if you want to run against the
# local version of the gem.
#
# $LOAD_PATH.unshift(File.join(File.dirname(__FILE__), 'lib'))
# $LOAD_PATH.unshift(File.dirname(__FILE__))

require 'rubygems'
require 'google_calendar'

# Create an instance of the calendar.
cal = Google::Calendar.new(:client_id     => "419624150549-g443ff1nnjh52u6kbslilfjj25o7epvq.apps.googleusercontent.com",
                           :client_secret => "MIIEvgIBADANBgkqhkiG9w0BAQEFAASCBKgwggSkAgEAAoIBAQCzEmIWTCDJWq+s\n2z2rfcIyLMfy1uASugicwajQfReOgDVD6IZ6XgaFsthDG58tasDU4jjeyjUitSjE\n0P6U+IVJLcIesA1GyUqMEnCFIBGiAvZWNtueOcRpLIg65ozzI5aMN07iSxQHB34u\ngiO3SEfKgTkTV0aS+WCQ3Fk3L0mURudEHvIqD3auFrvxBu9Kij9RyDyEVv81k5GZ\nb3UiWHf2q65zAa/G8aP2H4KBuu3P1a3PRZlcAN5rGnMiQVnhkzZQnZGVwOPYsyM9\nDfFcSpqDBToiK2BhGubZxId/NqitcJ+2Cilg695vwxFExZJUn7v3WvO0LShBYXLA\nAwC3pxZ1AgMBAAECggEAaXpbkny3F0O2lN/zHG+QEtPz1uOgywcPiZ483MnCNWrp\ndR2jELMPrnMhFa5QfYUTHpI+I2UCFXaWFBBy1Lbqc6djX4Yd2+M3aPh3lMLGACM0\njKX1iObH/ZeAiwlAXvtIc0Ek0wCcRGOyfJylgxEtUGf7gZv38xy3N7zDRFEzSwXY\nCMePS7B7nRC7X5uHDb3WF3BzTwnvOkiWToeFVn4HgHmIWiWcXxuj5MOt/s7OQDMH\ndEj6myYX+lzU0HFBc3TicQct7PJtZ6/ucUfa81in1huGSG5bTo//rEYU2fGsYgh8\nFoetqgtDRN1CQOuMADceHH6PP+yxjJBWqR1d6SE9AQKBgQDjIdu3Y51pw5ULInRY\nadkMBetXBanqui+rH812EkThVVwDh3JRd4ILpt1vUWy+FxrSTkT57MBbTapXc1q9\n5UYoKZ4y0h3PU9CCy7SlEf1uonyedEY64zK5t/jIfuaNKQ3y+W+0Z/wF1yMvAKmQ\nnkp70a7rsf+piBsaS6XDgrnqtQKBgQDJ1Mt7bNIe3TpTMxNHKfqUillTty6zHYH9\nmUlfVXKFGXSxbYoxOwD8gP99EoYwoU4ibvtCL8ocTwsq0JGsIPi4xw+BU8roQkuI\nArEbCTOZRF0Mk3onYDBM1Ezvhkf8/LXSMSRkokugHt1dXg9p7fb8maQgy1P7UsVQ\nFRuL0+sUwQKBgQCY/YVx0beGNid+iIa1xxZb8uDCjR4W7bKOIa3Tihq7bTO9bM6j\n8Uu3bX5aLQ6CPC3k2rO7ZK1s0rOalCjbIERRaTcWJFHQBTS95ViYl7WNgAVQ9iEY\nKVFRp4n8Av5otu6ea0XCzwgDJxab4mZU80pYfLTGLe930iXvYGUXfEaewQKBgDR/\ntHojYTiEBQLVO0N8iOCQaBHdiTkwCLsFX09783DpoS/xtUt+9I+5ojtPUTZfDuro\nAVVDBwh8CwSVAf9LCEdQCBl0yUfGzszPHnBQ4WoRnT6DMfgCDi493tFDFYCZ31WQ\nUM4YZSF+RcheihXcvy0PbeDV4r9x1T8yblrdwb1BAoGBAIU0OuU95Quo/BPt8EEh\n4qFsiXWtVxi6izEi2d4B/6dI22LR3J5JK6mlceqp8ciO9UuQT/IcAW8YMBSvlqut\ndEQw3Eg0Oj6YXoyUPVJZVnOnZahIL8ThoW+NGEUCxD3Cxj4cTvSu8tsVXfYtLel1\nu+VL8WP6WRWZA4i9XXdGhoGN\n",
                           :calendar      => YOUR_CALENDAR_ID,
                           :redirect_url  => "urn:ietf:wg:oauth:2.0:oob" # this is what Google uses for 'applications'
                           )

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

cal.find_events_in_range(start_time, end_time, :expand_recurring_events => true)
# event = cal.create_event do |e|
#   e.title = 'A Cool Event'
#   e.start_time = Time.now
#   e.end_time = Time.now + (60 * 60) # seconds * min
# end

# puts event

# event = cal.find_or_create_event_by_id(event.id) do |e|
#   e.title = 'An Updated Cool Event'
#   e.end_time = Time.now + (60 * 60 * 2) # seconds * min * hours
#   e.color_id = 3  # google allows colors 0-11
# end

puts event

# All events
puts cal.events

# Query events
puts cal.find_events('your search string')
