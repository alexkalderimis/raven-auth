expect = require('chai').expect

authenticate = require '../../raven/authenticate'

Request = require '../request'
CallTracker = require '../call-tracker'

to-auth-req = -> "I am an auth request"

empty-config = {}

config-with-fns =
    get-msg: (req) -> req.called-get-msg = true
    get-desc: (req) -> req.called-get-desc = true

let test = it

    describe 'Simple authentication', ->

        req = new Request method: \GET, body: \foo
        redirect = new CallTracker

        authenticate empty-config, to-auth-req, req, redirect~call

        test 'session should have a can-store property', ->
            expect(req.session.can-store).to.be.true

        test 'session should not have any post-data', ->
            expect(req.session.post-data).to.not.exist

        test 'response should have been ended', ->
            expect(redirect.called).to.be.true

        test 'response should be a redirect', ->
            expect(redirect.args[0]).to.equal 'I am an auth request'

    describe 'With post-data', ->

        req = new Request method: \POST, body: \foo
        redirect = new CallTracker

        authenticate empty-config, to-auth-req, req, redirect~call

        test 'session should have a can-store property', ->
            expect(req.session.can-store).to.be.true

        test 'session should have post-data', ->
            expect(req.session.post-data).to.equal \foo

        test 'response should have been ended', ->
            expect(redirect.called).to.be.true

        test 'response should be a redirect', ->
            expect(redirect.args[0]).to.equal 'I am an auth request'

    describe 'Providing messages and descriptions', ->

        req = new Request method: \GET, body: \foo
        redirect = new CallTracker
        var ar-args

        authenticate config-with-fns, (to-auth-req << -> ar-args := it), req, redirect~call

        test 'session should have a can-store property', ->
            expect(req.session.can-store).to.be.true

        test 'session should not have any post-data', ->
            expect(req.session.post-data).to.not.exist

        test 'response should have been ended', ->
            expect(redirect.called).to.be.true

        test 'response should be a redirect', ->
            expect(redirect.args[0]).to.equal 'I am an auth request'

        test 'get-msg was called', ->
            expect(req.called-get-msg).to.be.true

        test 'get-desc was called', ->
            expect(req.called-get-desc).to.be.true

        test 'msg and desc were used', ->
            expect(ar-args.msg).to.be.true
            expect(ar-args.desc).to.be.true


