(function() {
  $(function() {
    var setType, type, types;
    types = ['CoffeeScript', 'JavaScript'];
    setType = function(type) {
      var cls;
      if (type == null) {
        type = 'CoffeeScript';
      }
      cls = type.toLowerCase();
      $(".example:not(." + cls + ")").hide();
      $(".example." + cls).show();
      if (typeof localStorage !== "undefined" && localStorage !== null) {
        localStorage.setItem('type', type);
      }
      return $('.btn.language-toggle span').text(type);
    };
    type = typeof localStorage !== "undefined" && localStorage !== null ? localStorage.getItem('type') : void 0;
    setType(type);
    return $('.btn.language-toggle').on('click', function(e) {
      var $span, to_type;
      $span = $(this).find('span');
      to_type = types[Math.abs(types.indexOf($span.text()) - 1)];
      return setType(to_type);
    });
  });

}).call(this);
