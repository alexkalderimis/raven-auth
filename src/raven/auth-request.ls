require! qs

serialise-date = (date) -> date.toISOString().replace /[:\.-]/g, ''

module.exports = (wls-base, auth-types, {req, desc, msg, fail = 'yes', ver = 2}) -->
    date = serialise-date new Date()
    {url} = req
    params = (req.body ? '')

    wls-base + \? + qs.stringify {ver, url, desc, msg, params, date, fail}

