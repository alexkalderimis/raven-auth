expect = require('chai').expect

Request = require '../request'
CallTracker = require '../call-tracker'
key-store = require '../key-store'
handle-reply = require '../../raven/handle-reply'

auth-types = [ \dummy ]
timeout = 5000
ver = 2
max-skew = 30000
iact = (req) -> req.session.iact
max-session-life = 100
now = (offset = 0) -> new Date().get-time! + offset
local-host = \here-

get-config = -> {
    max-session-life, iact, max-skew, ver, local-host,
    key-store, auth-types, timeout, read-reply: id
}

TOLERANCE = 500ms

class InvalidResponse
    is-valid: -> false

class ValidResponse
    (opts = {}) -> import opts
    is-valid: -> true

    redirect: (res) -> redirect.called = true

phase2 = handle-reply get-config!

let test = it
    describe 'Phase2', ->

        describe 'Invalid response', ->

            req = new Request {}
            fail = new CallTracker
            redirect = new CallTracker
            reply = new InvalidResponse

            phase2 reply, req, fail~call, redirect~call

            test 'The authentication should be failed', ->
                expect(fail.called).to.be.true

            test 'The response should mention invalid', ->
                expect(fail.args[0]).to.match /invalid/i

            test 'The response status should be 500', ->
                expect(fail.args[1]).to.equal 500

            test 'The response not be redirected to destination', ->
                expect(redirect.called).to.not.be.true

        describe 'Response with wrong url', ->

            req = new Request url: \dummy-url
            fail = new CallTracker
            redirect = new CallTracker
            reply = new ValidResponse url: \wrong-url

            phase2 reply, req, fail~call, redirect~call

            test 'The response should be ended', ->
                expect(fail.called).to.be.true

            test 'The response should mention urls', ->
                expect(fail.args[0]).to.match /URL/

            test 'The response status should be 500', ->
                expect(fail.args[1]).to.equal 500

            test 'The response should not be redirected to destination', ->
                expect(redirect.called).to.not.be.true

        describe 'Already authenticated', ->

            req = new Request url: \dummy, session: {principal: \foo}
            fail = new CallTracker
            redirect = new CallTracker
            reply = new ValidResponse url: \here-dummy, principal: \foo

            phase2 reply, req, fail~call, redirect~call

            test 'The response should be redirected to destination', ->
                expect(redirect.called, "Fail args: #{ fail.args}").to.be.true

            test 'The response should be redirected to url in the WLS response', ->
                expect(redirect.args[0]).to.equal reply.url

            test 'There should be no response content', ->
                expect(fail.args).to.not.exist

        describe 'No session storage', ->

            req = new Request url: \dummy
            fail = new CallTracker
            redirect = new CallTracker
            reply = new ValidResponse url: \here-dummy

            phase2 reply, req, fail~call, redirect~call

            test 'The response should be ended', ->
                expect(fail.called).to.be.true

            test 'The response status should be 500', ->
                expect(fail.args[1]).to.equal 500

            test 'The response should mention sessions', ->
                expect(fail.args[0]).to.match /session/i

            test 'The response should not be redirected to destination', ->
                expect(redirect.called).to.not.be.true

        describe 'Wrong version', ->

            req = new Request url: \dummy, session: {can-store: true}
            fail = new CallTracker
            redirect = new CallTracker
            reply = new ValidResponse url: \here-dummy, ver: 1

            phase2 reply, req, fail~call, redirect~call

            test 'The response should be redirected to destination', ->
                expect(redirect.called).to.be.true

            test 'The session should store a 600 code', ->
                expect(req.session.status-code).to.equal 600

            test 'The session should store a message about protocols', ->
                expect(req.session.message).to.match /protocol/

        describe 'Auth failed', ->

            req = new Request url: \dummy, session: {can-store: true}
            fail = new CallTracker
            redirect = new CallTracker
            reply = new ValidResponse url: \here-dummy, ver: 2, status: 400, msg: 'oops'

            phase2 reply, req, fail~call, redirect~call

            test 'The response should be redirected to destination', ->
                expect(redirect.called).to.be.true

            test 'The session should store a the 400 code', ->
                expect(req.session.status-code).to.equal 400

            test 'The session should store a message with the info from raven', ->
                expect(req.session.message).to.match /oops/

        describe 'Reply from the future', ->

            req = new Request url: \dummy, session: {can-store: true}
            fail = new CallTracker
            redirect = new CallTracker
            reply = new ValidResponse {
                url: \here-dummy
                ver: 2
                status: 200
                issued-at: new Date(now 100000)
            }

            phase2 reply, req, fail~call, redirect~call

            test 'The response should be redirected to destination', ->
                expect(redirect.called).to.be.true

            test 'The session should store a the 600 code', ->
                expect(req.session.status-code).to.equal 600

            test 'The session should store a message mentioning the future', ->
                expect(req.session.message).to.match /future/

        describe 'Stale response', ->

            req = new Request url: \dummy, session: {can-store: true}
            fail = new CallTracker
            redirect = new CallTracker
            reply = new ValidResponse {
                url: \here-dummy
                ver: 2
                status: 200
                issued-at: new Date(now -100000)
            }

            phase2 reply, req, fail~call, redirect~call

            test 'The response should be redirected to destination', ->
                expect(redirect.called).to.be.true

            test 'The session should store a the 600 code', ->
                expect(req.session.status-code).to.equal 600

            test 'The session should store a message mentioning staleness', ->
                expect(req.session.message).to.match /stale/

        describe 'Unacceptable', ->

            req = new Request url: \dummy, session: {can-store: true}
            fail = new CallTracker
            redirect = new CallTracker
            reply = new ValidResponse {
                url: \here-dummy
                ver: 2
                status: 200
                issued-at: new Date(now -10)
                is-acceptable: false
            }

            phase2 reply, req, fail~call, redirect~call

            test 'The response should be redirected to destination', ->
                expect(redirect.called).to.be.true

            test 'The session should store a the 600 code', ->
                expect(req.session.status-code).to.equal 600

            test 'The session should store a message mentioning acceptability', ->
                expect(req.session.message).to.match /acceptable/

        describe 'No forced interaction', ->

            req = new Request url: \dummy, session: {can-store: true, iact: true}
            fail = new CallTracker
            redirect = new CallTracker
            reply = new ValidResponse {
                url: \here-dummy
                ver: 2
                status: 200
                issued-at: new Date(now -10)
                is-acceptable: true
            }

            phase2 reply, req, fail~call, redirect~call

            test 'The response should be redirected to destination', ->
                expect(redirect.called).to.be.true

            test 'The session should store a the 600 code', ->
                expect(req.session.status-code).to.equal 600

            test 'The session should store a message mentioning interaction', ->
                expect(req.session.message).to.match /interact/i

        describe 'Authenticated', ->

            req = new Request url: \dummy, session: {can-store: true}
            fail = new CallTracker
            redirect = new CallTracker
            reply = new ValidResponse {
                url: \here-dummy
                ver: 2
                status: 200
                issued-at: new Date(now -10)
                is-acceptable: true
                principal: \corvus
                id: \corvid
                params: 'foo=bar'
                life: 100000
            }

            phase2 reply, req, fail~call, redirect~call

            test 'The response should be redirected to destination', ->
                expect(redirect.called).to.be.true

            test 'The session should have the status code 200', ->
                expect(req.session.status-code).to.equal 200

            test 'The session should have the right issue', ->
                expect(req.session.issue).to.be.within (now -TOLERANCE), (now +TOLERANCE)

            test 'The session should have the right last use time', ->
                expect(req.session.last).to.be.within (now -TOLERANCE), (now +TOLERANCE)

            test 'The session should have the right life', ->
                expect(req.session.life).to.equal 100

            test 'The session should have the right id', ->
                expect(req.session.id).to.equal \corvid

            test 'The session should have the right principal', ->
                expect(req.session.principal).to.equal \corvus

            test 'The session should have the right params', ->
                expect(req.session.params).to.equal 'foo=bar'

        describe 'Authenticated with interaction', ->

            req = new Request url: \dummy, session: {can-store: true, iact: true}
            fail = new CallTracker
            redirect = new CallTracker
            reply = new ValidResponse {
                url: \here-dummy
                auth: \pwd
                ver: 2
                status: 200
                issued-at: new Date(now -10)
                is-acceptable: true
                principal: \corvus
                id: \corvid
                params: 'foo=bar'
                life: 100000
            }

            phase2 reply, req, fail~call, redirect~call

            test 'The response should be redirected to destination', ->
                expect(redirect.called).to.be.true

            test 'The session should have the status code 200', ->
                expect(req.session.status-code).to.equal 200

            test 'The session should have the right issue', ->
                expect(req.session.issue).to.be.within (now -TOLERANCE), (now +TOLERANCE)

            test 'The session should have the right last use time', ->
                expect(req.session.last).to.be.within (now -TOLERANCE), (now +TOLERANCE)

            test 'The session should have the right life', ->
                expect(req.session.life).to.equal 100

            test 'The session should have the right id', ->
                expect(req.session.id).to.equal \corvid

            test 'The session should have the right principal', ->
                expect(req.session.principal).to.equal \corvus

            test 'The session should have the right params', ->
                expect(req.session.params).to.equal 'foo=bar'

        describe 'Authenticated with shorter than max life', ->

            req = new Request url: \dummy, session: {can-store: true, iact: true}
            fail = new CallTracker
            redirect = new CallTracker
            reply = new ValidResponse {
                url: \here-dummy
                auth: \pwd
                ver: 2
                status: 200
                issued-at: new Date(now -10)
                is-acceptable: true
                principal: \corvus
                id: \corvid
                params: 'foo=bar'
                life: 50
            }

            phase2 reply, req, fail~call, redirect~call

            test 'The session should have the right life', ->
                expect(req.session.life).to.equal 50

