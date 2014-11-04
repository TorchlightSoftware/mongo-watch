# Mongo Watch

This watcher ties into the MongoDB replication log (local.oplog.rs) by default, but you can also tie into local.oplog.$main on a master DB. It then notifies your watchers any time the data changes.

In order to use this you must:

*replication log*

1. Have access to the oplog.  This will not be available on shared DB hosting, as it would reveal everyone else's database transactions to you.
2. Have replication enabled.  This can be done by starting mongod with the option `--replSet someArbitraryName`.  You must then call `rs.initiate()` from the mongo CLI.

*master log*

1. Have access to the oplog.  This will not be available on shared DB hosting, as it would reveal everyone else's database transactions to you.
2. Start your mongod as `--master`.
3. Use: `new MongoWatch({useMasterOplog:true})`

The watcher is fairly low latency and overhead.  On my machine a test with a single insert and watcher takes 20ms.  The cursor used to tail the oplog is being initialized with {awaitdata: true} so the data should be getting pushed from MongoDB's internal mechanism, instead of polling.

Because the watcher ties in to the oplog, this solution should scale with you as you add more MongoDB nodes, and allow any corresponding application instances to be notified of the same state changes.  I have not yet set up a cluster to test this, so I would welcome any comments or feedback you might have.

Happy event driven programming!  8-)

**Note:** The query functionality previously supported in 0.1.12 is now deprecated.  This code will be moved to [Particle](https://github.com/torchlightsoftware/particle).  Sorry for any inconvenience, but I determined this would be a much cleaner place to separate the APIs and respective responsibilities of the libraries.

## Install

```bash
npm install mongo-watch
```

## Usage

Watching a collection is as easy as:

```coffee-script
MongoWatch = require 'mongo-watch'

watcher = new MongoWatch {format: 'pretty'}

# watch the collection
watcher.watch 'test.users', (event) ->

  # parse the results
  console.log 'something changed:', event
```

Now when you run an insert you should see the event get logged by the code above.

```coffee-script
# create db client for a test transaction
{Server, Db} = require 'mongodb'
client = new Db 'test', new Server('localhost', 27017), {w: 1}
client.open ->
  client.collection 'users', (err, users) ->

    # fire off an update that will trigger the watcher
    users.insert {email: 'graham@daventry.com'}, ->
```

## Options

See the applyDefaults function in [lib/main.coffee](https://github.com/TorchlightSoftware/mongo-watch/blob/master/lib/main.coffee) for a list of options and their defaults.

See the tests for more examples.

## Authentication

Pass the "username" and "password" options.

```coffee
watcher = new MongoWatch {username: 'bobross', password: 'happytrees'}
```

## Replica sets

If you pass a replicaSet array it will be used to establish a connection.
It should keep working in case the primary changes - i.e. when it dies, and secondary takes it place.

```coffee
watcher = new MongoWatch {
    replicaSet: [
        {host: "currentPrimary.mongoexample.com", port : 10453},
        {host: "currentSecondary.mongoexample.com", port : 10452}
    ]
}
```

## Debugging

If you pass the onDebug option with a function of your choice, it will be notified of major events in the listener lifecycle.  This is useful for troubleshooting if you're not receiving the notifications you expect.

```coffee
watcher = new MongoWatch {onDebug: console.log}
```

For reference, here is output taken from the test 'Mongo Watch - insert should emit an event'.  You should expect an output similar to this, and if it's breaking down you should be able to see why from the last event that was fired.  Are you listening to the right collection?

```bash
Ready: false
Emiting 'connected'. Stream exists: true
Adding emitter for: { collection: 'test.users' }
Adding listener on: { collection: 'test.users' }
Data changed: { data:
   { ts: { _bsontype: 'Timestamp', low_: 1, high_: 1362553757 },
     h: { _bsontype: 'Long', low_: -1091839621, high_: 386723518 },
     op: 'i',
     ns: 'test.users',
     o: { email: 'graham@daventry.com', _id: 5136eb9d19bd55597e000001 } },
  watching: 'test.users',
  relevant: true }
Emitting event: { channel: 'change:test.users',
  event:
   { ts: { _bsontype: 'Timestamp', low_: 1, high_: 1362553757 },
     h: { _bsontype: 'Long', low_: -1091839621, high_: 386723518 },
     op: 'i',
     ns: 'test.users',
     o: { email: 'graham@daventry.com', _id: 5136eb9d19bd55597e000001 } } }
Removing listeners for: test.users
```

## Credits

[Kristina Chodorow](http://www.kchodorow.com/blog/2010/10/12/replication-internals/) was very helpful both in documenting the oplog in her blog posts, and in answering some of my questions.  Christian Kvalheim's [code](https://github.com/christkv/realtime/blob/master/lib/app/dataproviders/flow_data_provider.js) served as the basis for the cursor connection.

## Contributing

Pull requests welcome!  Please create a feature branch instead of submitting directly to master.  This will help me test/verify before merging.

## LICENSE

(MIT License)

Copyright (c) 2013 Torchlight Software <info@torchlightsoftware.com>

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
"Software"), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
