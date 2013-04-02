WlsResponse = require './wls-response'
get-redirect = require './auth-request'
handle-existing-session = require './existing-session'
handle-reply = require './handle-reply'
authenticate = require './authenticate'

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


