sample-response = '2!200!!20130404T013030Z!1365039030-16998-4!http%3A%2F%2Flocalhost%3A3001%2F!test0001!pwd!!36000!!901!EJhXHSEuaj2T3U-f-8OMCIb2DSkFvx7jRUFY5EgGlLiyKlWcR7s1DI..FJLKGc6Otb9rKFK-haF7NvyzMMmOkbx1iKZSgUXW5B420-dW.7TPOB187xcHzQezPSw7rHxrq2byp-pRkT7G9TDWDrqAMblasSsN3s8Nanifp1gOcxA_'

expect = require('chai').expect
key-store = require '../key-store'
get-key = -> key-store \pub
auth-types = [ \pwd ]

WlsResponse = require '../../raven/wls-response'
parse = WlsResponse.parse get-key, auth-types

require! util

let test = it

    describe 'A sample response', ->

        resp = parse sample-response

        console.log util.inspect resp

        test 'parts are ok', ->
            expect(resp.parts-ok!).to.be.true

        test 'principal is ok', ->
            expect(resp.princ-ok!).to.be.true

        test 'auth is ok', ->
            expect(resp.auth-ok!).to.be.true

        test.skip 'sig matches content', ->
            expect(resp.sig-matches-content!).to.be.true

        test.skip 'should be valid', ->

            expect(resp.is-valid!).to.be.true
