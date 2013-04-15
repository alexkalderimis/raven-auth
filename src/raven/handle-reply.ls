debug = require('debug') 'raven-auth:phase2'

class ReplyHandler

    (config, @req, @fail, @redirect) ->
        import config{max-skew, ver, max-session-life, read-reply, local-host}
        @iact = config.iact if config.iact?
        @now = new Date().getTime!
        @url = @local-host + (@req.url ? '').replace /\?.*$/, ''
        {@session} = @req

    parse-reply: (reply) ->
        try
            @raven-resp = @read-reply reply
        catch e
            debug "Could not parse reply: #{ e }"
            @set-error 500, "Error parsing reply from WLS: #{ e }\n#{ e.stack }"

    start-handling: ->
        | not @raven-resp           => null
        | not @raven-resp.is-valid! => @reject 'Invalid authentication response', 500
        | @raven-resp.url isnt @url => @reject "Wrong URL: #{ @raven-resp.url }", 500
        | (p = @session?.principal) and p is @raven-resp.principal => @accept!
        | not @session?.can-store          => @reject 'Session error', 500
        | otherwise                        => @check-resp!

    check-resp: ->

        # From this point on we defer the message to the end destination
        @reply = @sendToEndDestination

        [min-now, max-now] = [foldl f, @now, [@max-skew, 1000sec] for f in [(-), (+)]]
        {ver, status, issued-at, is-acceptable, auth, msg} = @raven-resp

        switch
            | ver isnt @ver            => @reject "wrong protocol version (#{ ver })"
            | status isnt 200          =>
                err = 'ERROR: authentication failed - ' + status
                cause = if msg then ", #{ msg }" else ''
                @reject err + cause, status
            | issued-at > max-now      => @reject 'reply issued in the future?'
            | issued-at < min-now      => @reject 'reply is stale'
            | not is-acceptable        => @reject 'Authentication method is unacceptable'
            | @iact @req and not auth? => @reject 'Authentication was not interactive'
            | otherwise                => @init-session!

    init-session: ->
        {life, id, principal, params} = @raven-resp
        @session <<< {
            issue: @now
            last: @now
            life: Math.min(@max-session-life, life)
            id
            principal
            params
        }
        @accept!

    sendToEndDestination: ->
        @session.message = @content
        @session.status-code = @status-code
        @redirect @raven-resp.url

    accept: ->
        @reply = @sendToEndDestination
        @status-code = 200
        @content = 'Authenticated'

    reject: (msg, code = 600) ->
        debug msg
        @set-error code, "Error: #{ msg }"

    set-error: (@status-code, @content) ->

    iact: -> false

    reply: -> @fail @content, @status-code

module.exports = (config, reply, req, fail, redirect) -->
    handler = new ReplyHandler config, req, fail, redirect
        ..parse-reply reply
        ..start-handling!
        ..reply!

