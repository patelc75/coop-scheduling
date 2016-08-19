# coop-scheduling

## Descriptions/Background

Co-op School's app to schedule classes based on two sets of GCals: 1) 
specialist availability 2) class availability. 

The code uses a "greedy algorithm" where each special (special.json) is looped through all the classes associated with it (classes.json). Alternating week group classes (eg. half groups alternate between art and woodshoip eery week) are supported by providing to specialist calendars in special.json

Requirements: [Google Doc](https://docs.google.com/document/d/1qBIYSTEUu-8jmeWuvZ9mrWTmkWM_LXEiKnJtz40smLU/edit#) (ask Chirag or Mandy for permissions)

We are using this Ruby google calendar wrapper: https://github.com/northworld/google_calendar

## Usage instructions

Follow these instructions every time a schedule needs to be generated (usually before the semester starts) 

### Staff instructions

1. Log into `coopcalendars@thecoopschool.org` Google account (ask for credentials via LastPass if you don't have them)
1. Update all Google calendars that include the word "In" (eg. `Class In | Pre-K | Bumblebees`, `Special In | Gym Shanecka`) for both specialist and class schedules
1. Log into your github.com account (If no account, create an account on github.com and ask for permissions on the [coop-scheduling repo](https://github.com/patelc75/coop-scheduling))
1. Update [classes.json](https://github.com/patelc75/coop-scheduling/blob/master/classes.json) to add or remove classe schedules (Pre-K, K, 1st, etc) 
1. Update [specials.json](https://github.com/patelc75/coop-scheduling/blob/master/specials.json) to assign specific specials to specfic classes (eg. assign "movement" to "bumblebees", "fourth", "kindergarten"). 
1. Pretty please confirm google_calendar_id in classes.json and teacher1_google_calendar_id are correct in specials.json are CORRECT
1. If the schedules have too many specials on a single day, add a "Do not schedule" slot on that day in the classes "Class In" Google calendar

### Developer instructions

1. Log into to Google Calendar (coopcalendars@thecoopschool.org). Get password from Mandy or Chirag via LastPass
1. Ask Chirag for the Google Cal auth env variables via LastPass. 
1. Install gems below
1. Confirm `specials.json` and `classes.json` are correct 
1. Update $monday_start in `rdebug coop_scheduler.rb` and select the Monday's date of the current week
1. Run `rdebug coop_scheduler.rb` or `ruby coop_scheduler.rb`
1. Look for 'Could not schedule' messages in the console log after running. If found, you can split up or re-arrange the specials in `specials.json` for better load balancing of classes and re-run 
1. If `Google::HTTPAuthorizationFailed` error occurs, uncomment the `prompt_for_refresh_token(cal)` line in `ruby coop_scheduler.rb` to create a new refresh token
1. Do not use the token from the GCal site, first paste it into the ruby prompt and it will output the refresh token to use your env variables (eg. `export GCAL_REFRESH_TOKEN=<token>`)
1. In the output look for the "Could not Schedule" string for specials that could not be scheduled
1. When finished, hide the "Class In" or "Special In" calendars in Google Cal account and look for the "Class Out" and "Special Out" calendars
1. See Github issues for pending development still needed



## Developer onboarding instructions

* Install these gems:

```ruby
gem install 'google_calendar' #may need to install v0.5 locally (like on Chirag's 11' Mackbook air)
gem install 'chronic'
gem install 'time_difference'
```
* Ask Chirag for env vars necessary to connect to GCal API (optionally through LastPass)
* Execute `rdebug co-op scheudling`


### Useful debugging statements running `rdebug coop_scheduler.rb`

```ruby
e event_to_check_start_time.getlocal.to_s + " to " + event_to_check_end_time.getlocal.to_s
e Chronic.parse(special_to_schedule.start_time).getlocal.to_s + " to " + Chronic.parse(special_to_schedule.end_time).getlocal.to_s
```

### Naming convention of Google calendars

```
Special In | Gardening Sophie
Special In | Spanish Carla

Special Out | Gardening Sophie
Special Out | Spanish Carla
....

Class In | Pre-K | Dragonflies
Class In | Pre-K | Catydids

Class Out | Pre-K | Dragonflies
Class Out | Pre-K | Catydids
```

Because of the google_calendar gem, create a new cal to Google Calendar API only works on Chirag's 11' Macbook Air because of the way the gem was installed
