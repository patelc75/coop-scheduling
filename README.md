# coop-scheduling
Co-op School's app to schedule classes based on classroom, teacher, specialist, and class schedule

We are using this Ruby google calendar wrapper: https://github.com/northworld/google_calendar

# Useful debugging statements using `rdebug coop_scheduler.rb`

e event_to_check_start_time.getlocal.to_s + " to " + event_to_check_end_time.getlocal.to_s
e Chronic.parse(special_to_schedule.start_time).getlocal.to_s + " to " + Chronic.parse(special_to_schedule.end_time).getlocal.to_s
