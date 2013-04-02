expect = require('chai').expect

Request = require '../request'
Response = require '../response'
timeout = 5000

phase1 = {timeout} |> require '../../raven/existing-session'

now = (offset = 0) -> new Date().get-time! + offset

class Next

    called: false

    next: -> @called = true

let test = it

    middleware-test = (session, exp-sess, code, content, called-next, should-go, f) ->  ->

        req = new Request {session}
        res = new Response
        next = new Next
        var go-on

        @beforeAll -> go-on := phase1 req, res, next~next

        test "the session should #{if exp-sess then 'not ' else ''}have been deleted", ->
            expect(req.session).to[if exp-sess then 'not' else 'be']equal null

        if code?
            test "the response should be #{ code }", ->
                expect(res.statusCode).to.equal code

        if content?
            test "the response content should match #{ content }", ->
                expect(res.content).to.match content

        test "next should #{ if called-next then '' else 'not '}have been called", ->
            expect(next.called).to.equal called-next

        test "we should #{ if should-go then '' else 'not ' }go on", ->
            expect(go-on).to.equal should-go

        f?( req, res, next )

    phase1-failure = (session, code, content) ->
        middleware-test session, false, code, content, false, false

    issue = now -1000
    last = now -500
    status-code = 200
    expire = now 10000
    good-session = -> {status-code, issue, last, expire, post-data: 'somedata=foo'}

    describe 'Cancelled authentication',
        phase1-failure {status-code: 410}, 403, /cancelled/

    describe 'Redirected failure',
        phase1-failure {status-code: 400, message: 'oh noes!'}, 500, /noes/

    describe 'Session from the future',
        phase1-failure {status-code, issue: now 1000}, 500, /future/

    describe 'Last used in the future',
        phase1-failure {status-code, issue, last: now(1000)}, 500, /future/

    describe 'Expired session',
        middleware-test {status-code, issue, last, expire: now(-10), principal: \foo}, true, null, null, false, true, (req) ->
            test 'Should have an empty principal', ->
                expect(req.session.principal).to.equal ''

            test 'Should store a message about session expiry', ->
                expect(req.session.message).to.match /timed out/

    describe 'Successful authentication',
        middleware-test good-session!, true, null, null, true, false, (req, res, next) ->

            test 'Post data was transferred', ->
                expect(req.body).to.equal req.session.post-data

            test 'Last use was updated', ->
                expect(req.session.last).to.be.within now(-100), now!



