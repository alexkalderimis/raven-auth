require! [express, passport, debug]

log = debug 'raven:express-test-server'
port = process.env.PORT or 3001

raven = require '../raven'

key-store =
    | process.env.REAL_RAVEN => "#{ __dirname }/../../keys/raven"
    | otherwise              => "#{ __dirname }/../../keys/demo-server"

raven-host = if process.env.REAL_RAVEN then 'raven.cam.ac.uk' else 'demo.raven.cam.ac.uk'

raven-url     = "https://#{ raven-host }/auth/authenticate.html"
raven-log-out = "https://#{ raven-host }/auth/logout.html"

local-host = "http://localhost:#{ port }"
log-out-path = '/log-out'
verify = (crsid, done) ->
    log "Successful log in by #{ crsid }"
    done null, crsid

ravenConf = {
    local-host, log-out-path,
    raven-log-out, raven-url,
    key-store, verify
}

app = express()

passport.serializeUser (user, done) ->
    log "Serialising #{ user }"
    done null, user

passport.deserializeUser (id, done) ->
    log "Deserialising #{ id }"
    done null, id

passport.use raven.strategy ravenConf

app.configure ->
  app.use express.logger \dev
  app.use express.static(__dirname + '/../../public')
  app.use express.cookieParser()
  app.use express.bodyParser()
  app.use express.session({ secret: 'keyboard cat' })
  app.use passport.initialize!
  app.use passport.session!

app.get '/', (req, res) ->
    res
      ..setHeader 'Content-Type', 'text/plain'
      ..write "I have no idea who you are"
      ..end!

app.get '/:foo', passport.authenticate(\raven, {failureRedirect: '/'}), (req, res) ->
    res
      ..setHeader 'Content-Type', 'text/plain'
      ..write "Hello to #{ req.params.foo }, #{ req.user }"
      ..end!

app.listen port
