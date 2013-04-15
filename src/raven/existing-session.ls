debug = require('debug') 'raven-auth:phase1'

module.exports = (config, req, reject, succeed, raven-resp) -->
    now = Date.now!
    {session} = req
    {timeout} = config
    {status-code, issue, last, expire, message} = session

    if status-code is 410
        reject 'You cancelled the authentication', 403
    else if status-code? and status-code isnt 200
        reject message, 500
    else if now? and (now < issue or now < last)
        reject 'Session initiated or last used in future?', 500
    else if now >= expire or now >= last + timeout
        debug "session timeout"
        delete session.principal
        session.message = 'Your existing session has timed out'
        return true
    else if session.principal? and not raven-resp?
        debug "auth succeeded"
        if session.post-data?
            debug "restoring post data: #{ session.post-data }"
            req.body = session.post-data
        session.last = now
        succeed!
    else
        debug "Need to parse response from raven"
        return true
    false

