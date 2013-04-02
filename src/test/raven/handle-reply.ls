expect = require('chai').expect

Request = require '../request'
Response = require '../response'
key-store = require '../key-store'
handle-reply = require '../../raven/handle-reply'

auth-types = [ \dummy ]
timeout = 5000
ver = 2
max-skew = 30000
iact = (req) -> req.session.iact
max-session-life = 100
now = (offset = 0) -> new Date().get-time! + offset

get-config = -> {
    max-session-life, iact, max-skew, ver,
    key-store, auth-types, timeout, read-reply: id
}


class InvalidResponse
    is-valid: -> false

class ValidResponse
    (opts = {}) -> import opts
    is-valid: -> true

    redirect: (res) -> res.data.redirected = true

phase2 = handle-reply get-config!

let test = it

    describe 'Invalid response', ->

        req = new Request {}
        res = new Response
        reply = new InvalidResponse

        phase2 reply, req, res

        test 'The response should be ended', ->
            expect(res.data.ended).to.be.true

        test 'The response should mention parsing', ->
            expect(res.content).to.match /parse/

        test 'The response status should be 500', ->
            expect(res.statusCode).to.equal 500

        test 'The response should not be redirected to destination', ->
            expect(res.data.redirected).to.not.be.true

    describe 'Response with wrong url', ->

        req = new Request url: \dummy-url
        res = new Response
        reply = new ValidResponse url: \wrong-url

        phase2 reply, req, res

        test 'The response should be ended', ->
            expect(res.data.ended).to.be.true

        test 'The response should mention urls', ->
            expect(res.content).to.match /URL/

        test 'The response status should be 500', ->
            expect(res.statusCode).to.equal 500

        test 'The response should not be redirected to destination', ->
            expect(res.data.redirected).to.not.be.true

    describe 'Already authenticated', ->

        req = new Request url: \dummy, session: {principal: \foo}
        res = new Response
        reply = new ValidResponse url: \dummy

        phase2 reply, req, res

        test 'The response should be redirected to destination', ->
            expect(res.data.redirected).to.be.true

    describe 'No session storage', ->

        req = new Request url: \dummy
        res = new Response
        reply = new ValidResponse url: \dummy

        phase2 reply, req, res

        test 'The response should be ended', ->
            expect(res.data.ended).to.be.true

        test 'The response status should be 500', ->
            expect(res.statusCode).to.equal 500

        test 'The response should mention sessions', ->
            expect(res.content).to.match /session/i

        test 'The response should not be redirected to destination', ->
            expect(res.data.redirected).to.not.be.true

    describe 'Wrong version', ->

        req = new Request url: \dummy, session: {can-store: true}
        res = new Response
        reply = new ValidResponse url: \dummy, ver: 1

        phase2 reply, req, res

        test 'The response should be redirected to destination', ->
            expect(res.data.redirected).to.be.true

        test 'The session should store a the 600 code', ->
            expect(req.session.status-code).to.equal 600

        test 'The session should store a message about protocols', ->
            expect(req.session.message).to.match /protocol/

    describe 'Auth failed', ->

        req = new Request url: \dummy, session: {can-store: true}
        res = new Response
        reply = new ValidResponse url: \dummy, ver: 2, status: 400, msg: 'oops'

        phase2 reply, req, res

        test 'The response should be redirected to destination', ->
            expect(res.data.redirected).to.be.true

        test 'The session should store a the 400 code', ->
            expect(req.session.status-code).to.equal 400

        test 'The session should store a message with the info from raven', ->
            expect(req.session.message).to.match /oops/

    describe 'Reply from the future', ->

        req = new Request url: \dummy, session: {can-store: true}
        res = new Response
        reply = new ValidResponse {
            url: \dummy
            ver: 2
            status: 200
            issued-at: new Date(now 100000)
        }

        phase2 reply, req, res

        test 'The response should be redirected to destination', ->
            expect(res.data.redirected).to.be.true

        test 'The session should store a the 600 code', ->
            expect(req.session.status-code).to.equal 600

        test 'The session should store a message mentioning the future', ->
            expect(req.session.message).to.match /future/

    describe 'Stale response', ->

        req = new Request url: \dummy, session: {can-store: true}
        res = new Response
        reply = new ValidResponse {
            url: \dummy
            ver: 2
            status: 200
            issued-at: new Date(now -100000)
        }

        phase2 reply, req, res

        test 'The response should be redirected to destination', ->
            expect(res.data.redirected).to.be.true

        test 'The session should store a the 600 code', ->
            expect(req.session.status-code).to.equal 600

        test 'The session should store a message mentioning staleness', ->
            expect(req.session.message).to.match /stale/

    describe 'Unacceptable', ->

        req = new Request url: \dummy, session: {can-store: true}
        res = new Response
        reply = new ValidResponse {
            url: \dummy
            ver: 2
            status: 200
            issued-at: new Date(now -10)
            is-acceptable: false
        }

        phase2 reply, req, res

        test 'The response should be redirected to destination', ->
            expect(res.data.redirected).to.be.true

        test 'The session should store a the 600 code', ->
            expect(req.session.status-code).to.equal 600

        test 'The session should store a message mentioning acceptability', ->
            expect(req.session.message).to.match /acceptable/

    describe 'No forced interaction', ->

        req = new Request url: \dummy, session: {can-store: true, iact: true}
        res = new Response
        reply = new ValidResponse {
            url: \dummy
            ver: 2
            status: 200
            issued-at: new Date(now -10)
            is-acceptable: true
        }

        phase2 reply, req, res

        test 'The response should be redirected to destination', ->
            expect(res.data.redirected).to.be.true

        test 'The session should store a the 600 code', ->
            expect(req.session.status-code).to.equal 600

        test 'The session should store a message mentioning interaction', ->
            expect(req.session.message).to.match /interaction/

    describe 'Authenticated', ->

        req = new Request url: \dummy, session: {can-store: true}
        res = new Response
        reply = new ValidResponse {
            url: \dummy
            ver: 2
            status: 200
            issued-at: new Date(now -10)
            is-acceptable: true
            principal: \corvus
            id: \corvid
            params: 'foo=bar'
            life: 100000
        }

        phase2 reply, req, res

        test 'The response should be redirected to destination', ->
            expect(res.data.redirected).to.be.true

        test 'The session should have the status code 200', ->
            expect(req.session.status-code).to.equal 200

        test 'The session should have the right issue', ->
            expect(req.session.issue).to.be.within (now -100), (now +100)

        test 'The session should have the right last use time', ->
            expect(req.session.last).to.be.within (now -100), (now +100)

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
        res = new Response
        reply = new ValidResponse {
            url: \dummy
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

        phase2 reply, req, res

        test 'The response should be redirected to destination', ->
            expect(res.data.redirected).to.be.true

        test 'The session should have the status code 200', ->
            expect(req.session.status-code).to.equal 200

        test 'The session should have the right issue', ->
            expect(req.session.issue).to.be.within (now -100), (now +100)

        test 'The session should have the right last use time', ->
            expect(req.session.last).to.be.within (now -100), (now +100)

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
        res = new Response
        reply = new ValidResponse {
            url: \dummy
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

        phase2 reply, req, res

        test 'The session should have the right life', ->
            expect(req.session.life).to.equal 50
