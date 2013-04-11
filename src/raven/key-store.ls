require! fs

kid = -> it.replace /pubkey/, ''
key = (d, f) -> fs.readFileSync "#{ d }/#{ f }", 'utf8'

module.exports = (dir) ->
    fns = fs.readdirSync dir
    [ [kid(fn), key(dir, fn)] for fn in fns when fn is /pub/ ] |> listToObj |> objToFunc
