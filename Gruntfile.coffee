module.exports = (g) ->
    
  g.loadNpmTasks('grunt-contrib-watch')
  g.loadNpmTasks('grunt-simple-mocha')
  g.loadNpmTasks('grunt-contrib-clean')

  {initConfig, util, registerMultiTask, registerTask} = g
  log = g.log.writeln

  registerTask 'default', ['clean', 'build', 'simplemocha']

  registerMultiTask 'build', 'compile livescripts', ->
    done = @async()
    {files, dir, dest, flags} = @data

    dest ?= dir

    args =
      cmd: './node_modules/.bin/livescript',
      args: [ '--compile', '--output', dest]

    if (flags)
      args.args = flags.map( (f) -> "--#{ f }" ).concat args.args

    if dir
      log "Compiling #{ dir } --> #{ dest }"
      args.args.push dir
    else if files
      log "Compiling #{ files.length } files to #{ dest }"
      args.args = ['join'].concat(args.args).concat files

    util.spawn(args, done)

  initConfig
    clean: ['build']
    watch:
      files:"src/**/*.ls"
      tasks:"default"
    build:
      compile:
        flags: ["const", "prelude"]
        dir: "src/"
        dest: "build/"
    simplemocha:
      options:
        globals: ['should']
        timeout: 3000
        ignoreLeaks: false
        grep: '*-test'
        ui: 'bdd'
        reporter: 'tap'
      all: { src: 'build/test/**/*.js' }

