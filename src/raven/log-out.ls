debug = require('debug') 'raven-auth:log-out'

module.exports = ({log-out-path, raven-log-out}, req, res, next) -->
    if log-out-path? and req.url.match log-out-path
        debug "Logging out"
        req.session.destroy!
        res
          ..writeHead 302, Location: raven-log-out
          ..end!
    else
        next!

