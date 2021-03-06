import 'dart:convert';

import 'package:meta/meta.dart';

import '../clients/couchdb_client.dart';
import '../responses/database_response.dart';
import '../responses/response.dart';
import '../exceptions/couchdb_exception.dart';
import '../utils/includer_path.dart';
import 'component.dart';

/// Class that implements methods for interacting with entire database
/// in CouchDB
class Database extends Component {
  /// Create Database by accepting web-based or server-based client
  Database(CouchDbClient client) : super(client);

  /// Returns the HTTP Headers containing a minimal amount of information
  /// about the specified database.
  Future<DatabaseResponse> headDbInfo(String dbName) async {
    Response info;
    try {
      info = await client.head(dbName);
    } on CouchDbException catch (e) {
      e.response = Response(<String, String>{
        'error': 'Not found',
        'reason': 'Database doesn\'t exist.'
      }).errorResponse();
      rethrow;
    }
    return info.databaseResponse();
  }

  /// Gets information about the specified database
  ///
  /// Returns JSON like:
  /// ```json
  /// {
  ///     "cluster": {
  ///         "n": 3,
  ///         "q": 8,
  ///         "r": 2,
  ///         "w": 2
  ///     },
  ///     "compact_running": false,
  ///     "data_size": 65031503,
  ///     "db_name": "receipts",
  ///     "disk_format_version": 6,
  ///     "disk_size": 137433211,
  ///     "doc_count": 6146,
  ///     "doc_del_count": 64637,
  ///     "instance_start_time": "0",
  ///     "other": {
  ///         "data_size": 66982448
  ///     },
  ///     "purge_seq": 0,
  ///     "sizes": {
  ///         "active": 65031503,
  ///         "external": 66982448,
  ///         "file": 137433211
  ///     },
  ///     "update_seq": "292786-g1AAAAF..."
  /// }
  /// ```
  Future<DatabaseResponse> dbInfo(String dbName) async {
    Response info;
    try {
      info = await client.get(dbName);
    } on CouchDbException {
      rethrow;
    }
    return info.databaseResponse();
  }

  /// Creates a new database
  ///
  /// Returns JSON like:
  /// ```json
  /// {
  ///     "ok": true
  /// }
  /// ```
  ///
  /// Otherwise error response is returned.
  Future<DatabaseResponse> createDb(String dbName, {int q = 8}) async {
    final regexp = RegExp(r'^[a-z][a-z0-9_$()+/-]*$');
    Response result;

    if (!regexp.hasMatch(dbName)) {
      throw ArgumentError(r'''Incorrect db name!
      Name must be validating by this rules:
        - Name must begin with a lowercase letter (a-z)
        - Lowercase characters (a-z)
        - Digits (0-9)
        - Any of the characters _, $, (, ), +, -, and /.''');
    }

    final path = '$dbName?q=$q';
    try {
      result = await client.put(path);
    } on CouchDbException {
      rethrow;
    }
    return result.databaseResponse();
  }

  /// Deletes the specified database, and all the documents and attachments contained within it
  ///
  /// Returns JSON like:
  /// ```json
  /// {
  ///     "ok": true
  /// }
  /// ```
  ///
  /// Otherwise error response is returned.
  Future<DatabaseResponse> deleteDb(String dbName) async {
    Response result;

    try {
      result = await client.delete(dbName);
    } on CouchDbException {
      rethrow;
    }
    return result.databaseResponse();
  }

  /// Creates a new document in the specified database, using the supplied JSON document structure
  ///
  /// Returns JSON like:
  /// ```json
  /// {
  ///     "id": "ab39fe0993049b84cfa81acd6ebad09d",
  ///     "ok": true,
  ///     "rev": "1-9c65296036141e575d32ba9c034dd3ee"
  /// }
  /// ```
  Future<DatabaseResponse> createDocIn(String dbName, Map<String, Object> doc,
      {String batch, Map<String, String> headers}) async {
    Response result;

    final path = '$dbName${includeNonNullParam('?batch', batch)}';

    try {
      result = await client.post(path, body: doc, reqHeaders: headers);
    } on CouchDbException {
      rethrow;
    }
    return result.databaseResponse();
  }

  /// Executes the built-in _all_docs view, returning all of the documents in the database
  ///
  /// Returns JSON like:
  /// ```json
  /// {
  ///     "offset": 0,
  ///     "rows": [
  ///         {
  ///             "id": "16e458537602f5ef2a710089dffd9453",
  ///             "key": "16e458537602f5ef2a710089dffd9453",
  ///             "value": {
  ///                 "rev": "1-967a00dff5e02add41819138abb3284d"
  ///             }
  ///         },
  ///         {
  ///             "id": "a4c51cdfa2069f3e905c431114001aff",
  ///             "key": "a4c51cdfa2069f3e905c431114001aff",
  ///             "value": {
  ///                 "rev": "1-967a00dff5e02add41819138abb3284d"
  ///             }
  ///         }
  ///     ],
  ///     "total_rows": 2
  /// }
  /// ```
  Future<DatabaseResponse> allDocs(String dbName,
      {bool conflicts = false,
      bool descending = false,
      Object endKey,
      String endKeyDocId,
      bool group = false,
      int groupLevel,
      bool includeDocs = false,
      bool attachments = false,
      bool altEncodingInfo = false,
      bool inclusiveEnd = true,
      Object key,
      List<Object> keys,
      int limit,
      bool reduce,
      int skip,
      bool sorted = true,
      bool stable = false,
      String stale,
      Object startKey,
      String startKeyDocId,
      String update,
      bool updateSeq = false}) async {
    Response result;

    try {
      result = await client.get('$dbName/_all_docs'
          '?conflicts=$conflicts'
          '&descending=$descending'
          '&${includeNonNullJsonParam("endkey", endKey)}'
          '&${includeNonNullParam("endkey_docid", endKeyDocId)}'
          '&group=$group'
          '&${includeNonNullParam("group_level", groupLevel)}'
          '&include_docs=$includeDocs'
          '&attachments=$attachments'
          '&alt_encoding_info=$altEncodingInfo'
          '&inclusive_end=$inclusiveEnd'
          '&${includeNonNullJsonParam("key", key)}'
          '&${includeNonNullJsonParam("keys", keys)}'
          '&${includeNonNullParam("limit", limit)}'
          '&${includeNonNullParam("reduce", reduce)}'
          '&${includeNonNullParam("skip", skip)}'
          '&sorted=$sorted'
          '&stable=$stable'
          '&${includeNonNullParam("stale", stale)}'
          '&${includeNonNullJsonParam("startkey", startKey)}'
          '&${includeNonNullParam("startkey_docid", startKeyDocId)}'
          '&${includeNonNullParam("update", update)}'
          '&update_seq=$updateSeq');
    } on CouchDbException {
      rethrow;
    }
    return result.databaseResponse();
  }

