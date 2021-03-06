require! util
debug = require('debug') 'raven-auth:middle-ware'

get-redirect = require './auth-request'
handle-existing-session = require './existing-session'
handle-reply = require './handle-reply'
authenticate = require './authenticate'
check-log-out = require './log-out'
Config = require './config'

module.exports = (opts) ->

    config = new Config opts

    log-out = check-log-out config
    phase1 = handle-existing-session config
    phase2 = handle-reply config
    phase3 = authenticate config, get-redirect config

    raven = (req, res, next) ->

        reply = req.query['WLS-Response']
        debug "Got reply #{ reply }"
        {session} = req
        debug session

        fail = config.fail req, res
        redirect = config.redirect req, res

        debug "Entering phase 1"
        if session?.sent-to-raven
            proceed = phase1 req, fail, next, reply
            debug "Can proceed?: #{ proceed }"
            return unless proceed

        debug "Entering phase 2"
        if reply?
            return phase2 reply, req, fail, redirect

        debug "Entering phase 3"
        phase3 req, redirect

    (req, res, next) -> log-out req, res, -> raven req, res, next

