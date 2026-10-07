import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

typedef WriteRejected = void Function(Object error, StackTrace stack);

void logRejectedWrite(Object error, StackTrace stack) =>
    debugPrint('Firestore rejected a write: $error');

/// Every stored document carries the ID of the write that produced it. It is
/// how [sendWrite] tells that a write has reached the local cache.
const writeIdField = 'writeId';

class _WriteQueue {
  Future<void> last = Future.value();
}

final _queues = Expando<_WriteQueue>();

/// Firestore applies a write to the local cache at once, but its future
/// completes only when the server confirms it — without a network that may be
/// hours later. So nothing waits for the server: listeners already see the
/// change, and the write is sent when the connection returns, also after an
/// app restart. [onRejected] is called if the server refuses it.
///
/// Writes are issued one at a time, the next one only after the previous is in
/// the local cache. On Android the plugin hands every write to a thread of its
/// own, so two writes issued together may otherwise be applied in the wrong
/// order and the older one wins.
///
/// [write] must leave [writeId] in [landsIn] under [writeIdField], or delete
/// [landsIn] when [writeId] is null. The returned future completes when the
/// write is in the cache — a matter of milliseconds, network or not.
Future<void> sendWrite({
  required DocumentReference<Map<String, dynamic>> landsIn,
  required String? writeId,
  required Future<void> Function() write,
  required WriteRejected onRejected,
}) {
  final queue = _queues[landsIn.firestore] ??= _WriteQueue();
  final landed = queue.last.then((_) async {
    unawaited(write().then((_) {}, onError: onRejected));
    try {
      await landsIn
          .snapshots()
          .firstWhere(
            (snap) => writeId == null
                ? !snap.exists
                : snap.data()?[writeIdField] == writeId,
          )
          .timeout(_landingTimeout);
    } catch (_) {
      // Never hold the next write back for long: in the gym a late write is
      // better than a frozen screen.
    }
  });
  queue.last = landed.then((_) {}, onError: (_) {});
  return landed;
}

const _landingTimeout = Duration(seconds: 2);

/// A new document ID; works without a network.
String newFirestoreId(FirebaseFirestore db) => db.collection('ids').doc().id;
