debug = require('debug') 'raven-auth:authenticate'

module.exports = (config, to-auth-req, req, res) -->
    {session} = req
    session.can-store = true
    session.sent-to-raven = true
    session.post-data = req.body if req.method isnt \GET
    debug "Saved request body: #{ JSON.stringify req.body }"
    msg = config.get-msg? req
    desc = config.get-desc? req
    Location = to-auth-req {req, msg, desc}
    debug "Redirecting to #{ Location }" 
    res.writeHead 302, {Location}
    res.end()

