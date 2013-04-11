module.exports = (config, req, res, next, raven-resp) -->
    now = new Date().getTime()
    {session} = req
    {timeout} = config
    {status-code, issue, last, expire, message} = session

    if status-code is 410
        debug "Auth cancelled"
        req.session = null
        res.statusCode = 403
        res.end 'You cancelled the authentication', 'utf8'
    else if status-code? and status-code isnt 200
        debug "Auth failed"
        req.session = null
        res.statusCode = 500
        res.end message, 'utf8'
    else if now? and (now < issue or now < last)
        debug "Invalid session time"
        req.session = null
        res.statusCode = 500
        res.end 'Session initiated or last used in future?', 'utf8'
    else if now >= expire or now >= last + timeout
        debug "session timeout"
        session.principal = ''
        session.message = 'Your existing session has timed out'
        return true
    else if session.principal? and not raven-resp?
        debug "auth succeeded"
        if session.post-data?
            req.body = session.post-data
        session.last = now
        next!
    else
        debug "Need to parse response from raven"
        return true
    false

!function debug
    console.log ... if process.env.DEBUG
