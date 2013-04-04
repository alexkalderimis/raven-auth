expect = require('chai').expect

to-auth-req = require('../../raven/auth-request') \wls-url, [ \foo \bar ]


no-msgs = 'wls-url?ver=2&url=req-url&desc=&aauth=foo%2Cbar&msg=&params=&date=DATE-STR&fail=yes'
with-msgs = 'wls-url?ver=2&url=req-url&desc=desc&aauth=foo%2Cbar&msg=msg&params=&date=DATE-STR&fail=yes'

de-date = (x) -> x.replace /date=20.*Z/, 'date=' + \DATE-STR

let test = it

    describe 'Auth Request generator', ->

        req = url: \req-url
        msg = \msg
        desc = \desc

        test 'should have generated a suitable url', ->

            auth-loc = to-auth-req {req}
            expect(de-date auth-loc).to.equal no-msgs

        test 'should have generated a suitable url, with messages', ->

            auth-loc = to-auth-req {req, msg, desc}
            expect(de-date auth-loc).to.equal with-msgs

