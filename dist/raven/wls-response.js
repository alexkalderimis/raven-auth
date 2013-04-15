if (typeof window == 'undefined' || window === null) {
  require('prelude-ls').installPrelude(global);
} else {
  prelude.installPrelude(window);
}
(function(){
  var crypto, qs, debug, util, log, notThere, exists, requiredParts, DATE_RE, parseDate, SIG_RE, sigTr, sigDecode, WlsResponse, NoResponse, split$ = ''.split;
  crypto = require('crypto');
  qs = require('qs');
  debug = require('debug');
  util = require('util');
  log = debug('raven-auth:wls-response');
  notThere = function(x){
    return x == null || empty(x);
  };
  exists = function(x){
    return !!(x != null && (x.length == null || !empty(x)));
  };
  requiredParts = ['ver', 'status', 'issuedAt', 'id', 'url'];
  DATE_RE = /^(\d{4})(\d{2})(\d{2})T(\d{2})(\d{2})(\d{2})Z$/;
  parseDate = function(str){
    var x;
    switch (false) {
    case !DATE_RE.test(str):
      return (function(arg$){
        var y, mon, d, h, min, s, time;
        y = arg$[0], mon = arg$[1], d = arg$[2], h = arg$[3], min = arg$[4], s = arg$[5];
        time = Date.UTC(y, mon - 1, d, h, min, s);
        return new Date(time);
      }.call(this, (function(){
        var i$, ref$, len$, results$ = [];
        for (i$ = 0, len$ = (ref$ = drop(1, DATE_RE.exec(str))).length; i$ < len$; ++i$) {
          x = ref$[i$];
          results$.push(+x);
        }
        return results$;
      }())));
    default:
      return null;
    }
  };
  SIG_RE = /(_|\.|-)/g;
  sigTr = objToFunc(
  listToObj(
  [['-', '+'], ['.', '/'], ['_', '=']]));
  sigDecode = function(it){
    return it != null ? it.replace(SIG_RE, sigTr) : void 8;
  };
  module.exports = WlsResponse = (function(){
    WlsResponse.displayName = 'WlsResponse';
    var prototype = WlsResponse.prototype, constructor = WlsResponse;
    function WlsResponse(keyStore, authTypes, parts){
      var ver, stat, issue, url, sso, life, sig, acceptable;
      ver = parts[0], stat = parts[1], this.msg = parts[2], issue = parts[3], this.id = parts[4], url = parts[5], this.principal = parts[6], this.auth = parts[7], sso = parts[8], life = parts[9], this.params = parts[10], this.kid = parts[11], sig = parts[12];
      this.ver = +ver;
      this.url = qs.parse("url=" + url).url;
      this.status = +stat;
      this.issuedAt = parseDate(issue);
      this.previousAuth = (sso != null ? sso : '').split(',');
      this.life = +life;
      this.acceptable = acceptable = (authTypes != null
        ? authTypes
        : []).slice();
      this.isAcceptable = orList(map((function(it){
        return in$(it, acceptable);
      }), this.previousAuth.concat([this.auth])));
      if (this.kid) {
        this.key = keyStore(this.kid);
      }
      this.sig = sigDecode(sig);
      this.signedData = function(it){
        return it.join('!');
      }(
      take(parts.length - 2, parts));
      log("Parsed response: " + util.inspect(this));
    }
    prototype.isValid = function(){
      var this$ = this;
      return andList(
      map(compose$([
        function(it){
          return this$[it]();
        }, (function(it){
          return it + 'Ok';
        })
      ]))(
      ['parts', 'princ', 'auth', 'sig']));
    };
    prototype.partsOk = function(){
      var x;
      return andList((function(){
        var i$, ref$, len$, results$ = [];
        for (i$ = 0, len$ = (ref$ = requiredParts).length; i$ < len$; ++i$) {
          x = ref$[i$];
          results$.push(exists(this[x]));
        }
        return results$;
      }.call(this)));
    };
    prototype.princOk = function(){
      if (this.status === 200) {
        return exists(this.principal);
      } else {
        return notThere(this.principal);
      }
    };
    prototype.authOk = function(){
      return this.isAcceptable && (!empty(this.auth) || !empty(this.previousAuth));
    };
    prototype.sigOk = function(){
      return this.status !== 200 || (this.sig != null && this.key != null && this.sigMatchesContent());
    };
    prototype.sigMatchesContent = function(){
      var x$, v, ok;
      log(this.sig, this.signedData);
      x$ = v = crypto.createVerify('sha1');
      x$.update(this.signedData);
      ok = v.verify(this.key, this.sig, 'base64');
      log("Signature verification " + (ok ? 'succeeded' : 'failed'));
      return ok;
    };
    prototype.redirect = function(res){
      log("Redirecting to " + this.url);
      res.writeHead(302, {
        Location: this.url
      });
      return res.end();
    };
    WlsResponse.parse = curry$(function(keyStore, authTypes, source){
      switch (false) {
      case !!source:
        return new NoResponse;
      default:
        return new WlsResponse(keyStore, authTypes, split$.call(source, '!'));
      }
    });
    return WlsResponse;
  }());
  NoResponse = (function(superclass){
    var prototype = extend$((import$(NoResponse, superclass).displayName = 'NoResponse', NoResponse), superclass).prototype, constructor = NoResponse;
    function NoResponse(){
      log('NO RESPONSE');
    }
    prototype.isValid = function(){
      return false;
    };
    return NoResponse;
  }(WlsResponse));
  function in$(x, arr){
    var i = -1, l = arr.length >>> 0;
    while (++i < l) if (x === arr[i] && i in arr) return true;
    return false;
  }
  function compose$(fs){
    return function(){
      var i, args = arguments;
      for (i = fs.length; i > 0; --i) { args = [fs[i-1].apply(this, args)]; }
      return args[0];
    };
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
  function extend$(sub, sup){
    function fun(){} fun.prototype = (sub.superclass = sup).prototype;
    (sub.prototype = new fun).constructor = sub;
    if (typeof sup.extended == 'function') sup.extended(sub);
    return sub;
  }
  function import$(obj, src){
    var own = {}.hasOwnProperty;
    for (var key in src) if (own.call(src, key)) obj[key] = src[key];
    return obj;
  }
}).call(this);
