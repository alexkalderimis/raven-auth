require! connect
raven = require '../raven'

port = process.env.PORT or 3001

key-store =
    | process.env.REAL_RAVEN => "#{ __dirname }/../../keys/raven"
    | otherwise              => "#{ __dirname }/../../keys/demo-server"

raven-host = if process.env.REAL_RAVEN then 'raven.cam.ac.uk' else 'demo.raven.cam.ac.uk'

raven-url     = "https://#{ raven-host }/auth/authenticate.html"
raven-log-out = "https://#{ raven-host }/auth/logout.html"

local-host = "http://localhost:#{ port }"
log-out-path = '/log-out'

ravenConf = {
    local-host, log-out-path,
    raven-log-out, raven-url, 
    key-store
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
