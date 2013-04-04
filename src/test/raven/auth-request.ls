expect = require('chai').expect

to-auth-req = require('../../raven/auth-request') {
    raven-url: \wls-url,
    auth-types: [ \foo \bar ]
    local-host: 'http://my-host.org'
}

no-msgs = 'wls-url?ver=2&url=http%3A%2F%2Fmy-host.org%2Freq-url&desc=&aauth=foo%2Cbar&msg=&params=&date=DATE-STR&fail=yes'
with-msgs = 'wls-url?ver=2&url=http%3A%2F%2Fmy-host.org%2Freq-url&desc=desc&aauth=foo%2Cbar&msg=msg&params=&date=DATE-STR&fail=yes'

de-date = (x) -> x.replace /date=20.*Z/, 'date=' + \DATE-STR

let test = it

    describe 'Auth Request generator', ->

        req = url: '/req-url'
        msg = \msg
        desc = \desc

        test 'should have generated a suitable url', ->

            auth-loc = to-auth-req {req}
            expect(de-date auth-loc).to.equal no-msgs

        test 'should have generated a suitable url, with messages', ->

            auth-loc = to-auth-req {req, msg, desc}
            expect(de-date auth-loc).to.equal with-msgs

