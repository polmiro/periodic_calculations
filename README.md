# PeriodicCalculations

[![Build Status](https://travis-ci.org/polmiro/periodic_calculations.png)](https://travis-ci.org/polmiro/periodic_calculations)
[![Code Climate](https://codeclimate.com/github/polmiro/periodic_calculations.png)](https://codeclimate.com/github/polmiro/periodic_calculations)
[![Coverage Status](https://coveralls.io/repos/polmiro/periodic_calculations/badge.png)](https://coveralls.io/r/polmiro/periodic_calculations)
[![Gem Version](https://badge.fury.io/rb/periodic_calculations.png)](http://badge.fury.io/rb/periodic_calculations)

Periodic Calculations gem allows you to retrieve periodic results of aggregates that can be accumulated over time with PostgreSQL. The results are returned in real time (there are no scheduled precalculations).

The returned data is ready to be displayed in a graph, for example, using the [jQuery Flot](http://www.flotcharts.org/) library.

## Demo ##

Please check out the [demo](http://periodic-calculations-demo.herokuapp.com) to see it in action.

## How does it work ##

It takes advantage of the [window_functions](http://www.postgresql.org/docs/9.1/static/tutorial-window.html) to be able to generate accumulated metrics over time.
