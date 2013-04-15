if (typeof window == 'undefined' || window === null) {
  require('prelude-ls').installPrelude(global);
} else {
  prelude.installPrelude(window);
}
(function(){
  var MiddleWare;
  MiddleWare = require('./raven/middle-ware');
  module.exports = MiddleWare;
}).call(this);
