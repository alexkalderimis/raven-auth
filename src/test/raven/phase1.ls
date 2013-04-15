expect = require('chai').expect

Request = require '../request'
CallTracker = require '../call-tracker'
timeout = 5000

phase1 = {timeout} |> require '../../raven/existing-session'

now = (offset = 0) -> new Date().get-time! + offset

class Session
    (vals) -> import vals

    destroy: -> @destroyed = true

let test = it

    describe 'Phase 1:', ->

        mwt = (session, should-fail, code, content, called-next, should-go, f) ->  ->

            req = new Request {session: new Session(session)}
            succeed = new CallTracker
            fail = new CallTracker

            var go-on

            @beforeAll -> go-on := phase1 req, fail~call, succeed~call, null

            test "Fail should #{if should-fail then '' else 'not '}have been called", ->
                expect(fail.called).to.equal should-fail

            if code?
                test "the response should be #{ code }", ->
                    expect(fail.args[1]).to.equal code

            if content?
                test "the response content should match #{ content }", ->
                    expect(fail.args[0]).to.match content

            test "next should #{ if called-next then '' else 'not '}have been called", ->
                expect(succeed.called).to.equal called-next

            test "we should #{ if should-go then '' else 'not ' }go on", ->
                expect(go-on).to.equal should-go

            f?( req, fail, succeed )

        phase1-failure = (session, code, content) ->
            mwt session, true, code, content, false, false

        issue = now -1000
        last = now -500
        status-code = 200
        expire = now 10000
        principal = \corvus
        good-session = -> {
            principal, status-code, issue, last, expire, post-data: 'somedata=foo'
        }

        describe 'Cancelled authentication',
            phase1-failure {status-code: 410}, 403, /cancelled/

        describe 'Redirected failure',
            phase1-failure {status-code: 400, message: 'oh noes!'}, 500, /noes/

        describe 'Session from the future',
            phase1-failure {status-code, issue: now 1000}, 500, /future/

        describe 'Last used in the future',
            phase1-failure {status-code, issue, last: now(1000)}, 500, /future/

        let sess = {status-code, issue, last, expire: now(-10), principal: \foo}
            describe 'Expired session', mwt sess, false, null, null, false, true, (req) ->
                test 'Should have an empty principal', ->
                    expect(req.session.principal).to.not.exist

                test 'Should store a message about session expiry', ->
                    expect(req.session.message).to.match /timed out/

        describe 'Successful authentication',
            mwt good-session!, false, null, null, true, false, (req) ->

                test 'Post data was transferred', ->
                    expect(req.body).to.equal req.session.post-data

                test 'Last use was updated', ->
                    expect(req.session.last).to.be.within now(-100), now!

