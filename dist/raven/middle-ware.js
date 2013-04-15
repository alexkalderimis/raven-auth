if (typeof window == 'undefined' || window === null) {
  require('prelude-ls').installPrelude(global);
} else {
  prelude.installPrelude(window);
}
(function(){
  var getRedirect, handleExistingSession, handleReply, authenticate, checkLogOut, Config, util;
  getRedirect = require('./auth-request');
  handleExistingSession = require('./existing-session');
  handleReply = require('./handle-reply');
  authenticate = require('./authenticate');
  checkLogOut = require('./log-out');
  Config = require('./config');
  util = require('util');
  module.exports = function(opts){
    var config, logOut, phase1, phase2, phase3, raven;
    config = new Config(opts);
    logOut = checkLogOut(config);
    phase1 = handleExistingSession(config);
    phase2 = handleReply(config);
    phase3 = authenticate(config, getRedirect(config));
    raven = function(req, res, next){
      var reply, session, proceed;
      reply = req.query['WLS-Response'];
      debug("Got reply " + reply);
      session = req.session;
      if (session != null) {
        debug(util.inspect(session));
      }
      debug("Entering phase 1");
      if (session != null && session.sentToRaven) {
        proceed = phase1(req, res, next, reply);
        debug("Can proceed?: " + proceed);
        if (!proceed) {
          return;
        }
      }
      debug("Entering phase 2");
      if (reply != null) {
        return phase2(reply, req, res);
      }
      debug("Entering phase 3");
      return phase3(req, res);
    };
    return function(req, res, next){
      return logOut(req, res, function(){
        return raven(req, res, next);
      });
    };
  };
  function debug(){
    if (process.env.DEBUG) {
      console.log.apply(this, arguments);
    }
  }
}).call(this);
