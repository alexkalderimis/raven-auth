WlsResponse = require './raven-response'
get-redirect = require './auth-request'

redirect-err = (session, res, raven, message, code) -->
    session.message = message
    session.status-code = code
    raven.redirect res

module.exports = (config) ->

    config.get-reply = WlsResponse.parse config.key-store, config.auth-types

    phase1 = handle-existing-session config
    phase2 = handle-reply config
    phase3 = authenticate config, get-redirect config.raven-url, config.auth-types

    (req, res, next) ->

        reply = res.query.WlsResponse
        {session} = req

        if session?
            proceed = phase1 req, res, next
            return unless proceed

        if reply?
            return phase2 config, reply, req, res

        phase3 req, res

authenticate = (config, to-auth-req, req, res) -->
    {session} = req
    session.can-store = true
    session.post-data = req.body if req.method isnt 'GET'
    msg = config.get-msg? req
    desc = config.get-desc? req
    Location = to-auth-req {req, msg, desc}
    res.writeHead 302, {Location}
    res.end()

handle-existing-session = (config, req, res, next) -->
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
        message = 'Your existing session has timed out'
        return true
    else unless reply?
        if session.post-data?
            req.body = session.post-data
        session.last = now
        next()
    false

handle-reply = (config, reply, req, res) -->

    redirect = redirect-err session, res, raven-resp
    {max-session-life, ver, iact, max-skew, read-reply, timeout} = config
    iact ?= -> ''
    raven-resp = read-reply reply
    now = new Date().getTime()
    {session} = req

    if not raven-resp.is-valid()
        res.statusCode = 500
        res.end 'Cannot parse authentication response.', 'utf8'
    else if raven-resp.url isnt req.url
        res.statusCode = 500
        res.end 'URLs do not match', 'utf8'
    else if session? and session.principal isnt ''
        raven-resp.redirect res
    else unless session?.can-store
        res.statusCode = 500
        res.end 'Session storage unavailable', 'utf8'
    else
        session.id = raven-resp.id

        if raven-resp.ver isnt ver
            redirect "ERROR: wrong protocol version", 600
        else if raven-resp.status isnt 200
            err = 'ERROR: authentication failed - ' + raven-resp.status
            if raven-resp.msg
                err += ", #{ raven-resp.msg }"
            redirect err, raven-resp.status
        else if raven-resp.issued-at.getTime() > now + max-skew + 1
            redirect "ERROR: reply issued in the future?", 600
        else if now - max-skew - 1 > raven-resp.issued-at.getTime() + timeout
            redirect "ERROR: reply is stale", 600
        else unless raven-resp.is-acceptable
            redirect "ERROR: authentication method is unacceptable", 600
        else if iact(req) and not raven-resp.auth
            redirect 'ERROR: forced interaction request not honoured', 600
        else
            session << {
                status-code: 200
                issue: now
                last: now
                life: Math.min(max-session-life, raven-resp.life)
                id: raven-resp.id
                principal: raven-resp.principal
                params: raven-resp.params
            }

            raven-resp.redirect res














