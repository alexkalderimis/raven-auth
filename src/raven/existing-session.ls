module.exports = (config, req, res, next) -->
    now = new Date().getTime()
    {session} = req
    {timeout} = config
    {status-code, issue, last, expire, message} = session

    if status-code is 410
        req.session = null
        res.statusCode = 403
        res.end 'You cancelled the authentication', 'utf8'
    else if status-code isnt 200
        req.session = null
        res.statusCode = 500
        res.end message, 'utf8'
    else if now < issue or now < last
        req.session = null
        res.statusCode = 500
        res.end 'Session initiated or last used in future?', 'utf8'
    else if now >= expire or now >= last + timeout
        session.principal = ''
        session.message = 'Your existing session has timed out'
        return true
    else unless req.query.WlsResponse
        if session.post-data?
            req.body = session.post-data
        session.last = now
        next()
    false
