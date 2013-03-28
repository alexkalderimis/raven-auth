expect = require('chai').expect

WlsResponse = require '../raven/wls-response'

auth-types = [ \dummy ]

parse = WlsResponse.parse auth-types

let test = it

    describe 'Empty responses', ->

        var resp

        @beforeAll -> resp := parse null

        test 'should be invalid', -> expect(resp.is-valid()).to.be.false

