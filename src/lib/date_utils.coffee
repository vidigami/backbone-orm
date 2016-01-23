###
  backbone-orm.js 0.7.14
  Copyright (c) 2013-2016 Vidigami
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

  @isBefore: (mv, tv) -> mv.valueOf() < tv.valueOf()
  @isAfter: (mv, tv) -> mv.valueOf() > tv.valueOf()
  @isEqual: (mv, tv) -> +mv is +tv
