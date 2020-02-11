import 'dart:async';
import 'dart:html';

import 'package:idb_shim/idb_client_native.dart';
import 'package:sembast_web/src/jdb_factory_idb.dart';
import 'package:sembast_web/src/jdb_import.dart';

/// The native jdb factory
var jdbFactoryIdbNative = JdbFactoryWeb();

/// The sembast idb native factory with web.
var databaseFactoryWeb = DatabaseFactoryWeb();

/// Web jdb factory.
class JdbFactoryWeb extends JdbFactoryIdb {
  /// Web jdb factory.
  JdbFactoryWeb() : super(idbFactoryNative);

  StreamSubscription _revisionSubscription;

  @override
  void start() {
    stop();
    _revisionSubscription = storageRevisionStream.listen((storageRevision) {
      var list = databases[storageRevision.name];
      for (var jdbDatabase in list) {
        jdbDatabase.addRevision(storageRevision.revision);
      }
    });
  }

  @override
  void stop() {
    _revisionSubscription?.cancel();
    _revisionSubscription = null;
  }
}

/// Web factory.
class DatabaseFactoryWeb extends DatabaseFactoryJdb {
  /// Web factory.
  DatabaseFactoryWeb() : super(jdbFactoryIdbNative);
}

/// The storage revision.
class StorageRevision {
  /// Name of the database.
  final String name;

  /// Revision.
  final int revision;

  /// Revision for one storage
  StorageRevision(this.name, this.revision);
}

String _sembastStorageKeyPrefix = 'sembast_web/revision:';

/// Storage revision notification from all tabs
Stream<StorageRevision> get storageRevisionStream {
  StreamSubscription storageEventSubscription;
  StreamController<StorageRevision> ctlr;
  ctlr = StreamController<StorageRevision>(onListen: () {
    storageEventSubscription = window.onStorage.listen((event) {
      if (event.key.startsWith(_sembastStorageKeyPrefix)) {
        var name = event.key.substring(_sembastStorageKeyPrefix.length);
        var revision =
            event.newValue == null ? 0 : (int.tryParse(event.newValue) ?? 0);
        ctlr.add(StorageRevision(name, revision));
      }
    });
  }, onCancel: () {
    storageEventSubscription?.cancel();
  });
  return ctlr.stream;
}