rimraf = require 'rimraf'
{spawn} = require 'child_process'
{print} = require 'sys'

task 'clean', 'Remove compiled files', ->
  rimraf.sync 'lib'

task 'build', 'Build entire project', ->
  coffee = spawn 'node_modules/.bin/coffee', ['-c', '-o', 'lib', 'src']
  coffee.stderr.on 'data', (data) ->
    process.stderr.write data.toString()
  coffee.stdout.on 'data', (data) ->
    print data.toString()

task 'rebuild', 'Clean and build the project from scratch', ->
  invoke 'clean'
  invoke 'build'