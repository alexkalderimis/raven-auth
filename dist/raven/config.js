if (typeof window == 'undefined' || window === null) {
  require('prelude-ls').installPrelude(global);
} else {
  prelude.installPrelude(window);
}
(function(){
  var keyStore, WlsResponse, debug, Config;
  keyStore = require('./key-store');
  WlsResponse = require('./wls-response');
  debug = require('debug')('raven-auth:config');
  Config = (function(){
    Config.displayName = 'Config';
    var prototype = Config.prototype, constructor = Config;
    function Config(opts){
      var ref$, dir;
      import$(this, opts);
      if (((ref$ = this.keyStore) != null ? ref$.substring : void 8) != null) {
        dir = this.keyStore;
        debug('Loading keys from %s', dir);
        this.keyStore = keyStore(dir);
      }
      if (this.keyStore == null) {
        throw new Error("No keyStore provided");
      }
      if (this.localHost == null) {
        throw new Error("No localHost provided");
      }
      this.readReply = WlsResponse.parse(this.keyStore, this.authTypes);
    }
    prototype.ravenUrl = 'https://raven.cam.ac.uk/auth/authenticate.html';
    prototype.ravenLogOut = 'https://raven.cam.ac.uk/auth/logout.html';
    prototype.timeout = 60000;
    prototype.maxSessionLife = 24 * 60 * 60 * 1000;
    prototype.ver = 2;
    prototype.maxSkew = 1000;
    prototype.authTypes = ['pwd'];
    return Config;
  }());
  module.exports = Config;
  function import$(obj, src){
    var own = {}.hasOwnProperty;
    for (var key in src) if (own.call(src, key)) obj[key] = src[key];
    return obj;
  }
}).call(this);
