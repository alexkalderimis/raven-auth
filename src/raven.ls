WlsResponse = require './raven/wls-response'

module.exports = (req, res, next) -->
    reply = get-reply req.body

get-reply = (params) ->
    resp = WlsResponse.parse params['WLS-Response']
    return void unless resp?






