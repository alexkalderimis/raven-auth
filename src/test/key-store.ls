require! fs

key-dir = __dirname + '/../../keys/demo-server/'

read-key = -> fs.readFileSync "#{ key-dir }/#{ it }key901", 'utf8'

key-store = [ [x, read-key x] for x in <[ pub priv ]> ] |> listToObj |> objToFunc

module.exports = key-store
