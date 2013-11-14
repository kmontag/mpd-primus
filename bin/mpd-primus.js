#!/usr/bin/env node
var argv = require('optimist')
  .usage("Create a WebSockets-compatible server to read and control an MPD server\nUsage: $0")
  .describe('http-port', 'Port for incoming connections')
  .describe('http-host', 'Hostname for incoming connections (allows all hostnames by default)')
  .describe('mpd-host', 'Hostname for the outgoing MPD connection')
  .describe('mpd-port', 'Port for the outgoing MPD connection')
  .describe('help', 'Show this message and exit')
  .boolean('help')
  .describe('verbose', 'Print debug info')
  .alias('verbose', 'v')
  .boolean('verbose')
  .default({
    'http-port': 8080,
    'mpd-host': '127.0.0.1',
    'mpd-port': 6600,
  })
  .argv;

if (argv.help) {
  console.log(require('optimist').help());
  process.exit(0);
}

var BasicLogger = require('basic-logger');
if (argv.verbose) {
  BasicLogger.setLevel('debug');
} else {
  BasicLogger.setLevel('info', true);
}
var mpdws = require('../lib/mpdws.js');
var http = require('http');
var httpServer = http.createServer().listen(argv['http-port'], argv['http-host'], function() {
  console.log('HTTP Server listening on port ' + argv['http-port'])
});
var server = mpdws.createServer(httpServer).connect({
  port: argv['mpd-port'],
  host: argv['mpd-host'],
}, function() {
  console.log('Connected to MPD server at ' + argv['mpd-host'] + ':' + argv['mpd-port']);
});