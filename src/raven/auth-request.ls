require! qs

serialise-date = (date) -> date.toISOString().replace /[:\.-]/g, ''

module.exports = (config, {req, desc, msg, fail = 'yes', ver = 2}) -->
    {raven-url, auth-types, local-host} = config
    date = serialise-date new Date()
    url = local-host + req.url
    params = '' # Not implemented. This is an optional part of the spec.
    aauth = (auth-types ? []).join \,

    raven-url + \? + qs.stringify {ver, url, desc, aauth, msg, params, date, fail}