  /// Executes the built-in _all_docs view, returning specified documents in the database
  ///
  /// The POST to _all_docs allows to specify multiple [keys] to be selected from the database.
  /// This enables you to request multiple documents in a single request, in place of multiple [getDoc()] requests.
  ///
  /// Returns JSON like:
  /// ```json
  /// {
  ///     "offset": 0,
  ///     "rows": [
  ///         {
  ///             "id": "16e458537602f5ef2a710089dffd9453",
  ///             "key": "16e458537602f5ef2a710089dffd9453",
  ///             "value": {
  ///                 "rev": "1-967a00dff5e02add41819138abb3284d"
  ///             }
  ///         },
  ///         {
  ///             "id": "a4c51cdfa2069f3e905c431114001aff",
  ///             "key": "a4c51cdfa2069f3e905c431114001aff",
  ///             "value": {
  ///                 "rev": "1-967a00dff5e02add41819138abb3284d"
  ///             }
  ///         }
  ///     ],
  ///     "total_rows": 2453
  /// }
  /// ```
  Future<DatabaseResponse> docsByKeys(String dbName,
      {List<String> keys}) async {
    Response result;

    final body = <String, List<String>>{'keys': keys};

    try {
      result = keys == null
          ? await client.post('$dbName/_all_docs')
          : await client.post('$dbName/_all_docs', body: body);
    } on CouchDbException {
      rethrow;
    }
    return result.databaseResponse();
  }

  /// Returns a JSON structure of all of the design documents in a given database
  ///
  /// Returns JSON like:
  /// ```json
  /// {
  ///     "offset": 0,
  ///     "rows": [
  ///         {
  ///             "id": "_design/16e458537602f5ef2a710089dffd9453",
  ///             "key": "_design/16e458537602f5ef2a710089dffd9453",
  ///             "value": {
  ///                 "rev": "1-967a00dff5e02add41819138abb3284d"
  ///             }
  ///         },
  ///         {
  ///             "id": "_design/a4c51cdfa2069f3e905c431114001aff",
  ///             "key": "_design/a4c51cdfa2069f3e905c431114001aff",
  ///             "value": {
  ///                 "rev": "1-967a00dff5e02add41819138abb3284d"
  ///             }
  ///         }
  ///     ],
  ///     "total_rows": 2
  /// }
  /// ```
  Future<DatabaseResponse> allDesignDocs(String dbName,
      {bool conflicts = false,
      bool descending = false,
      String endKey,
      String endKeyDocId,
      bool includeDocs = false,
      bool inclusiveEnd = true,
      String key,
      String keys,
      int limit,
      int skip = 0,
      String startKey,
      String startKeyDocId,
      bool updateSeq = false}) async {
    Response result;

    final path =
        '$dbName/_design_docs?conflicts=$conflicts&descending=$descending&'
        '${includeNonNullParam('endkey', endKey)}&${includeNonNullParam('endkey_docid', endKeyDocId)}&'
        'include_docs=$includeDocs&inclusive_end=$inclusiveEnd&${includeNonNullParam('key', key)}&'
        '${includeNonNullParam('keys', keys)}&${includeNonNullParam('limit', limit)}&'
        'skip=$skip&${includeNonNullParam('startkey', startKey)}&${includeNonNullParam('startkey_docid', startKeyDocId)}&'
        'update_seq=$updateSeq';

    try {
      result = await client.get(path);
    } on CouchDbException {
      rethrow;
    }
    return result.databaseResponse();
  }

  /// Returns a JSON structure of specified design documents in a given database
  ///
  /// The POST to _design_docs allows to specify multiple [keys] to be selected from the database.
  /// This enables you to request multiple design documents in a single request, in place of multiple [designDoc()] requests
  ///
  /// Returns JSON like:
  /// ```json
  /// {
  ///     "offset": 0,
  ///     "rows": [
  ///         {
  ///             "id": "_design/16e458537602f5ef2a710089dffd9453",
  ///             "key": "_design/16e458537602f5ef2a710089dffd9453",
  ///             "value": {
  ///                 "rev": "1-967a00dff5e02add41819138abb3284d"
  ///             }
  ///         },
  ///         {
  ///             "id": "_design/a4c51cdfa2069f3e905c431114001aff",
  ///             "key": "_design/a4c51cdfa2069f3e905c431114001aff",
  ///             "value": {
  ///                 "rev": "1-967a00dff5e02add41819138abb3284d"
  ///             }
  ///         }
  ///     ],
  ///     "total_rows": 6
  /// }
  /// ```
  Future<DatabaseResponse> designDocsByKeys(
      String dbName, List<String> keys) async {
    Response result;

    final body = <String, List<String>>{'keys': keys};

    try {
      result = await client.post('$dbName/_design_docs', body: body);
    } on CouchDbException {
      rethrow;
    }
    return result.databaseResponse();
  }

