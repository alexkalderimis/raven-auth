WlsResponse = require './wls-response'
get-redirect = require './auth-request'
handle-existing-session = require './existing-session'
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


