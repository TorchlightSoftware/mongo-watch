QueryStream = require '../QueryStream'

writers = {}

module.exports = (cache, collName, keys, done) ->

  for key in keys
    fullKey = "#{collName}.#{key}"

    # check what keys already exist
    if writers[collName]?
      newKeys = _.filter keys, (k) -> k not in writers[collName].keys
      unless _.isEmpty newKeys
        writers[collName].qs.add newKeys

    else

      # subscribe to new keys
      qs = new QueryStream {}
      cw = new CacheWriter {}
      qs.pipe(cw)

      writers[collName] = {cw, qs}

    writers[collName].cw.ready ->
      done()
