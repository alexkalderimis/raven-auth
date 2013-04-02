WlsResponse = require './wls-response'
get-redirect = require './auth-request'
handle-reply = require './handle-reply'

module.exports = (config) ->

    config.get-reply = WlsResponse.parse config.key-store, config.auth-types

    phase1 = handle-existing-session config
    phase2 = handle-reply config
    phase3 = authenticate config, get-redirect config.raven-url, config.auth-types

    (req, res, next) ->

        reply = req.query.WlsResponse
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
        session.message = 'Your existing session has timed out'
        return true
    else unless req.query.WlsResponse
        if session.post-data?
            req.body = session.post-data
        session.last = now
        next()
    false

