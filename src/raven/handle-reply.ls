redirect-err = (session, res, raven, message, code) -->
    session.message = message
    session.status-code = code
    raven.redirect res

module.exports = (config, reply, req, res) -->

    {max-session-life, ver, max-skew, read-reply, timeout} = config
    {session} = req
    raven-resp = read-reply reply
    redirect = redirect-err session, res, raven-resp
    iact = config.iact ? (-> '')
    now = new Date().getTime()

    if not raven-resp.is-valid()
        res.statusCode = 500
        res.end 'Cannot parse authentication response.', 'utf8'
    else if raven-resp.url isnt req.url
        res.statusCode = 500
        res.end 'URLs do not match', 'utf8'
    else if session? and session.principal? and session.principal isnt ''
        raven-resp.redirect res
    else if not session?.can-store
        res.statusCode = 500
        res.end 'Session storage unavailable', 'utf8'
    else
        session.id = raven-resp.id

        if raven-resp.ver isnt ver
            redirect "ERROR: wrong protocol version", 600
        else if raven-resp.status isnt 200
            err = 'ERROR: authentication failed - ' + raven-resp.status
            cause = if raven-resp.msg then ", #{ raven-resp.msg }" else ''
            redirect err + cause, raven-resp.status
        else if raven-resp.issued-at.getTime() > now + max-skew + 1
            redirect "ERROR: reply issued in the future?", 600
        else if now - max-skew - 1 > raven-resp.issued-at.getTime() + timeout
            redirect "ERROR: reply is stale", 600
        else unless raven-resp.is-acceptable
            redirect "ERROR: authentication method is unacceptable", 600
        else if iact(req) and not raven-resp.auth
            redirect 'ERROR: forced interaction request not honoured', 600
        else
            session <<< {
                status-code: 200
                issue: now
                last: now
                life: Math.min(max-session-life, raven-resp.life)
                id: raven-resp.id
                principal: raven-resp.principal
                params: raven-resp.params
            }

            raven-resp.redirect res

