require! qs

serialise-date = (date) -> date.toISOString().replace /[:\.-]/g, ''

module.exports = (wls-base, auth-types, {req, desc, msg, fail = 'yes', ver = 2}) -->
    date = serialise-date new Date()
    {url} = req
    params = '' # Not implemented. This is an optional part of the spec.
    aauth = (auth-types ? []).join \,

    wls-base + \? + qs.stringify {ver, url, desc, aauth, msg, params, date, fail}

