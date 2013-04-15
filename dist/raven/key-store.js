if (typeof window == 'undefined' || window === null) {
  require('prelude-ls').installPrelude(global);
} else {
  prelude.installPrelude(window);
}
(function(){
  var fs, kid, key;
  fs = require('fs');
  kid = function(it){
    return it.replace(/pubkey/, '');
  };
  key = function(d, f){
    return fs.readFileSync(d + "/" + f, 'utf8');
  };
  module.exports = function(dir){
    var fns, fn;
    fns = fs.readdirSync(dir);
    return objToFunc(
    listToObj(
    (function(){
      var i$, ref$, len$, results$ = [];
      for (i$ = 0, len$ = (ref$ = fns).length; i$ < len$; ++i$) {
        fn = ref$[i$];
        if (/pub/.exec(fn)) {
          results$.push([kid(fn), key(dir, fn)]);
        }
      }
      return results$;
    }())));
  };
}).call(this);
