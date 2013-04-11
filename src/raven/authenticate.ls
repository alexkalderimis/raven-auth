module.exports = (config, to-auth-req, req, res) -->
    {session} = req
    session.can-store = true
    session.sent-to-raven = true
    session.post-data = req.body if req.method isnt \GET
    msg = config.get-msg? req
    desc = config.get-desc? req
    Location = to-auth-req {req, msg, desc}
    console.log "Redirecting to #{ Location }" if process.env.DEBUG
    res.writeHead 302, {Location}
    res.end()

