###
  backbone-orm.js 0.7.8
  Copyright (c) 2013-2014 Vidigami
  License: MIT (http://www.opensource.org/licenses/mit-license.php)
  Source: https://github.com/vidigami/backbone-orm
  Dependencies: Backbone.js and Underscore.js.
###

_ = require 'underscore'

UNITS_TO_MS =
  milliseconds: {milliseconds: 1}
  seconds: {milliseconds: 1000}
  minutes: {milliseconds: 60*1000}
  hours: {milliseconds: 24*60*1000}
  days: {days: 1}
  weeks: {days: 7}
  months: {months: 1}
  years: {years: 1}

module.exports = class DateUtils
  @durationAsMilliseconds: (count, units) ->
    throw new Error "DateUtils.durationAsMilliseconds :Unrecognized units: #{units}" unless lookup = UNITS_TO_MS[units]

    # from moment duration
    return count * lookup.milliseconds if lookup.milliseconds
    return count * 864e5 * lookup.days if lookup.days
    return count * lookup.months * 2592e6 if lookup.months
    return count * lookup.years * 31536e6 if lookup.years

  @isBefore: (mv, tv) -> mv.getTime() < tv.getTime()
  @isAfter: (mv, tv) -> mv.getTime() > tv.getTime()

  # iso_string_regex = /^[-+]?\d{4,6}-\d\d-\d\dT\d\d:\d\d:\d\d\.\d{3}Z$/
  # @isISOString: (s) -> iso_string_regex.test(s)
  # iso_parse_string_regex = /^([-+]?\d{4,6})-(\d\d)-(\d\d)T(\d\d):(\d\d):(\d\d)\.(\d{3})Z$/
  # @fromISOString: (s) ->
  #   groups = iso_parse_string_regex.exec(s)
  #   return new Date(Date.UTC(groups[1], groups[2], groups[3], groups[4], groups[5], groups[6], groups[7]))
