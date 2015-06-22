# coop-scheduling

## Descriptions/Background

Co-op School's app to schedule classes based on two sets of GCals: 1) 
specialist availability 2) class availability. 

Requirements: [Google Doc](https://docs.google.com/document/d/1qBIYSTEUu-8jmeWuvZ9mrWTmkWM_LXEiKnJtz40smLU/edit#) (ask Chirag or Mandy for permissions)

We are using this Ruby google calendar wrapper: https://github.com/northworld/google_calendar

## Onboarding Instructions

* Install these gems:

```ruby
gem install 'google_calendar' #may need to install locally
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
