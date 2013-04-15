if (typeof window == 'undefined' || window === null) {
  require('prelude-ls').installPrelude(global);
} else {
  prelude.installPrelude(window);
}
(function(){
  module.exports = curry$(function(arg$, req, res, next){
    var logOutPath, ravenLogOut, x$;
    logOutPath = arg$.logOutPath, ravenLogOut = arg$.ravenLogOut;
    if (logOutPath != null && req.url.match(logOutPath)) {
      req.session.destroy();
      x$ = res;
      x$.writeHead(302, {
        Location: ravenLogOut
      });
      x$.end();
      return x$;
    } else {
      return next();
    }
  });
  function curry$(f, bound){
    var context,
    _curry = function(args) {
      return f.length > 1 ? function(){
        var params = args ? args.concat() : [];
        context = bound ? context || this : this;
        return params.push.apply(params, arguments) <
            f.length && arguments.length ?
          _curry.call(context, params) : f.apply(context, params);
      } : f;
    };
    return _curry();
  }
}).call(this);