  /// Executes multiple specified built-in view queries of all documents in this database
  ///
  /// Returns JSON like:
  /// ```json
  /// {
  ///     "results" : [
  ///         {
  ///             "rows": [
  ///                 {
  ///                     "id": "SpaghettiWithMeatballs",
  ///                     "key": "meatballs",
  ///                     "value": 1
  ///                 },
  ///                 {
  ///                     "id": "SpaghettiWithMeatballs",
  ///                     "key": "spaghetti",
  ///                     "value": 1
  ///                 },
  ///                 {
  ///                     "id": "SpaghettiWithMeatballs",
  ///                     "key": "tomato sauce",
  ///                     "value": 1
  ///                 }
  ///             ],
  ///             "total_rows": 3
  ///         },
  ///         {
  ///             "offset" : 2,
  ///             "rows" : [
  ///                 {
  ///                     "id" : "Adukiandorangecasserole-microwave",
  ///                     "key" : "Aduki and orange casserole - microwave",
  ///                     "value" : [
  ///                         null,
  ///                         "Aduki and orange casserole - microwave"
  ///                     ]
  ///                 },
  ///                 {
  ///                     "id" : "Aioli-garlicmayonnaise",
  ///                     "key" : "Aioli - garlic mayonnaise",
  ///                     "value" : [
  ///                         null,
  ///                         "Aioli - garlic mayonnaise"
  ///                     ]
  ///                 },
  ///                 {
  ///                     "id" : "Alabamapeanutchicken",
  ///                     "key" : "Alabama peanut chicken",
  ///                     "value" : [
  ///                         null,
  ///                         "Alabama peanut chicken"
  ///                     ]
  ///                 }
  ///             ],
  ///             "total_rows" : 2667
  ///         }
  ///     ]
  /// }
  /// ```
  Future<DatabaseResponse> queriesDocsFrom(
      String dbName, List<Map<String, Object>> queries) async {
    Response result;

    final body = <String, List<Map<String, Object>>>{'queries': queries};

    try {
      result = await client.post('$dbName/_all_docs/queries', body: body);
    } on CouchDbException {
      rethrow;
    }
    return result.databaseResponse();
  }

  /// Queries several documents in bulk
  ///
  /// Returns JSON like:
  /// ```json
  /// {
  ///   "results": [
  ///     {
  ///       "id": "foo",
  ///       "docs": [
  ///         {
  ///           "ok": {
  ///             "_id": "bbb",
  ///             "_rev": "4-753875d51501a6b1883a9d62b4d33f91",
  ///             "value": "this is foo",
  ///             "_revisions": {
  ///               "start": 4,
  ///               "ids": [
  ///                 "753875d51501a6b1883a9d62b4d33f91",
  ///                 "efc54218773c6acd910e2e97fea2a608",
  ///                 "2ee767305024673cfb3f5af037cd2729",
  ///                 "4a7e4ae49c4366eaed8edeaea8f784ad"
  ///               ]
  ///             }
  ///           }
  ///         }
  ///       ]
  ///     },
  ///     {
  ///       "id": "foo",
  ///       "docs": [
  ///         {
  ///           "ok": {
  ///             "_id": "bbb",
  ///             "_rev": "1-4a7e4ae49c4366eaed8edeaea8f784ad",
  ///             "value": "this is the first revision of foo",
  ///             "_revisions": {
  ///               "start": 1,
  ///               "ids": [
  ///                 "4a7e4ae49c4366eaed8edeaea8f784ad"
  ///               ]
  ///             }
  ///           }
  ///         }
  ///       ]
  ///     },
  ///     {
  ///       "id": "bar",
  ///       "docs": [
  ///         {
  ///           "ok": {
  ///             "_id": "bar",
  ///             "_rev": "2-9b71d36dfdd9b4815388eb91cc8fb61d",
  ///             "baz": true,
  ///             "_revisions": {
  ///               "start": 2,
  ///               "ids": [
  ///                 "9b71d36dfdd9b4815388eb91cc8fb61d",
  ///                 "309651b95df56d52658650fb64257b97"
  ///               ]
  ///             }
  ///           }
  ///         }
  ///       ]
  ///     }
  ///   ]
  /// }
  /// ```
  Future<DatabaseResponse> bulkDocs(String dbName, List<Object> docs,
      {@required bool revs}) async {
    Response result;

    final body = <String, List<Object>>{'docs': docs};

    try {
      result = await client.post('$dbName?revs=$revs', body: body);
    } on CouchDbException {
      rethrow;
    }
    return result.databaseResponse();
  }

  /// Creates and updates multiple documents at the same time within a single request
  ///
  /// Returns JSON like:
  /// ```json
  /// [
  ///     {
  ///         "ok": true,
  ///         "id": "FishStew",
  ///         "rev":" 1-967a00dff5e02add41819138abb3284d"
  ///     },
  ///     {
  ///         "ok": true,
  ///         "id": "LambStew",
  ///         "rev": "3-f9c62b2169d0999103e9f41949090807"
  ///     }
  /// ]
  /// ```
  Future<DatabaseResponse> insertBulkDocs(String dbName, List<Object> docs,
      {bool newEdits = true, Map<String, String> headers}) async {
    Response result;

    final body = <String, Object>{'docs': docs, 'new_edits': newEdits};

    try {
      result = await client.post('$dbName/_bulk_docs',
          body: body, reqHeaders: headers);
    } on CouchDbException {
      rethrow;
    }
    return result.databaseResponse();
  }

