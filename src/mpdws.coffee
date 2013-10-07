mpd = require('mpd')
Primus = require('primus')
PrimusEmitter = require("primus-emitter")
PrimusResponder = require("primus-responder")

exports = {}
exports.Server = class
  constructor: (httpServer)->
    @httpServer = httpServer
    @mpdClient = null
    @_isReady = false
    @_readyCallbacks = []

    # Fire callback immediately if the MPD connection is already good to go,
    # or wait for it if necessary.
    addReadyCallback = (callback)=>
      if @_isReady
        callback()
      else
        @_readyCallbacks.push callback
    primus = new Primus(httpServer, transformer: 'websockets')
    primus.use 'responder', PrimusResponder
    primus.on 'connection', (spark)=>
      console.log "connect"
      addReadyCallback =>
        client = @mpdClient

        # All clients get a ready event
        spark.emit 'ready'

        # Forward basic MPD events
        for event in ['error', 'end', 'connect']
          do (event)->
            client.on event, (args...)->
              primus.emit.apply primus, [event] + args

        # System events fire twice
        client.on 'system', (name) ->
          console.log "system"
          console.log name
          primus.emit 'system', name
          primus.emit "system-#{name}"

  connect: (mpdOptions, connectCallback, errCallback)->
    @mpdClient = mpd.connect mpdOptions
    @mpdClient.on 'ready', =>
      @_isReady = true
      (c()) for c in @_readyCallbacks
      connectCallback() if connectCallback?
    this

exports.createServer = (httpServer)-> new exports.Server httpServer
module.exports = exports
