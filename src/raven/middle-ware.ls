WlsResponse = require './wls-response'

module.exports = ({key-store, auth-types}, req, res, next) -->
    wls-resp = WlsResponse.parse auth-types, res.body.WlsResponse

