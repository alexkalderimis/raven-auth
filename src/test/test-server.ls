require! connect
raven = require '../raven/middle-ware'

port = process.env.PORT or 3001

test-keys = require './key-store'
key-store = -> test-keys \pub
raven-url = 'https://demo.raven.cam.ac.uk/auth/authenticate.html'
raven-log-out = 'https://demo.raven.cam.ac.uk/auth/logout.html'
timeout = 60000
max-session-life = 24 * 60 * 60 * 1000
ver = 2
max-skew = 60000
auth-types = [ \pwd ]
local-host = "http://localhost:#{ port }"
log-out-path = '/log-out'

ravenConf = {
    log-out-path, raven-log-out,
    key-store, auth-types, raven-url, local-host,
    timeout, max-session-life, ver, max-skew
}

demo = (req, res, next) ->
    console.log "request to #{ req.url }"
    res
     ..setHeader 'Content-Type', 'text/html'
     ..write '<doctype! html><html><head></head><body>'
     ..write "<h1>Hey there #{ req.session.principal }</h1>"
     ..write '<p>Welcome to this demo</p>'
     ..write """<a href="#{ log-out-path }">Log out</a>"""
     ..write '</body></html>'
     ..end!

app = connect()
    ..use connect.logger \dev
    ..use connect.errorHandler!
    ..use connect.bodyParser!
    ..use connect.query!
    ..use connect.cookieParser!
    ..use connect.session secret: \raven-auth-testing
    ..use raven ravenConf
    ..use demo
    ..listen port

console.log "Listening on #{ port }"
