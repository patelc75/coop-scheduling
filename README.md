# coop-scheduling

## Descriptions/Background

Co-op School's app to schedule classes based on two sets of GCals: 1) 
specialist availability 2) class availability. 

The code uses a "greedy algorithm" where each special (special.json) is looped through all the classes associated with it (classes.json). Alternating week group classes (eg. half groups alternate between art and woodshoip eery week) are supported by providing to specialist calendars in special.json

Requirements: [Google Doc](https://docs.google.com/document/d/1qBIYSTEUu-8jmeWuvZ9mrWTmkWM_LXEiKnJtz40smLU/edit#) (ask Chirag or Mandy for permissions)

We are using this Ruby google calendar wrapper: https://github.com/northworld/google_calendar

## Usage

1. Log into to Google Calendar (coopcalendars@thecoopschool.org). Get password from Mandy or Chirag
1. Ask Chirag for the Google Cal auth env variables via LastPass. 
1. Install gems below
1. Confirm specials.json and classes.json are correct (split up specials in specials.json for better load balancing of classes)
1. Run `rdebug coop_scheudler.rb` or `ruby coop_scheduler.rb`
1. If `Google::HTTPAuthorizationFailed` error occurs, uncomment the `prompt_for_refresh_token(cal)` line in `ruby coop_scheduler.rb`
1. In the output look for the "Could not Schedule" string for classes that could not be scheduled
1. When finished, hide the "Class In" or "Special In" calendars in Google Cal account and look for the "Class Out" and "Special Out" alendars
1. See Github issues for pending development still needed (recurring events not working for example)

## Onboarding Instructions

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
