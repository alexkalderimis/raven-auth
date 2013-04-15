MiddleWare = require './raven/middle-ware'
RavenStrategy = require './raven/strategy'

module.exports = MiddleWare

module.exports.strategy = -> new RavenStrategy it

