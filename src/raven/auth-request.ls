serialise-date = (date) -> date

module.exports = class AuthRequest

    ({req, @auth-types, @desc, @msg, @fail = 'yes', @ver = 2}) ->
        @date = serialise-date new Date()
