expect = require('chai').expect

Request = require '../request'
Response = require '../response'
key-store = require '../key-store'
auth-types = [ \dummy ]

raven = {key-store, auth-types} |> require '../../raven/middle-ware'

class Next

    next: -> @called = true

let test = it

    describe 'Cancelled authentication', ->

        req = new Request session: {status-code: 410}
        req = new Response
        next = new Next

        @beforeAll -> raven req, res, next

        test 'the session should have been deleted', ->
            expect(req.session).to.be.null

        test 'the response should be 403', ->
            expect(res.statusCode).to.equal 403

        test 'the response content should mention cancellation', ->
            expect(res.content).to.match /cancelled/