  /// Find documents using a declarative JSON querying syntax
  ///
  /// Returns JSON like:
  /// ```json
  /// {
  ///     "docs": [
  ///         {
  ///             "_id": "176694",
  ///             "_rev": "1-54f8e950cc338d2385d9b0cda2fd918e",
  ///             "year": 2011,
  ///             "title": "The Tragedy of Man"
  ///         },
  ///         {
  ///             "_id": "780504",
  ///             "_rev": "1-5f14bab1a1e9ac3ebdf85905f47fb084",
  ///             "year": 2011,
  ///             "title": "Drive"
  ///         }
  ///     ],
  ///     "execution_stats": {
  ///         "total_keys_examined": 0,
  ///         "total_docs_examined": 200,
  ///         "total_quorum_docs_examined": 0,
  ///         "results_returned": 2,
  ///         "execution_time_ms": 5.52
  ///     }
  /// }
  /// ```
  Future<DatabaseResponse> find(String dbName, Map<String, Object> selector,
      {int limit = 25,
      int skip,
      List<Object> sort,
      List<String> fields,
      Object useIndex,
      int r = 1,
      String bookmark,
      bool update = true,
      bool stable,
      String stale = 'false',
      bool executionStats = false}) async {
    Response result;

    final body = <String, Object>{
      'selector': selector,
      'limit': limit,
      'r': r,
      'bookmark': bookmark,
      'update': update,
      'stale': stale,
      'execution_stats': executionStats
    };
    if (skip != null) {
      body['skip'] = skip;
    }
    if (sort != null) {
      body['sort'] = sort;
    }
    if (fields != null) {
      body['fields'] = fields;
    }
    if (useIndex != null) {
      body['use_index'] = useIndex;
    }
    if (stable != null) {
      body['stable'] = stable;
    }

    try {
      result = await client.post('$dbName/_find', body: body);
    } on CouchDbException {
      rethrow;
    }
    return result.databaseResponse();
  }

  /// Create a new index on a database
  ///
  /// Returns JSON like:
  /// ```json
  /// {
  ///     "result": "created",
  ///     "id": "_design/a5f4711fc9448864a13c81dc71e660b524d7410c",
  ///     "name": "foo-index"
  /// }
  /// ```
  Future<DatabaseResponse> createIndexIn(String dbName,
      {@required List<String> indexFields,
      String ddoc,
      String name,
      String type = 'json',
      Map<String, Object> partialFilterSelector}) async {
    Response result;

    final body = <String, Object>{
      'index': <String, List<String>>{'fields': indexFields},
      'type': type
    };
    if (ddoc != null) {
      body['ddoc'] = ddoc;
    }
    if (name != null) {
      body['name'] = name;
    }
    if (partialFilterSelector != null) {
      body['partial_filter_selector'] = partialFilterSelector;
    }

    try {
      result = await client.post('$dbName/_index', body: body);
    } on CouchDbException {
      rethrow;
    }
    return result.databaseResponse();
  }

  /// Gets a list of all indexes in the database
  ///
  /// Returns JSON like:
  /// ```json
  /// {
  ///     "total_rows": 2,
  ///     "indexes": [
  ///     {
  ///         "ddoc": null,
  ///         "name": "_all_docs",
  ///         "type": "special",
  ///         "def": {
  ///             "fields": [
  ///                 {
  ///                     "_id": "asc"
  ///                 }
  ///             ]
  ///         }
  ///     },
  ///     {
  ///         "ddoc": "_design/a5f4711fc9448864a13c81dc71e660b524d7410c",
  ///         "name": "foo-index",
  ///         "type": "json",
  ///         "def": {
  ///             "fields": [
  ///                 {
  ///                     "foo": "asc"
  ///                 }
  ///             ]
  ///         }
  ///     }
  ///   ]
  /// }
  /// ```
  Future<DatabaseResponse> indexesAt(String dbName) async {
    Response result;

    try {
      result = await client.get('$dbName/_index');
    } on CouchDbException {
      rethrow;
    }
    return result.databaseResponse();
  }

  /// Delets index in the database
  ///
  /// Returns JSON like:
  /// ```json
  /// {
  ///     "ok": "true"
  /// }
  /// ```
  Future<DatabaseResponse> deleteIndexIn(
      String dbName, String designDoc, String name) async {
    Response result;

    try {
      result = await client.delete('$dbName/_index/$designDoc/json/$name');
    } on CouchDbException {
      rethrow;
    }
    return result.databaseResponse();
  }

