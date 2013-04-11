require! crypto
require! qs

not-there = (x) -> not x? or empty x

exists = (x) -> !! (x? and (not x.length? or not empty x))

required-parts = [\ver \status \issuedAt \id \url]

# Dates come as: 20130411T184130Z => Thu Apr 11 18:41:30 UTC 2013

DATE_RE = /(\d{4})(\d{2})(\d{2})T(\d{2})(\d{2})(\d{2})Z/

parse-date = (str) ->
    | DATE_RE.test(str) =>
        let [y, mon, d, h, min, s] = [+x for x in drop 1, DATE_RE.exec str]
            time                 = Date.UTC y, mon - 1, d, h, min, s
            new Date time
    | otherwise         => null

SIG_RE = /(_|\.|-)/g
re-sig = [[\- \+], [\. \/], [\_ \=]] |> listToObj |> objToFunc

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
        @sig = sig?.replace SIG_RE, re-sig
        @signed-data = take (parts.length - 2), parts |> (.join \!)

    is-valid: ->
        [\parts \princ \auth \sig] |> map ((+ \Ok) >> ~> @[it]!) |> andList

    parts-ok: -> andList [exists @[x] for x in required-parts]

    princ-ok: -> if @status is 200 then exists @principal else not-there @principal

    auth-ok: -> @is-acceptable and ((not empty @auth) or (not empty @previousAuth))

    sig-ok: -> @status isnt 200 or (@sig? and @key? and @sig-matches-content())

    sig-matches-content: ->
        console.log @sig, @signed-data if process.env.DEBUG
        v = crypto.createVerify 'sha1'
        v.update @signed-data
        v.verify(@key, @sig, 'base64')

    redirect: (res) ->
        res.writeHead 302, Location: @url
        res.end()

    @parse = (key-store, auth-types, source) -->
        | not source => new NoResponse
        | otherwise  => new WlsResponse key-store, auth-types, source / \!

class NoResponse extends WlsResponse

    ->
        console.log "NO RESPONSE" if process.env.DEBUG

    is-valid: -> false

!function debug
    console.log ... if process.env.DEBUG
