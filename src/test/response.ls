module.exports = class MockResponse

    (@data = {}) ->

    end: (content, enc) ->
        @content = new Buffer(content, enc).toString('utf8') if content?
        @data.ended = true

    writeHead: (@statusCode, @headers) ->




