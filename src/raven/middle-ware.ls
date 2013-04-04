WlsResponse = require './wls-response'
get-redirect = require './auth-request'
handle-existing-session = require './existing-session'
handle-reply = require './handle-reply'
authenticate = require './authenticate'
check-log-out = require './log-out'

module.exports = (config) ->

    config.read-reply = WlsResponse.parse config.key-store, config.auth-types

    log-out = check-log-out config
    phase1 = handle-existing-session config
    phase2 = handle-reply config
    phase3 = authenticate config, get-redirect config

    raven = (req, res, next) ->

        reply = req.query.WlsResponse
        {session} = req

        if session?.sent-to-raven
            proceed = phase1 req, res, next
            return unless proceed

        if reply?
            return phase2 config, reply, req, res

        phase3 req, res

    (req, res, next) -> log-out req, res, -> raven req, res, next


