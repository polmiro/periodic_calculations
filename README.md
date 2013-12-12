# PeriodicCalculations

[![Build Status](https://travis-ci.org/polmiro/periodic_calculations.png)](https://travis-ci.org/polmiro/periodic_calculations)
[![Code Climate](https://codeclimate.com/github/polmiro/periodic_calculations.png)](https://codeclimate.com/github/polmiro/periodic_calculations)
[![Coverage Status](https://coveralls.io/repos/polmiro/periodic_calculations/badge.png)](https://coveralls.io/r/polmiro/periodic_calculations)
[![Gem Version](https://badge.fury.io/rb/periodic_calculations.png)](http://badge.fury.io/rb/periodic_calculations)

Periodic Calculations gem allows you to retrieve periodic results of aggregates that can be accumulated over time with PostgreSQL. The results are returned in real time (there are no scheduled precalculations).

The returned data is ready to be displayed in a graph, for example, using the [jQuery Flot](http://www.flotcharts.org/) library.

## Demo ##

Please check out the [demo](http://periodic-calculations-demo.herokuapp.com) to see it in action.

## Installation ##

Add this line to your application's Gemfile:

```ruby
gem 'periodic_calculations'
```

## Usage ##

The gem adds theses methods to active record instances: periodic_operation, periodic_count_all, periodic_sum, periodic_minium, periodic_max, periodic_average.

It will return an array composed of pairs [Time, _result_]. One pair for each period interval.

```ruby
@data = Purchase
  .where("price > 0")     # custom scope
  .periodic_sum(
    :price,               # target column
    30.days.ago,          # start time
    Time.now,             # end time
    :cumulative => true   # options
  )

# Example result
# [
#   [#Time<"2013-11-11 00:00:00 -0800">, 200],
#   [#Time<"2013-11-12 00:00:00 -0800">, 200],
#   [#Time<"2013-11-13 00:00:00 -0800">, 500],
#   [#Time<"2013-11-14 00:00:00 -0800">, 800],
#   ...
#   [#Time<"2013-12-08 00:00:00 -0800">, 1100],
#   [#Time<"2013-12-09 00:00:00 -0800">, 1700],
#   [#Time<"2013-12-10 00:00:00 -0800">, 1700],
# ]
```

You can play with the different options and see the code produced in the [demo page](http://periodic-calculations-demo.herokuapp.com)

## How does it work ##

The gem takes advantage of the [window_functions](http://www.postgresql.org/docs/9.1/static/tutorial-window.html) to be able to generate accumulated metrics over time.
