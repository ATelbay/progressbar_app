import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

typedef WriteRejected = void Function(Object error, StackTrace stack);

void logRejectedWrite(Object error, StackTrace stack) =>
    debugPrint('Firestore rejected a write: $error');

/// Firestore applies a write to the local cache at once, but its future
/// completes only when the server confirms it — without a network that may be
/// hours later. So nothing waits for it: listeners already see the change, and
/// the write is sent when the connection returns, also after an app restart.
/// [onRejected] is called if the server refuses it.
void sendWrite(Future<void> write, WriteRejected onRejected) =>
    unawaited(write.then((_) {}, onError: onRejected));

/// A new document ID; works without a network.
String newFirestoreId(FirebaseFirestore db) => db.collection('ids').doc().id;
