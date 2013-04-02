expect = require('chai').expect
require! [fs, crypto]
key-store = require '../key-store'

WlsResponse = require '../../raven/wls-response'

auth-types = [ \dummy ]

parse = WlsResponse.parse key-store, auth-types

to-reply = join \!

parse-reply = parse << to-reply

replace-only = (index, x) --> if x of index then index[x] else x

get-args = -> [
    2,
    200,
    'a message',
    \20130330T123456Z,
    \id,
    'http://some.url.org',
    \me,
    \dummy,
    '',
    \600,
    '',
]

sign-args = (args) ->
    s = crypto.createSign 'sha1'
    s.update to-reply args
    sig = s.sign key-store('priv'), 'base64'
    args.push \pub, sig
    args

get-signed-args = (sign-args << get-args)

let test = it

    describe 'Empty responses', ->

        var resp

        @beforeAll -> resp := parse null

        test 'should be invalid', -> expect(resp.is-valid()).to.be.false

    describe 'Unsigned response', ->

        var resp
        args = get-args! ++ [\pub, \invalid-signature]

        @beforeAll -> resp := parse-reply args

        test 'should be invalid', -> expect(resp.is-valid()).to.be.false

    describe 'A response missing a required part', ->
        var resp
        args = get-args! |> map replace-only {id: ''} |> sign-args

        @beforeAll -> resp := parse-reply args

        test 'should be invalid', -> expect(resp.is-valid()).to.be.false

    describe 'A 200 response without a principal', ->
        var resp
        args = get-args! |> map replace-only {me: ''} |> sign-args

        @beforeAll -> resp := parse-reply args

        test 'should be invalid', -> expect(resp.is-valid()).to.be.false

    describe 'A response with unacceptable auth', ->
        var resp
        args = get-args! |> map replace-only {dummy: 'foo'} |> sign-args

        @beforeAll -> resp := parse-reply args

        test 'should be invalid', -> expect(resp.is-valid()).to.be.false

    describe 'A valid response', ->

        var resp
        args = get-signed-args!

        @beforeAll -> resp := parse-reply args

        test 'should be valid', -> expect(resp.is-valid()).to.be.true

