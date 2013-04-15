if (typeof window == 'undefined' || window === null) {
  require('prelude-ls').installPrelude(global);
} else {
  prelude.installPrelude(window);
}
(function(){
  var debug;
  debug = require('debug')('raven-auth:authenticate');
  module.exports = curry$(function(config, toAuthReq, req, res){
    var session, msg, desc, Location;
    session = req.session;
    session.canStore = true;
    session.sentToRaven = true;
    if (req.method !== 'GET') {
      session.postData = req.body;
    }
    debug("Saved request body: " + JSON.stringify(req.body));
    msg = typeof config.getMsg === 'function' ? config.getMsg(req) : void 8;
    desc = typeof config.getDesc === 'function' ? config.getDesc(req) : void 8;
    Location = toAuthReq({
      req: req,
      msg: msg,
      desc: desc
    });
    debug("Redirecting to " + Location);
    res.writeHead(302, {
      Location: Location
    });
    return res.end();
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
