if (typeof window == 'undefined' || window === null) {
  require('prelude-ls').installPrelude(global);
} else {
  prelude.installPrelude(window);
}
(function(){
  var qs, serialiseDate;
  qs = require('qs');
  serialiseDate = function(date){
    return date.toISOString().replace(/[:\.-]/g, '');
  };
  module.exports = curry$(function(config, arg$){
    var req, desc, msg, fail, ref$, ver, ravenUrl, authTypes, localHost, date, url, params, aauth;
    req = arg$.req, desc = arg$.desc, msg = arg$.msg, fail = (ref$ = arg$.fail) != null ? ref$ : 'yes', ver = (ref$ = arg$.ver) != null ? ref$ : 2;
    ravenUrl = config.ravenUrl, authTypes = config.authTypes, localHost = config.localHost;
    date = serialiseDate(new Date());
    url = localHost + req.url;
    params = '';
    aauth = (authTypes != null
      ? authTypes
      : []).join(',');
    return ravenUrl + '?' + qs.stringify({
      ver: ver,
      url: url,
      desc: desc,
      aauth: aauth,
      msg: msg,
      params: params,
      date: date,
      fail: fail
    });
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
