require! connect
raven = require '../raven/middle-ware'

port = process.env.PORT or 3001

key-store =
    | process.env.REAL_RAVEN => require('../raven/key-store') "#{ __dirname }/../../keys/raven"
    | otherwise              =>
        let test-keys = require('./key-store')
            -> test-keys \pub

raven-host = if process.env.REAL_RAVEN then 'raven.cam.ac.uk' else 'demo.raven.cam.ac.uk'

raven-url     = "https://#{ raven-host }/auth/authenticate.html"
raven-log-out = "https://#{ raven-host }/auth/logout.html"

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