  /// Shows which index is being used by the query
  ///
  /// Returns JSON like:
  /// ```json
  /// {
  ///     "dbname": "movies",
  ///     "index": {
  ///         "ddoc": "_design/0d61d9177426b1e2aa8d0fe732ec6e506f5d443c",
  ///         "name": "0d61d9177426b1e2aa8d0fe732ec6e506f5d443c",
  ///         "type": "json",
  ///         "def": {
  ///             "fields": [
  ///                 {
  ///                     "year": "asc"
  ///                 }
  ///             ]
  ///         }
  ///     },
  ///     "selector": {
  ///         "year": {
  ///             "$gt": 2010
  ///         }
  ///     },
  ///     "opts": {
  ///         "use_index": [],
  ///         "bookmark": "nil",
  ///         "limit": 2,
  ///         "skip": 0,
  ///         "sort": {},
  ///         "fields": [
  ///             "_id",
  ///             "_rev",
  ///             "year",
  ///             "title"
  ///         ],
  ///         "r": [
  ///             49
  ///         ],
  ///         "conflicts": false
  ///     },
  ///     "limit": 2,
  ///     "skip": 0,
  ///     "fields": [
  ///         "_id",
  ///         "_rev",
  ///         "year",
  ///         "title"
  ///     ],
  ///     "range": {
  ///         "start_key": [
  ///             2010
  ///         ],
  ///         "end_key": [
  ///             {}
  ///         ]
  ///     }
  /// }
  /// ```
  Future<DatabaseResponse> explain(String dbName, Map<String, Object> selector,
      {int limit = 25,
      int skip,
      List<Object> sort,
      List<String> fields,
      Object useIndex,
      int r = 1,
      String bookmark,
      bool update = true,
      bool stable,
      String stale = 'false',
      bool executionStats = false}) async {
    Response result;

    final body = <String, Object>{
      'selector': selector,
      'limit': limit,
      'r': r,
      'bookmark': bookmark,
      'update': update,
      'stale': stale,
      'execution_stats': executionStats
    };
    if (skip != null) {
      body['skip'] = skip;
    }
    if (sort != null) {
      body['sort'] = sort;
    }
    if (fields != null) {
      body['fields'] = fields;
    }
    if (useIndex != null) {
      body['use_index'] = useIndex;
    }
    if (stable != null) {
      body['stable'] = stable;
    }

    try {
      result = await client.post('$dbName/_explain', body: body);
    } on CouchDbException {
      rethrow;
    }
    return result.databaseResponse();
  }

  /// Returns a list of database shards. Each shard will have its internal
  /// database range, and the nodes on which replicas of those shards are stored
  ///
  /// Returns JSON like:
  /// ```dart
  /// {
  ///   "shards": {
  ///     "00000000-1fffffff": [
  ///       "couchdb@node1.example.com",
  ///       "couchdb@node2.example.com",
  ///       "couchdb@node3.example.com"
  ///     ],
  ///     "20000000-3fffffff": [
  ///       "couchdb@node1.example.com",
  ///       "couchdb@node2.example.com",
  ///       "couchdb@node3.example.com"
  ///     ]
  ///   }
  /// }
  /// ```
  Future<DatabaseResponse> shards(String dbName) async {
    Response result;

    try {
      result = await client.get('$dbName/_shards');
    } on CouchDbException {
      rethrow;
    }
    return result.databaseResponse();
  }

  /// Returns information about the specific shard into which a given document
  /// has been stored, along with information about the nodes on which that
  /// shard has a replica
  ///
  /// Returns JSON like:
  /// ```dart
  /// {
  ///   "range": "e0000000-ffffffff",
  ///   "nodes": [
  ///     "node1@127.0.0.1",
  ///     "node2@127.0.0.1",
  ///     "node3@127.0.0.1"
  ///   ]
  /// }
  /// ```
  Future<DatabaseResponse> shard(String dbName, String docId) async {
    Response result;

    try {
      result = await client.get('$dbName/_shards/$docId');
    } on CouchDbException {
      rethrow;
    }
    return result.databaseResponse();
  }

  /// For the given database, force-starts internal shard synchronization
  /// for all replicas of all database shards
  ///
  /// This is typically only used when performing cluster maintenance,
  /// such as moving a shard.
  ///
  /// Returns JSON like:
  /// ```dart
  /// {
  ///     "ok": true
  /// }
  /// ```
  Future<DatabaseResponse> synchronizeShards(String dbName) async {
    Response result;

    try {
      result = await client.post('$dbName/_sync_shards');
    } on CouchDbException {
      rethrow;
    }
    return result.databaseResponse();
  }

