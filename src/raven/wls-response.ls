not-there = (x) -> not x? or empty x

required-parts = [\ver \status \issued-at \id \url]

DATE_RE = /(\d{4})(\d{2})(\d{2})T(\d{2})(\d{2})(\d{2})Z/

parse-date = (date-string) ->
    parts = [+x for x in drop 1, DATE_RE.exec date-string]
    new Date ...parts

module.exports = class WlsResponse

    (auth-types, [@ver, stat, @msg, issue, @id, @url, @principal,
      @auth, sso, life, @params, @kid, @sig]) ->
        @status = +stat
        @issued-at = parse-date issue
        @previousAuth = sso.split ','
        @life = +life
        @acceptable = [] ++ (auth-types ? [])

    is-valid: ->
        parts-ok = andList [@[x]? for x in required-parts]
        princ-ok = if @status is 200 then @principal? else not-there @principal
        auth-ok = (not empty @auth and @auth in @acceptable) or not empty @previousAuth
        sig-ok = @status isnt 200 or (@sig? and @kid?)
        andList [parts-ok, princ-ok, auth-ok, sig-ok]

    @parse = (auth-types, source) -->
        | not source => new NoResponse
        | otherwise  => new WlsResponse auth-types, source / \!

class NoResponse extends WlsResponse

    ->

    is-valid: -> false

