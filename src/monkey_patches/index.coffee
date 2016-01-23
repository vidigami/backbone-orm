###
  backbone-orm.js 0.7.14
  Copyright (c) 2013-2016 Vidigami
  License: MIT (http://www.opensource.org/licenses/mit-license.php)
  Source: https://github.com/vidigami/backbone-orm
  Dependencies: Backbone.js and Underscore.js.
###

{Backbone} = require '../core'

# TODO: remove when regression fixed: https://github.com/jashkenas/backbone/issues/3693
[major, minor] = Backbone.VERSION.split('.')

if (+major >= 1) and (+minor >=2)
  `
  // Internal method called by both remove and set.
  // Returns removed models, or false if nothing is removed.
  Backbone.Collection.prototype._removeModels = function(models, options) {
    var removed = [];
    for (var i = 0; i < models.length; i++) {
      var model = this.get(models[i]);
      if (!model) continue;

      // MONKEY PATCH
      var id = this.modelId(model.attributes);
      if (id != null) delete this._byId[id];
      delete this._byId[model.cid];

      var index = this.indexOf(model);
      this.models.splice(index, 1);
      this.length--;

      if (!options.silent) {
        options.index = index;
        model.trigger('remove', model, this, options);
      }

      removed.push(model);
      this._removeReference(model, options);
    }
    return removed.length ? removed : false;
  }
  `