  /// Returns a sorted list of changes made to documents in the database
  ///
  /// [feed] may be one from:
  ///
  ///     - `normal`
  ///     - `longpoll`
  ///     - `continuous`
  ///     - `eventsource`
  ///
  /// For `eventsource` value of [feed] JSON response placed at `results` field
  ///  with `Map` objects with two fields `data` and `id`.
  /// `last_seq` and `pending` fields are missing in returned JSON if [feed]
  /// have `eventsource` or `continuous` values.
  ///
  /// [Read more about difference between above values.](http://docs.couchdb.org/en/stable/api/database/changes.html#changes-feeds)
  ///
  /// Returns JSON like:
  /// ```json
  /// {
  ///     "last_seq": "5-g1AAAAIreJyVkEsKwjAURZ-toI5cgq5A0sQ0OrI70XyppcaRY
  /// 92J7kR3ojupaSPUUgotgRd4yTlwbw4A0zRUMLdnpaMkwmyF3Ily9xBwEIuiKLI05KOT
  /// W0wkV4rruP29UyGWbordzwKVxWBNOGMKZhertDlarbr5pOT3DV4gudUC9-MPJX9tpEA
  /// Yx4TQASns2E24ucuJ7rXJSL1BbEgf3vTwpmedCZkYa7Pulck7Xt7x_usFU2aIHOD4e
  /// EfVTVA5KMGUkqhNZV-8_o5i",
  ///     "pending": 0,
  ///     "results": [
  ///         {
  ///             "changes": [
  ///                 {
  ///                     "rev": "2-7051cbe5c8faecd085a3fa619e6e6337"
  ///                 }
  ///             ],
  ///             "id": "6478c2ae800dfc387396d14e1fc39626",
  ///             "seq": "3-g1AAAAG3eJzLYWBg4MhgTmHgz8tPSTV0MDQy1zMAQsMcoAR
  /// TIkOS_P___7MSGXAqSVIAkkn2IFUZzIkMuUAee5pRqnGiuXkKA2dpXkpqWmZeagpu_Q4
  /// g_fGEbEkAqaqH2sIItsXAyMjM2NgUUwdOU_JYgCRDA5ACGjQfn30QlQsgKvcjfGaQZma
  /// UmmZClM8gZhyAmHGfsG0PICrBPmQC22ZqbGRqamyIqSsLAAArcXo"
  ///         },
  ///         {
  ///             "changes": [
  ///                 {
  ///                     "rev": "3-7379b9e515b161226c6559d90c4dc49f"
  ///                 }
  ///             ],
  ///             "deleted": true,
  ///             "id": "5bbc9ca465f1b0fcd62362168a7c8831",
  ///             "seq": "4-g1AAAAHXeJzLYWBg4MhgTmHgz8tPSTV0MDQy1zMAQsMcoAR
  /// TIkOS_P___7MymBMZc4EC7MmJKSmJqWaYynEakaQAJJPsoaYwgE1JM0o1TjQ3T2HgLM1L
  /// SU3LzEtNwa3fAaQ_HqQ_kQG3qgSQqnoUtxoYGZkZG5uS4NY8FiDJ0ACkgAbNx2cfROUCi
  /// Mr9CJ8ZpJkZpaaZEOUziBkHIGbcJ2zbA4hKsA-ZwLaZGhuZmhobYurKAgCz33kh"
  ///         },
  ///         {
  ///             "changes": [
  ///                 {
  ///                     "rev": "6-460637e73a6288cb24d532bf91f32969"
  ///                 },
  ///                 {
  ///                     "rev": "5-eeaa298781f60b7bcae0c91bdedd1b87"
  ///                 }
  ///             ],
  ///             "id": "729eb57437745e506b333068fff665ae",
  ///             "seq": "5-g1AAAAIReJyVkE0OgjAQRkcwUVceQU9g-mOpruQm2tI2SLCuX
  /// OtN9CZ6E70JFmpCCCFCmkyTdt6bfJMDwDQNFcztWWkcY8JXyB2cu49AgFwURZGloRid3MMk
  /// EUoJHbXbOxVy6arc_SxQWQzRVHCuYHaxSpuj1aqbj0t-3-AlSrZakn78oeSvjRSIkIhSNiC
  /// FHbsKN3c50b02mURvEB-yD296eNOzzoRMRLRZ98rkHS_veGcC_nR-fGe1gaCaxihhjOI2lX
  /// 0BhniHaA"
  ///         }
  ///     ]
  /// }
  /// ```
  Future<Stream<DatabaseResponse>> changesIn(String dbName,
      {List<String> docIds,
      bool conflicts = false,
      bool descending = false,
      String feed = 'normal',
      String filter,
      int heartbeat = 60000,
      bool includeDocs = false,
      bool attachments = false,
      bool attEncodingInfo = false,
      int lastEventId,
      int limit,
      String since = '0',
      String style = 'main_only',
      int timeout = 60000,
      String view,
      int seqInterval}) async {
    Stream<DatabaseResponse> result;

    final path =
        '$dbName/_changes?${includeNonNullParam('doc_ids', docIds)}&conflicts=$conflicts&'
        'descending=$descending&feed=$feed&${includeNonNullParam('filter', filter)}&heartbeat=$heartbeat&'
        'include_docs=$includeDocs&attachments=$attachments&att_encoding_info=$attEncodingInfo&'
        '${includeNonNullParam('last-event-id', lastEventId)}&${includeNonNullParam('limit', limit)}&'
        'since=$since&style=$style&timeout=$timeout&${includeNonNullParam('view', view)}&'
        '${includeNonNullParam('seq_interval', seqInterval)}';

    try {
      final streamedRes = await client.streamed('get', path);
      switch (feed) {
        case 'longpoll':
          var strRes = await streamedRes.join();
          strRes = '{"result": [$strRes';
          result = Stream<DatabaseResponse>.fromFuture(
              Future<DatabaseResponse>.value(
                  Response(jsonDecode(strRes)).databaseResponse()));
          break;
        case 'continuous':
          final mappedRes =
              streamedRes.map((v) => v.replaceAll('}\n{', '},\n{'));
          result = mappedRes.map((v) =>
              Response(jsonDecode('{"result": [$v]}')).databaseResponse());
          break;
        case 'eventsource':
          final mappedRes = streamedRes
              .map((v) => v.replaceAll(RegExp('\n+data'), '},\n{data'))
              .map((v) => v.replaceAll('data', '"data"'))
              .map((v) => v.replaceAll('\nid', ',\n"id"'));
          result = mappedRes.map((v) =>
              Response(jsonDecode('{"result": [{$v}]}')).databaseResponse());
          break;
        default:
          var strRes = await streamedRes.join();
          strRes = '{"result": [$strRes';
          result = Stream<DatabaseResponse>.fromFuture(
              Future<DatabaseResponse>.value(
                  Response(jsonDecode(strRes)).databaseResponse()));
      }
    } on CouchDbException {
      rethrow;
    }
    return result;
  }

