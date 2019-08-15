# Concepts

If you are relatively new to BTrDB, then there are a few things you should be
aware of about interacting with the server.  First of all, time series databases
such as BTrDB are not relational databases and so they behave differently, have
different access methods, and provide different guarantees.

The following sections provide insight into the high level objects and aspects
of their behavior which will allow you to use them effectively.

## BTrDB Server

Like most time series databases, the BTrDB server contains multiple streams of
data in which each stream contains a data point at a given time.  However,
BTrDB focuses on univariate data which opens a host of benefits and is one of
the reasons BTrDB is able to process incredibly large amounts of data quickly
and easily.

## Points

Points of data within a time series make up the smallest objects you will be
dealing with when making calls to the database.  Because there are different
types of interactions with the database, there are different types of points
that could be returned to you: :code:`RawPoint` and :code:`StatPoint`.

### RawPoint

The RawPoint represents a single time/value pair and is the simpler of the two
types of points.  This is most useful when you need to process every single
value within the stream.

### StatPoint

The StatPoint provides statistics about multiple points and gives
aggregation values such as `min`, `max`, `mean`, etc.  This is most useful when you
don't need to touch every individual value such as when you only need the count
of the values over a range of time.

These statistical queries execute in time proportional to the number of
results, not the number of underlying points (i.e logarithmic time) and so you
can attain valuable data in a fraction of the time when compared with retrieving
all of the individual values.  Due to the internal data structures, BTrDB does
not need to read the underlying points to return these statistics!

## Streams

Streams represent a single series of time/value pairs.  As such, the database
can hold an almost unlimited amount of individual streams.  Each stream has a
`collection` which is similar to a "path" or grouping for multiple streams.  Each
steam will also have a `name` as well as a `uuid` which is guaranteed to be unique
across streams.

BTrDB data is versioned such that changes to a given stream (time series) will
result in a new version for the stream.  In this manner, you can pin your interactions to a
specific version ensuring the values do not change over the course of your
interactions.  If you want to work with the most recent version/data then
specify a version of zero (the default).

Each stream has a number of attributes and methods available and these are documented
within the API section of this publication.  But the most common interactions
by users are to access the UUID, tags, annotations, version, and underlying data.

Each stream uses a UUID as its unique identifier which can also be used when querying
for streams.  Metadata is provided by tags and annotations which are both provided
as dictionaries of data.  Tags are used internally and have very specific keys
while annotations are more free-form and can be used by you to store your own
metadata.
