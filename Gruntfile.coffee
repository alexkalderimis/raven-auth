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

  g.initConfig
    clean: ['build']
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