  /// Requests the database changes feed in the same way as [changesIn()] does,
  /// but is widely used with [filter]='_doc_ids' query parameter and allows
  /// one to pass a larger list of document IDs to [filter]
  ///
  /// Returns JSON like:
  /// ```json
  /// {
  ///     "last_seq": "5-g1AAAAIreJyVkEsKwjAURZ-toI5cgq5A0sQ0OrI70XyppcaRY92J7kR3ojupaSPUUgotgRd4yTlwbw4A0zRUMLdnpaMkwmyF3Ily9xBwEIuiKLI05KOTW0wkV4rruP29UyGWbordzwKVxWBNOGMKZhertDlarbr5pOT3DV4gudUC9-MPJX9tpEAYx4TQASns2E24ucuJ7rXJSL1BbEgf3vTwpmedCZkYa7Pulck7Xt7x_usFU2aIHOD4eEfVTVA5KMGUkqhNZV8_o5i",
  ///     "pending": 0,
  ///     "results": [
  ///         {
  ///             "changes": [
  ///                 {
  ///                     "rev": "13-bcb9d6388b60fd1e960d9ec4e8e3f29e"
  ///                 }
  ///             ],
  ///             "id": "SpaghettiWithMeatballs",
  ///             "seq":  "5-g1AAAAIReJyVkE0OgjAQRkcwUVceQU9g-mOpruQm2tI2SLCuXOtN9CZ6E70JFmpCCCFCmkyTdt6bfJMDwDQNFcztWWkcY8JXyB2cu49AgFwURZGloRid3MMkEUoJHbXbOxVy6arc_SxQWQzRVHCuYHaxSpuj1aqbj0t-3-AlSrZakn78oeSvjRSIkIhSNiCFHbsKN3c50b02mURvEB-yD296eNOzzoRMRLRZ98rkHS_veGcC_nR-fGe1gaCaxihhjOI2lX0BhniHaA"
  ///         }
  ///     ]
  /// }
  /// ```
  Future<Stream<DatabaseResponse>> postChangesIn(String dbName,
      {List<String> docIds,
      bool conflicts = false,
      bool descending = false,
      String feed = 'normal',
      String filter = '_doc_ids',
      int heartbeat = 60000,
      bool includeDocs = false,
      bool attachments = false,
      bool attEncodingInfo = false,
      int lastEventId,
      int limit,
      String since = '0',
      String style = 'main_only',
      int timeout = 60000,
      String view,
      int seqInterval}) async {
    Stream<DatabaseResponse> result;

    final path = '$dbName/_changes?conflicts=$conflicts&'
        'descending=$descending&feed=$feed&filter=$filter&heartbeat=$heartbeat&'
        'include_docs=$includeDocs&attachments=$attachments&att_encoding_info=$attEncodingInfo&'
        '${includeNonNullParam('last-event-id', lastEventId)}&${includeNonNullParam('limit', limit)}&'
        'since=$since&style=$style&timeout=$timeout&${includeNonNullParam('view', view)}&'
        '${includeNonNullParam('seq_interval', seqInterval)}';

    final body = <String, List<String>>{'doc_ids': docIds};

    try {
      //result = await client.post(path, body: body);
      final streamedRes = await client.streamed('post', path, body: body);
      switch (feed) {
        case 'longpoll':
          var strRes = await streamedRes.join();
          strRes = '{"result": [$strRes';
          result = Stream<DatabaseResponse>.fromFuture(
              Future<DatabaseResponse>.value(
                  Response(jsonDecode(strRes)).databaseResponse()));
          break;
        case 'continuous':
          final mappedRes =
              streamedRes.map((v) => v.replaceAll('}\n{', '},\n{'));
          result = mappedRes.map((v) =>
              Response(jsonDecode('{"result": [$v]}')).databaseResponse());
          break;
        case 'eventsource':
          final mappedRes = streamedRes
              .map((v) => v.replaceAll(RegExp('\n+data'), '},\n{data'))
              .map((v) => v.replaceAll('data', '"data"'))
              .map((v) => v.replaceAll('\nid', ',\n"id"'));
          result = mappedRes.map((v) =>
              Response(jsonDecode('{"result": [{$v}]}')).databaseResponse());
          break;
        default:
          var strRes = await streamedRes.join();
          strRes = '{"result": [$strRes';
          result = Stream<DatabaseResponse>.fromFuture(
              Future<DatabaseResponse>.value(
                  Response(jsonDecode(strRes)).databaseResponse()));
      }
    } on CouchDbException {
      rethrow;
    }
    return result;
  }

  /// Request compaction of the specified database
  ///
  /// Returns JSON like:
  /// ```json
  /// {
  ///     "ok": true
  /// }
  /// ```
  Future<DatabaseResponse> compact(String dbName) async {
    Response result;

    try {
      result = await client.post('$dbName/_compact');
    } on CouchDbException {
      rethrow;
    }
    return result.databaseResponse();
  }

  /// Compacts the view indexes associated with the specified design document
  ///
  /// Returns JSON like:
  /// ```json
  /// {
  ///     "ok": true
  /// }
  /// ```
  Future<DatabaseResponse> compactViewIndexesWith(
      String dbName, String ddocName) async {
    Response result;

    try {
      result = await client.post('$dbName/_compact/$ddocName');
    } on CouchDbException {
      rethrow;
    }
    return result.databaseResponse();
  }

  /// Commits any recent changes to the specified database to disk
  ///
  /// Returns JSON like:
  /// ```json
  /// {
  ///     // This property isn't listed in [DatabaseModelResponse]
  ///     "instance_start_time": "0",
  ///     "ok": true
  /// }
  /// ```
  Future<DatabaseResponse> ensureFullCommit(String dbName) async {
    Response result;

    try {
      result = await client.post('$dbName/_ensure_full_commit');
    } on CouchDbException {
      rethrow;
    }
    return result.databaseResponse();
  }

