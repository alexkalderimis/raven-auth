key-store = require './key-store'
WlsResponse = require './wls-response'
debug = require('debug') 'raven-auth:config'

class Config

    (opts) ->
        import opts
        if @key-store?.substring? # Promote to func
            dir = @key-store
            debug 'Loading keys from %s', dir
            @key-store = key-store dir
        throw new Error("No keyStore provided") unless @key-store?
        throw new Error("No localHost provided") unless @local-host?
        @read-reply = WlsResponse.parse @key-store, @auth-types

    raven-url: 'https://raven.cam.ac.uk/auth/authenticate.html'
    raven-log-out: 'https://raven.cam.ac.uk/auth/logout.html'
    timeout: 60_000ms
    max-session-life: 24hrs * 60min * 60sec * 1000ms
    ver: 2
    max-skew: 1sec
    auth-types: [ \pwd ]

module.exports = Config
