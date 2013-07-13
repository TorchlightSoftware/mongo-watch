patched = false
module.exports = ->
  return if patched
  patched = true

  {EventEmitter} = require "events"
  orig = EventEmitter.prototype.on
  patch = ->
    @_maxListeners = 0
    orig.apply @, arguments

  EventEmitter.prototype.on = patch
  EventEmitter.prototype.addListener = patch
