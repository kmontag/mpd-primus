mpd = require('mpd')
http = require('http')
BasicLogger = require('basic-logger')
Primus = require('primus')
PrimusEmitter = require("primus-emitter")
PrimusResponder = require("primus-responder")

logger = new BasicLogger()
basicEvents = ['error', 'end', 'connect']

# So we can get the same type of instance when outputting the client-side
# library.
buildPrimus = (httpServer)->
  primus = new Primus(httpServer, transformer: 'websockets')
  primus.use 'responder', PrimusResponder
  primus.use 'emitter', PrimusEmitter
  primus

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
    primus = buildPrimus httpServer
    primus.on 'connection', (spark)=>
      logger.debug 'Connect'
      addReadyCallback =>
        client = @mpdClient

        # All clients get a ready event
        spark.send 'ready'

        # Forward basic MPD events
        for event in ['error', 'end', 'connect']
          do (event)->
            client.on event, (args...)->
              spark.send.apply spark, [event] + args

        # System events fire twice
        client.on 'system', (name)->
          spark.send 'system', name
          spark.send "system-#{name}"

  connect: (mpdOptions, connectCallback, errCallback)->
    @mpdClient = mpd.connect mpdOptions
    @mpdClient.on 'ready', =>
      @_isReady = true
      (c()) for c in @_readyCallbacks
      connectCallback() if connectCallback?

      for event in basicEvents
        do (event)=>
          @mpdClient.on event, (args...)->
            logger.debug event
      @mpdClient.on 'system', (name)=>
        logger.debug "system-#{name}"
    this

exports.createServer = (httpServer)-> new exports.Server httpServer
exports.library = -> buildPrimus(http.createServer()).library()

module.exports = exports
