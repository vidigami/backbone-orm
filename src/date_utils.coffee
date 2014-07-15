###
  backbone-orm.js 0.6.0
  Copyright (c) 2013-2014 Vidigami
  License: MIT (http://www.opensource.org/licenses/mit-license.php)
  Source: https://github.com/vidigami/backbone-orm
  Dependencies: Backbone.js, Underscore.js, and Moment.js.
###

_ = require 'underscore'
moment = require 'moment'

module.exports = class DateUtils
  @durationAsMilliseconds: (count, units) ->
    moment.duration(count, units).asMilliseconds()

  @isBefore: (mv, tv) -> return moment(mv).isBefore(tv)
  @isBeforeOrSame: (mv, tv) -> mvm = moment(mv); return mvm.isBefore(tv) or mvm.isSame(tv)
  @isAfter: (mv, tv) -> return moment(mv).isAfter(tv)
  @isAfterOrSame: (mv, tv) -> mvm = moment(mv); return mvm.isAfter(tv) or mvm.isSame(tv)
