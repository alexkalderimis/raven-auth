if (typeof window == 'undefined' || window === null) {
  require('prelude-ls').installPrelude(global);
} else {
  prelude.installPrelude(window);
}
(function(){
  var err;
  module.exports = curry$(function(config, req, res, next, ravenResp){
    var now, session, timeout, statusCode, issue, last, expire, message, reject;
    now = new Date().getTime();
    session = req.session;
    timeout = config.timeout;
    statusCode = session.statusCode, issue = session.issue, last = session.last, expire = session.expire, message = session.message;
    reject = err(res, session);
    if (statusCode === 410) {
      reject('You cancelled the authentication', 403);
    } else if (statusCode != null && statusCode !== 200) {
      reject(message, 500);
    } else if (now != null && (now < issue || now < last)) {
      reject('Session initiated or last used in future?', 500);
    } else if (now >= expire || now >= last + timeout) {
      debug("session timeout");
      delete session.principal;
      session.message = 'Your existing session has timed out';
      return true;
    } else if (session.principal != null && ravenResp == null) {
      debug("auth succeeded");
      if (session.postData != null) {
        req.body = session.postData;
      }
      session.last = now;
      next();
    } else {
      debug("Need to parse response from raven");
      return true;
    }
    return false;
  });
  err = curry$(function(res, session, message, code){
    debug(message);
    session.destroy();
    res.statusCode = code;
    return res.end(message, 'utf8');
  });
  function debug(){
    if (process.env.DEBUG) {
      console.log.apply(this, arguments);
    }
  }
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
