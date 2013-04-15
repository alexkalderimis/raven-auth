middle-ware = require './middle-ware'

# A strategy wrapping the middle-ware making this suitable for use with passport.
module.exports = class RavenStrategy

    name: 'raven'

    (@opts) ->

    authenticate: (req, options) ->
        next = ~>
            @opts.verify req.session.principal, (err, user, msg) ~>
                | err => @error err
                | not user => @fail msg
                | otherwise => @success user

        fail = ~> @~fail
        redirect = ~> @~redirect

        config = @opts with {fail, redirect}
        raven = middle-ware config

        raven req, {}, next

