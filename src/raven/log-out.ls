module.exports = ({log-out-path, raven-log-out}, req, res, next) -->
    if log-out-path? and req.url.match log-out-path
        req.session = null
        res
          ..writeHead 302, Location: raven-log-out
          ..end!
    else
        next!

