require! [crypto, qs, debug, util]
log = debug 'raven-auth:wls-response'

not-there = (x) -> not x? or empty x

exists = (x) -> !! (x? and (not x.length? or not empty x))

required-parts = [\ver \status \issuedAt \id \url]

# Dates come as: 20130411T184130Z => Thu Apr 11 18:41:30 UTC 2013

DATE_RE = /^(\d{4})(\d{2})(\d{2})T(\d{2})(\d{2})(\d{2})Z$/

parse-date = (str) ->
    | DATE_RE.test(str) =>
        let [y, mon, d, h, min, s] = [+x for x in drop 1, DATE_RE.exec str]
            time                 = Date.UTC y, mon - 1, d, h, min, s
            new Date time
    | otherwise         => null

SIG_RE = /(_|\.|-)/g
sig-tr = [[\- \+], [\. \/], [\_ \=]] |> listToObj |> objToFunc
sig-decode = -> it?.replace SIG_RE, sig-tr

module.exports = class WlsResponse

    (key-store, auth-types, [ver, stat, @msg, issue, @id, url, @principal,
      @auth, sso, life, @params, @kid, sig]:parts) ->
        @ver = +ver
        @url = qs.parse("url=#{ url }").url
        @status = +stat
        @issued-at = parse-date issue
        @previousAuth = (sso ? '').split \,
        @life = +life
        @acceptable = acceptable = (auth-types ? []).slice!
        @is-acceptable = orList map (in acceptable), @previousAuth ++ [@auth]
        @key = key-store(@kid) if @kid
        @sig = sig-decode sig
        @signed-data = take (parts.length - 2), parts |> (.join \!)
        log "Parsed response: #{ util.inspect @ }"

    is-valid: -> [\parts \princ \auth \sig] |> map ((+ \Ok) >> ~> @[it]!) |> andList

    parts-ok: -> andList [exists @[x] for x in required-parts]

    princ-ok: -> if @status is 200 then exists @principal else not-there @principal

    auth-ok: -> @is-acceptable and ((not empty @auth) or (not empty @previousAuth))

    sig-ok: -> @status isnt 200 or (@sig? and @key? and @sig-matches-content())

    sig-matches-content: ->
        log @sig, @signed-data
        v = crypto.createVerify 'sha1'
                 ..update @signed-data
        ok = v.verify(@key, @sig, 'base64')
        log "Signature verification #{ if ok then 'succeeded' else 'failed' }"
        ok

    redirect: (res) ->
        log "Redirecting to #{ @url }"
        res.writeHead 302, Location: @url
        res.end()

    @parse = (key-store, auth-types, source) -->
        | not source => new NoResponse
        | otherwise  => new WlsResponse key-store, auth-types, source / \!

class NoResponse extends WlsResponse

    -> log 'NO RESPONSE'

    is-valid: -> false

