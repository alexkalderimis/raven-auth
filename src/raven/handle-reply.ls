class ReplyHandler

    (config, @req, @res) ->
        import config
        @now = new Date().getTime!
        @url = @local-host + (@req.url ? '').replace /\?.*$/, ''
        {@session} = @req
    
    parse-reply: (reply) ->
        try
            @raven-resp = @read-reply reply
        catch e
            @set-error 500, "Error: #{ e }\n#{ e.stack }"

    start-handling: ->
        | not @raven-resp                  => null
        | not @raven-resp.is-valid!        => @reject 'Invalid authentication response'
        | @raven-resp.url isnt @url        => @reject "#{ @raven-resp.url } is not #{ @url }"
        | @session?.principal is @raven-resp.principal => @accept!
        | not @session?.can-store          => @reject 'Session error'
        | otherwise                        => @init-session!

    init-session: ->

        # Now we reply by redirecting.
        @reply = @redirect

        [err, code = 600] = @check-resp!

        if err?
            @reject err, code
        else
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

    redirect: ->
        @session.message = @content
        @session.status-code = @status-code
        @raven-resp.redirect @res

    accept: ->
        @status-code = 200
        @content = 'Authenticated'

    reject: (msg, code = 500) ->
        debug msg
        @set-error code, "Error: #{ msg }"

    set-error: (@status-code, @content) ->

    iact: -> false

    reply: ->
        @res.status-code = @status-code
        @res.end @content, \utf8

    check-resp: ->

        [min-now, max-now] = [foldl f, @now, [@max-skew, 1] for f in [(-), (+)]]
        {ver, status, issued-at, is-acceptable, auth} = @raven-resp
        
        switch @raven-resp
            | ver isnt @ver            => ['wrong protocol version']
            | status isnt 200          =>
                let err = 'ERROR: authentication failed - ' + raven-resp.status
                    cause = if raven-resp.msg then ", #{ raven-resp.msg }" else ''
                    [err + cause, raven-resp.status]
            | issued-at > max-now      => ['reply issued in the future?']
            | issued-at < min-now      => ['reply is stale']
            | not is-acceptable        => ['authentication method is unacceptable']
            | @iact @req and not auth? => ['forced interaction request not honoured']
            | otherwise                => []

module.exports = (config, reply, req, res) -->
    handler = new ReplyHandler config, req, res
        ..parse-reply reply
        ..start-handling!
        ..reply!

!function debug
    console.log ... if process.env.DEBUG
