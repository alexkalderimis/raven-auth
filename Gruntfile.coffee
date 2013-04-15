module.exports = (g) ->
    
  g.loadNpmTasks('grunt-contrib-watch')
  g.loadNpmTasks('grunt-simple-mocha')
  g.loadNpmTasks('grunt-contrib-clean')

  log = g.log.writeln

  g.registerTask 'default', ['clean', 'build', 'simplemocha']

  g.registerMultiTask 'build', 'compile livescripts', ->
    done = @async()
    {files, dir, dest, flags} = @data

    dest ?= dir

    args =
      cmd: './node_modules/.bin/livescript',
      args: [ '--compile', '--output', dest]

    if (flags)
      args.args = flags.map( (f) -> "--#{ f }" ).concat args.args

    g.log.verbose.writeln args.cmd, args.args.join ' '

    if dir
      log "Compiling #{ dir } --> #{ dest }"
      args.args.push dir
    else if files
      log "Compiling #{ files.length } files to #{ dest }"
      args.args = ['join'].concat(args.args).concat files

    g.util.spawn(args, done)

  g.registerTask 'fetch-keys', 'Get the keys required for using real raven auth', ->
    done = @async()

    request = require 'request'
    cheerio = require 'cheerio'
    fs      = require 'fs'
    Q       = require 'q'

    writeFile = Q.nfbind fs.writeFile
    requesting = (args...) ->
      def = Q.defer()
      request args..., (err, response, body) ->
        if err?
          def.reject(new Error(err))
        else
          def.resolve([response, body])
      def.promise

    remoteDir = 'https://raven.cam.ac.uk/project/keys/'
    localDir  = __dirname + '/keys/raven/'

    getLinks = ([resp, body]) ->
      $ = cheerio.load body
      keyHrefs = []
      $('a').each ->
        link = $ this
        href = link.attr('href')
        if /pubkey/.test href
          g.log.writeln "Found #{ href }"
          keyHrefs.push href
      keyHrefs

    writeOut = (fileName, text) ->
      dest = localDir + fileName
      g.log.writeln "Writing #{ dest }"
      writeFile localDir + fileName, text

    requesting({uri: remoteDir})
      .then(getLinks)
      .then((links) ->
        promises = for h in links then do (h) ->
          requesting({uri: remoteDir + h}).then(([r, b]) -> writeOut h, b)
        Q.all promises)
      .then(-> done())
      .fail(done)

  g.initConfig
    clean: ['build', 'dist']
    watch:
      files: "src/**/*.ls"
      tasks: "default"
    build:
      compile:
        flags: ["const", "prelude"]
        dir: "src/"
        dest: "build/"
    simplemocha:
      options:
        timeout: 3000
        ignoreLeaks: false
        ui: 'bdd'
        reporter: 'spec'
      all:
        src: 'build/test/raven/*.js'

