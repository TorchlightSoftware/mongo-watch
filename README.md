# Mongo Watch

Mongo-Watch creates active queries to Mongo.  Whereas most query interfaces will hand you back a snapshot of the data, Mongo-Watch gives you not only the current data, but subscribes you to all changes that occur to that data.

The purpose is to support state synchronization and event driven applications.

In order to use this you must:

1. Have access to the oplog.  This will not be available on shared DB hosting, as it would reveal everyone else's database transactions to you.
2. Have replication enabled.  This can be done by starting mongod with the option '--replSet someArbitraryName'.  You must then call `rs.initiate()` from the mongo CLI.

The watcher is fairly low latency and overhead.  On my local machine I'm seeing an insert get picked up by the watcher after about 20ms.  Only one cursor used to tail the oplog.  It is being initialized with {awaitdata: true} so the data should be getting pushed from MongoDB's internal mechanism, instead of polling.

Because the watcher ties in to the oplog, this solution should scale with you as you add more MongoDB nodes, and allow any corresponding application instances to be notified of the same state changes.  I have not yet set up a cluster to test this, so I would welcome any comments or feedback you might have.

Sorry for the ugly documentation.  If you ask nicely I can probably help you out.  :-)

## Install

```bash
npm install mongo-watch
```

## Usage

Watching a collection is as easy as:

```javascript
var MongoWatch, watcher;

MongoWatch = require('mongo-watch');

watcher = new MongoWatch({
  format: 'pretty'
});

watcher.query({
  collName: collName,
  selection: selection,
  idSet: idSet

}, function(err, query) {

  query.on('data', function(event) {
    console.log('something changed:', event);
  });
});
```

Now when you run an insert you should see the event get logged by the code above.

```javascript
// create db client for a test transaction
var Db, Server, client, mongo;
mongo = require('mongodb'), Server = mongo.Server, Db = mongo.Db;

client = new Db('test', new Server('localhost', 27017), {w: 1});

client.open(function() {
  client.collection('users', function(err, users) {
    users.insert({email: 'graham@daventry.com'}, function() {});
  });
});

```

## API

### Query

IN:
collName: The name of the collection you wish to watch.
select: A normal select object ala Mongo native should work here.
idSet: An array containing IDs you wish to filter by.

OUT:
QueryStream instance.

### QueryStream

It's a Readable Stream/EventEmitter.  See node docs: http://nodejs.org/api/stream.html#stream_class_stream_readable

METHODS:
pipe: Pipe to a Writable stream.
on: Listen to events.
update {idSet, select}: Update the idSet or select statement.  The query will automatically look for any new records that you should have access to, and any records/fields that need to be deleted.  The appropriate events will be sent down stream to any listeners.

## Options

See the applyDefaults function in [lib/main.coffee](https://github.com/TorchlightSoftware/mongo-watch/blob/master/lib/main.coffee) for a list of options and their defaults.

There are multiple formats that you can specify: [raw, pretty, normal].  You can set it like this:

```javascript
new MongoWatch({format: 'normal'})
```

'normal' is a normalized format and is recommended for most cases.  It breaks up combined updates into separate events, and turns inserts into 'set' events.  Here is an example insert event:

```javascript
event = {
  origin: 'payload'
  timestamp: new Date
  namespace: 'test.users'
  operationId: 'abc123'
  operation: 'set'
  path: '.'
  data: {email: 'graham@daventry.com'}
}
```

'raw' is the raw format straight from the oplog.  It is very terse and abbreviated.  Some info can be found here: http://www.kchodorow.com/blog/2010/10/12/replication-internals/

'pretty' has non-abbreviated field names but doesn't deviate from the raw format other than that.

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

## Future

I'd like to look at other options besides observing the oplog.  One option would be creating a capped collection for each collection we are listening to, and using these as message busses.  We can then monkey patch the mongodb connection to make it push to the audit logs, and then establish a cursor on each audit log in the same manner we are watching the oplog now.

This would give us the same sort of functionality, but it would work in shared hosting environments, and it would distance us from any problems related to the oplog format changing.  There have been some major changes to the format since mongo-watch was created, so this would be a big advantage.

## Credits

[Kristina Chodorow](http://www.kchodorow.com/blog/2010/10/12/replication-internals/) was very helpful both in documenting the oplog in her blog posts, and in answering some of my questions.  Christian Kvalheim's [code](https://github.com/christkv/realtime/blob/master/lib/app/dataproviders/flow_data_provider.js) served as the basis for the cursor connection.

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
