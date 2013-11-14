fs = require 'fs'
rimraf = require 'rimraf'
{spawn} = require 'child_process'
{print} = require 'sys'

task 'clean', 'Remove compiled files', ->
  rimraf.sync 'lib'
  rimraf.sync 'client'

task 'build', 'Build entire project', ->
  # Coffeescripts from src/
  coffee = spawn 'node_modules/.bin/coffee', ['-c', '-o', 'lib', 'src']
  coffee.stderr.on 'data', (data) ->
    process.stderr.write data.toString()
  coffee.stdout.on 'data', (data) ->
    print data.toString()

  # Client library
  coffee.on 'exit', (status)->
    if status is 0
      mpdws = require './lib/mpd-primus'
      clientLibrary = mpdws.library()
      fs.mkdir 'client', (err)->
        if not err or (err and err.code is 'EEXIST')
          fs.writeFile 'client/primus.js', clientLibrary

task 'rebuild', 'Clean and build the project from scratch', ->
  invoke 'clean'
  invoke 'build'