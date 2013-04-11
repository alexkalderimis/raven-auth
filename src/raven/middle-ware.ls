WlsResponse = require './wls-response'
get-redirect = require './auth-request'
handle-existing-session = require './existing-session'
handle-reply = require './handle-reply'
authenticate = require './authenticate'
check-log-out = require './log-out'

require! util

module.exports = (config) ->

    config.read-reply = WlsResponse.parse config.key-store, config.auth-types

    log-out = check-log-out config
    phase1 = handle-existing-session config
    phase2 = handle-reply config
    phase3 = authenticate config, get-redirect config

    raven = (req, res, next) ->

        reply = req.query['WLS-Response'] #.WlsResponse
        debug "Got reply #{ reply }"
        {session} = req
        debug util.inspect session if session?

        debug "Entering phase 1"
        if session?.sent-to-raven
            proceed = phase1 req, res, next, reply
            debug "Can proceed?: #{ proceed }"
            return unless proceed

        debug "Entering phase 2"
        if reply?
            return phase2 reply, req, res

        debug "Entering phase 3"
        phase3 req, res

    (req, res, next) -> log-out req, res, -> raven req, res, next

!function debug
    console.log ... if process.env.DEBUG

