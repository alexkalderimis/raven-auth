if (typeof window == 'undefined' || window === null) {
  require('prelude-ls').installPrelude(global);
} else {
  prelude.installPrelude(window);
}
(function(){
  var debug, ReplyHandler;
  debug = require('debug')('raven-auth:phase2');
  ReplyHandler = (function(){
    ReplyHandler.displayName = 'ReplyHandler';
    var prototype = ReplyHandler.prototype, constructor = ReplyHandler;
    function ReplyHandler(config, req, res){
      var ref$;
      this.req = req;
      this.res = res;
      this.maxSkew = config.maxSkew;
      this.ver = config.ver;
      this.maxSessionLife = config.maxSessionLife;
      this.readReply = config.readReply;
      this.localHost = config.localHost;
      if (config.iact != null) {
        this.iact = config.iact;
      }
      this.now = new Date().getTime();
      this.url = this.localHost + ((ref$ = this.req.url) != null ? ref$ : '').replace(/\?.*$/, '');
      this.session = this.req.session;
    }
    prototype.parseReply = function(reply){
      var e;
      try {
        return this.ravenResp = this.readReply(reply);
      } catch (e$) {
        e = e$;
        debug("Could not parse reply: " + e);
        return this.setError(500, "Error parsing reply from WLS: " + e + "\n" + e.stack);
      }
    };
    prototype.startHandling = function(){
      var p, ref$;
      switch (false) {
      case !!this.ravenResp:
        return null;
      case !!this.ravenResp.isValid():
        return this.reject('Invalid authentication response');
      case this.ravenResp.url === this.url:
        return this.reject("Wrong URL: " + this.ravenResp.url);
      case !((p = (ref$ = this.session) != null ? ref$.principal : void 8) && p === this.ravenResp.principal):
        return this.accept();
      case !!((ref$ = this.session) != null && ref$.canStore):
        return this.reject('Session error');
      default:
        return this.initSession();
      }
    };
    prototype.initSession = function(){
      var ref$, err, code, ref1$, life, id, principal, params;
      this.reply = this.redirect;
      ref$ = this.checkResp(), err = ref$[0], code = (ref1$ = ref$[1]) != null ? ref1$ : 600;
      if (err != null) {
        return this.reject(err, code);
      } else {
        ref$ = this.ravenResp, life = ref$.life, id = ref$.id, principal = ref$.principal, params = ref$.params;
        ref$ = this.session;
        ref$.issue = this.now;
        ref$.last = this.now;
        ref$.life = Math.min(this.maxSessionLife, life);
        ref$.id = id;
        ref$.principal = principal;
        ref$.params = params;
        return this.accept();
      }
    };
    prototype.redirect = function(){
      this.session.message = this.content;
      this.session.statusCode = this.statusCode;
      return this.ravenResp.redirect(this.res);
    };
    prototype.accept = function(){
      this.reply = this.redirect;
      this.statusCode = 200;
      return this.content = 'Authenticated';
    };
    prototype.reject = function(msg, code){
      code == null && (code = 500);
      debug(msg);
      return this.setError(code, "Error: " + msg);
    };
    prototype.setError = function(statusCode, content){
      this.statusCode = statusCode;
      this.content = content;
    };
    prototype.iact = function(){
      return false;
    };
    prototype.reply = function(){
      this.res.statusCode = this.statusCode;
      return this.res.end(this.content, 'utf8');
    };
    prototype.checkResp = function(){
      var f, ref$, minNow, maxNow, ver, status, issuedAt, isAcceptable, auth, msg;
      ref$ = (function(){
        var i$, ref$, len$, fn$ = curry$(function(x$, y$){
          return x$ - y$;
        }), fn1$ = curry$(function(x$, y$){
          return x$ + y$;
        }), results$ = [];
        for (i$ = 0, len$ = (ref$ = [fn$, fn1$]).length; i$ < len$; ++i$) {
          f = ref$[i$];
          results$.push(foldl(f, this.now, [this.maxSkew, 1000]));
        }
        return results$;
      }.call(this)), minNow = ref$[0], maxNow = ref$[1];
      ref$ = this.ravenResp, ver = ref$.ver, status = ref$.status, issuedAt = ref$.issuedAt, isAcceptable = ref$.isAcceptable, auth = ref$.auth, msg = ref$.msg;
      switch (false) {
      case ver === this.ver:
        debug('response version (%s) is not config version (%s)', ver, this.ver);
        return ['wrong protocol version'];
      case status === 200:
        return (function(err){
          var cause;
          cause = msg ? ", " + msg : '';
          return [err + cause, status];
        }.call(this, 'ERROR: authentication failed - ' + status));
      case !(issuedAt > maxNow):
        return ['reply issued in the future?'];
      case !(issuedAt < minNow):
        debug("issued at should be " + minNow + " .. " + maxNow);
        debug("reply was issued at " + issuedAt.getTime());
        return ['reply is stale'];
      case !!isAcceptable:
        return ['authentication method is unacceptable'];
      case !(this.iact(this.req) && auth == null):
        return ['forced interaction request not honoured'];
      default:
        return [];
      }
    };
    return ReplyHandler;
  }());
  module.exports = curry$(function(config, reply, req, res){
    var x$, handler;
    x$ = handler = new ReplyHandler(config, req, res);
    x$.parseReply(reply);
    x$.startHandling();
    x$.reply();
    return x$;
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
