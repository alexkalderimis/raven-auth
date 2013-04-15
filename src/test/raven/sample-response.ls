require! [qs, debug, util]
log = debug \test:sample-response
expect = require('chai').expect
key-store = require '../key-store'

raw-response = '2!200!!20130411T181511Z!1365704106-26631-0!http%3A%2F%2Flocalhost%3A3001%2F!test0003!!pwd!32959!!901!JLaFVXJa7xK3ea0d1LDCIkXyeGqTHiJE-qXneQeSYvheNYzzCtHZvsfisyevyPr9l2lpTRP67Szoy1IUx2oQzxjBczoimMjdjCefkaLybI8NcZtGiY9iaFuodohdUO.mEw3m8SPnvyhsNm2qrpatfvQYkfuLeaLjLelZRyBHC7E_'

sample-response = qs.parse("x=#{ raw-response }").x
get-key = -> key-store \pub
auth-types = [ \pwd ]

WlsResponse = require '../../raven/wls-response'
parse = WlsResponse.parse get-key, auth-types

let test = it

    describe 'A sample response', ->

        resp = parse sample-response

        log resp

        test 'parts are ok', ->
            expect(resp.parts-ok!).to.be.true

        test 'principal is ok', ->
            expect(resp.princ-ok!).to.be.true

        test 'auth is ok', ->
            expect(resp.auth-ok!).to.be.true

        test 'sig matches content', ->
            expect(resp.sig-matches-content!).to.be.true

        test 'should be valid', ->

            expect(resp.is-valid!).to.be.true