  /// Removes view index files that are no longer required by CouchDB as a result of changed views within design documents
  ///
  /// Returns JSON like:
  /// ```json
  /// {
  ///     "ok": true
  /// }
  /// ```
  Future<DatabaseResponse> viewCleanup(String dbName) async {
    Response result;

    try {
      result = await client.post('$dbName/_view_cleanup');
    } on CouchDbException {
      rethrow;
    }
    return result.databaseResponse();
  }

  /// Returns the current security object from the specified database
  ///
  /// Returns JSON like:
  /// ```json
  /// {
  ///     "admins": {
  ///         "names": [
  ///             "superuser"
  ///         ],
  ///         "roles": [
  ///             "admins"
  ///         ]
  ///     },
  ///     "members": {
  ///         "names": [
  ///             "user1",
  ///             "user2"
  ///         ],
  ///         "roles": [
  ///             "developers"
  ///         ]
  ///     }
  /// }
  /// ```
  Future<DatabaseResponse> securityOf(String dbName) async {
    Response result;

    try {
      result = await client.get('$dbName/_security');
    } on CouchDbException {
      rethrow;
    }
    return result.databaseResponse();
  }

  /// Sets the security object for the given database
  ///
  /// Returns JSON like:
  /// ```json
  /// {
  ///     "ok": true
  /// }
  /// ```
  Future<DatabaseResponse> setSecurityFor(
      String dbName, Map<String, Map<String, List<String>>> security) async {
    Response result;

    try {
      result = await client.put('$dbName/_security', body: security);
    } on CouchDbException {
      rethrow;
    }
    return result.databaseResponse();
  }

  /// Permanently removes the references to deleted documents from the database
  ///
  /// Returns JSON like:
  /// ```json
  /// {
  ///   "purge_seq": null,
  ///   "purged": {
  ///     "c6114c65e295552ab1019e2b046b10e": {
  ///       "purged": [
  ///         "3-c50a32451890a3f1c3e423334cc92745"
  ///       ]
  ///     }
  ///   }
  /// }
  /// ```
  Future<DatabaseResponse> purge(
      String dbName, Map<String, List<String>> docs) async {
    Response result;

    try {
      result = await client.post('$dbName/_purge', body: docs);
    } on CouchDbException {
      rethrow;
    }
    return result.databaseResponse();
  }

  /// Gets the current purged_infos_limit (purged documents limit) setting,
  /// the maximum number of historical purges (purged document Ids with their revisions)
  /// that can be stored in the database
  ///
  /// Returns JSON like:
  /// ```json
  /// 1000
  /// ```
  Future<DatabaseResponse> purgedInfosLimit(String dbName) async {
    Response result;

    try {
      result = await client.get('$dbName/_purged_infos_limit');
    } on CouchDbException {
      rethrow;
    }
    return result.databaseResponse();
  }

  /// Sets the maximum number of purges (requested purged Ids with their revisions)
  /// that will be tracked in the database, even after compaction has occurred
  ///
  /// Returns JSON like:
  /// ```json
  /// {
  ///     "ok": true
  /// }
  /// ```
  Future<DatabaseResponse> setPurgedInfosLimit(String dbName, int limit) async {
    Response result;

    try {
      result = await client.put('$dbName/_purged_infos_limit', body: limit);
    } on CouchDbException {
      rethrow;
    }
    return result.databaseResponse();
  }

  /// Returns the document revisions that do not exist in the database
  ///
  /// Returns JSON like:
  /// ```json
  /// {
  ///     "missed_revs":{
  ///         "c6114c65e295552ab1019e2b046b10e": [
  ///             "3-b06fcd1c1c9e0ec7c480ee8aa467bf3b"
  ///         ]
  ///     }
  /// }
  /// ```
  Future<DatabaseResponse> missingRevs(
      String dbName, Map<String, List<String>> revs) async {
    Response result;

    try {
      result = await client.post('$dbName/_missing_revs', body: revs);
    } on CouchDbException {
      rethrow;
    }
    return result.databaseResponse();
  }

  /// Returns the subset of those that do not correspond to revisions stored in the database
  ///
  /// Returns JSON like:
  /// ```json
  /// {
  ///     "190f721ca3411be7aa9477db5f948bbb": {
  ///         "missing": [
  ///             "3-bb72a7682290f94a985f7afac8b27137",
  ///             "5-067a00dff5e02add41819138abb3284d"
  ///         ],
  ///         "possible_ancestors": [
  ///             "4-10265e5a26d807a3cfa459cf1a82ef2e"
  ///         ]
  ///     }
  /// }
  /// ```
  Future<DatabaseResponse> revsDiff(
      String dbName, Map<String, List<String>> revs) async {
    Response result;

    try {
      result = await client.post('$dbName/_revs_diff', body: revs);
    } on CouchDbException {
      rethrow;
    }
    return result.databaseResponse();
  }

  /// Gets the current **revs_limit** (revision limit) setting
  ///
  /// Returns JSON like:
  /// ```json
  /// 1000
  /// ```
  Future<DatabaseResponse> revsLimitOf(String dbName) async {
    Response result;

    try {
      result = await client.get('$dbName/_revs_limit');
    } on CouchDbException {
      rethrow;
    }
    return result.databaseResponse();
  }

  /// Sets the maximum number of document revisions that will be tracked by CouchDB, even after compaction has occurred
  ///
  /// Returns JSON like:
  /// ```json
  /// {
  ///     "ok": true
  /// }
  /// ```
  Future<DatabaseResponse> setRevsLimit(String dbName, int limit) async {
    Response result;

    try {
      result = await client.put('$dbName/_revs_limit', body: limit);
    } on CouchDbException {
      rethrow;
    }
    return result.databaseResponse();
  }
}
