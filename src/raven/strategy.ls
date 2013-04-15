middle-ware = require './middle-ware'

# A strategy wrapping the middle-ware making this suitable for use with passport.
module.exports = class RavenStrategy

    (@opts) ->

    authenticate: (req, options) ->
        next = @~pass
        fail = ~> @~fail
        redirect = ~> @~redirect

        config = @opts with {fail, redirect}
        raven = middle-ware config

        raven req, {}, next

