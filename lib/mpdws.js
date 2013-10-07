'use strict';

var mpd = require('mpd');
var Primus = require('primus');
var PrimusEmitter = require('primus-emitter');
var PrimusResponder = require('primus-responder');

var MpdWsServer = function(httpServer) {
    this.httpServer = httpServer;
    this._isReady = false;
    this._readyCallbacks = [];
    var self = this;
    
    // Fire callback immediately if the MPD connection is already good to go,
    // or wait for it if necessary.
    var addReadyCallback = function(callback) {
        if (self._isReady) {
            callback.call(self);
        } else {
            self._readyCallbacks.push(callback);
        }
    }

    var primus =  new Primus(httpServer, {transformer: 'websockets'});    
    primus.use('responder', PrimusResponder);
    primus.on('connection', function(spark) {
        console.log('connect');
        addReadyCallback(function() {
            var client = self.mpdClient;

            // All clients get a ready event
            spark.emit('ready');

            // Forward basic MPD events
            var events = ['error', 'end', 'connect'];
            for (var i = 0; i < events.length; i++) {
                (function(event) {
                    client.on(event, function() {
                        primus.emit.apply(primus, [event] + arguments);
                    });
                })(events[i]);
            }
            // System events fire twice
            client.on('system', function(name) {
                console.log('system');
                console.log(name);
                primus.emit('system', name);
                primus.emit('system-' + name);
            });            
        });
    });
};
MpdWsServer.prototype.connect = function(mpdOptions, connectCallback, errCallback) {
    this.mpdClient = mpd.connect(mpdOptions);
    var self = this;
    this.mpdClient.on('ready', function() {        
        self._isReady = true;
        for(var i = 0; i < self._readyCallbacks.length; i++) {
            self._readyCallbacks[i]();
        }
        if (connectCallback != null) {
            connectCallback();
        }
    });

    return this;
};

module.exports = {
    createServer: function(httpServer) {
        return new MpdWsServer(httpServer);
    }
};