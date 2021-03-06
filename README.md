# A library for Dart developers for work with CouchDB

Created under a MIT-style
[license](https://github.com/YevhenKap/couchdb_dart/blob/master/LICENSE).

## Overview

> CouchDB is a database that completely embraces the web. Store your data with JSON documents. Access your documents with your web browser, via HTTP.

A basic understanding of CouchDB is required to using this library. Detailed information can be found at the [official documentation site](http://docs.couchdb.org/en/stable/api/basics.html).

### API

The connection to the database, along with authentication, is handled via `CouchDbClient` for both web and server environments.

Available three types of authentication:

    - Basic
    - Cookie
    - Proxy

For `Basic` authentication simply pass `username` and `password` to constructor:

```dart
final c = CouchDbClient(username: 'name', password: 'pass');
```

For `Cookie` authentication you also must provide `auth` parameter and then call `authenticate()` method
(note that cookies are valid for `10` minutes by default, other expiration you may specify in `Expiration` header):

```dart
final c = CouchDbClient(username: 'name', password: 'pass', auth: 'cookie');
final res = await c.authenticate();
```

> `authenticate()`, `logout()` are suitable only for `cookie` authentication.
> `userInfo()` are suitable for all auth types.

For `Proxy` authentication pass `username` to constructor and provide

- `X-Auth-CouchDB-UserName`: username (by default is used `username` that is passed to constructor, so it can be skipped);
- `X-Auth-CouchDB-Roles`: comma-separated (,) list of user roles;
- `X-Auth-CouchDB-Token`: authentication token. When `proxy_use_secret` is set (which is strongly recommended!), this header provides an HMAC of the username to authenticate and the secret token to prevent requests from untrusted sources (by default are used `username` and `secret` that are passed to constructor, so it can be skipped).

headers:

```dart
final c = CouchDbClient(username: 'name', auth: 'proxy', secret: '92de07df7e7a3fe14808cef90a7cc0d91');
c.modifyRequestHeaders(<String, String>{
  'X-Auth-CouchDB-Roles': 'users,blogger'
});
```

> Note that `X-Auth-CouchDB-Token` isn't required if **proxy_use_secret** sets to `false`.

    [couch_httpd_auth]
    proxy_use_secret = false

> Otherwise you may provide `secret` option which is used to generate token. The secret key should be the same on the client and the CouchDB node:

    [couch_httpd_auth]
    secret = 92de07df7e7a3fe14808cef90a7cc0d91

> To use this authentication method make sure that the {chttpd_auth, proxy_authentication_handler} value in added to the list of the active chttpd/authentication_handlers:

    [chttpd]
    authentication_handlers = {chttpd_auth, cookie_authentication_handler}, {chttpd_auth, proxy_authentication_handler}, {chttpd_auth, default_authentication_handler}

#### Anonymous user

You can configure access to your db to anonymous users.
To achieve this you must provide the following option (and don't set username and password to `CouchDbClient` constructor):

    [chttpd]
    require_valid_user = false

Otherwise, no requests will be allowed from anonymous users.

#### Client

You can communicate with the server directly if you wish via the http client methods such as `get()` and `post()`, however, other classes provide functions which can abstract away the particulars of HTTP, therefore using these client methods directly is not the way you will typically use this library.

Every supported method: `HEAD`, `GET`, `POST`, `PUT` and `COPY` - has an `Accept` header with default value as `application/json`, and `POST` and `PUT` both have a `Content-Type` header with default value as `application/json`.
You can override this if you need.

All requests, both those by the basic http methods, as well as those by the other classes we will go over in a moment, return a specific `...Response` object (see below). It contains various fields, about which you can find in [package API](https://pub.dev/documentation/couchdb/latest/).

Some method returns `Response` object (primary for all responses). It is contain an `Response.json` property (`Map` type) that contain JSON that was sent by CouchDB, `Response.raw` property (`String` type) for responses that aren't valid JSON (numbers, lists, files) and `Response.headers` property that contains headers of the response.
In order to gets concrete object representation of the response you may call methods of the `Response` class that can return:

    - ServerResponse
    - DatabaseResponse
    - DocumentResponse
    - DesignDocumentResponse
    - LocalDocumentResponse
    - ErrorResponse

Each of these class have specific properties that can be provided by CouchDB according to categories of API described below.

#### Categories

All of the API is divided into five areas or categories, each representing a different aspect of the database overall. These five categories are:

    1. Server
    2. Database
    3. Documents
    4. Design documents
    5. Local documents

##### 1: Server

Represented by the `Server` class. This class provides server-level interaction with CouchDB, such as managing replication or obtaining basic information about the server. Also it includes info about authentication and current user (methods in `CouchDbClient` class).

##### 2: Database

A Database in CouchDB is a single document store located on the given database server. This part of the API is represented by the `Database` class. You will use this class for interacting with your data on a database level; for example creating a new database or preforming a query to search for certain documents.

##### 3: Documents

You will use the `Document` class to interact with the data on a document level. This would include functions such as fetching a specific document, adding a new document, or attaching a file to a document. Note that this class does not model the documents themselves, but rather your interactions with them. The documents themselves are represented as `Map`s.

##### 4: Design Documents

Represented by the `DesignDocument`, design documents provide views of data in the database.

##### 5: Local Documents

Local documents are no different than normal documents, with the exception that they are not copied to other instances of CouchDB during replication. You will interact with them via the `LocalDocument` class.

### CORS

CORS is a method of enabling a web app to talk to a server other than the server hosting it. It is only necessary if the application is running in the browser.

#### CouchDB Server Configuration for CORS

If the application isn't on the same origin with CouchDB instance (or you using different ports on server), then the remote CouchDB must be configured with the following options:

    [httpd]
    enable_cors = true
    [cors]
    origins = *
    credentials = true
    methods = GET, PUT, POST, HEAD, DELETE, COPY
    headers = accept, authorization, content-type, origin, referer, x-csrf-token

Change these settings either in Fauxton configuration utility or in the CouchDb local.ini file. For better security, specify specific domains instead of * in the `origins` section.

#### Browser Client Configuration for CORS

Depending on the browser, you might also need to pass `cors=true` to the `CouchBdClient` constructor. However, most of the time the browser will handle this for you and this shouldn't be necessary. In fact, it might cause an "Unsafe Header" message in the browser console.

## Usage

A simple usage example:

```dart
import 'package:couchdb/couchdb.dart';

Future<void> main() async {
  final client = CouchDbClient(username: 'name', password: 'password');
  final db = Database(client);
  final doc = Document(client);

  try {
    final DatabaseResponse response1 = await db.allDocs('some_db');

    for (var i in response1.rows) {
      // Some code here
    }

    final DocumentResponse response2 = await doc.doc('another_db', 'some_id');

    var thing = response2.json['some_attribute'];

  } on CouchDbException catch (e) {
    print('$e - error');
  }
}
```

## Features and bugs

Please file feature requests and bugs at the [issue tracker][tracker].

[tracker]: https://github.com/YevhenKap/couchdb_dart/issues

**With ❤️ to CouchDB**
