import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:appointment_booking/core/exceptions/app_exceptions.dart';

/// Generic service for handling Cloud Firestore operations.
///
/// Provides reusable CRUD operations, queries, batch writes, and
/// real-time streams that any feature can consume.
class FirestoreService {
  final FirebaseFirestore _firestore;

  FirestoreService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  // ---------------------------------------------------------------------------
  // Collection / Document references
  // ---------------------------------------------------------------------------

  /// Returns a [CollectionReference] for the given collection path.
  CollectionReference<Map<String, dynamic>> collection(String path) =>
      _firestore.collection(path);

  /// Returns a [DocumentReference] for the given document path.
  DocumentReference<Map<String, dynamic>> document(String path) =>
      _firestore.doc(path);

  // ---------------------------------------------------------------------------
  // Create
  // ---------------------------------------------------------------------------

  /// Creates a new document with an auto-generated ID.
  ///
  /// Returns the generated document ID.
  Future<String> addDocument({
    required String collectionPath,
    required Map<String, dynamic> data,
  }) async {
    try {
      final docRef = await _firestore.collection(collectionPath).add(data);
      return docRef.id;
    } on FirebaseException catch (e) {
      throw _handleFirestoreException(e);
    } catch (e) {
      throw UnknownException(e.toString());
    }
  }

  /// Creates or overwrites a document with a specific ID.
  ///
  /// If the document exists it will be completely overwritten unless
  /// [merge] is set to `true`.
  Future<void> setDocument({
    required String documentPath,
    required Map<String, dynamic> data,
    bool merge = false,
  }) async {
    try {
      await _firestore.doc(documentPath).set(data, SetOptions(merge: merge));
    } on FirebaseException catch (e) {
      throw _handleFirestoreException(e);
    } catch (e) {
      throw UnknownException(e.toString());
    }
  }

  // ---------------------------------------------------------------------------
  // Read
  // ---------------------------------------------------------------------------

  /// Fetches a single document by its full path.
  ///
  /// Returns the document data as a [Map], or `null` if the document does
  /// not exist.
  Future<Map<String, dynamic>?> getDocument({
    required String documentPath,
  }) async {
    try {
      final snapshot = await _firestore.doc(documentPath).get();
      return snapshot.data();
    } on FirebaseException catch (e) {
      throw _handleFirestoreException(e);
    } catch (e) {
      throw UnknownException(e.toString());
    }
  }

  /// Fetches all documents in a collection.
  ///
  /// Each returned map includes an `'id'` field with the document ID.
  Future<List<Map<String, dynamic>>> getCollection({
    required String collectionPath,
  }) async {
    try {
      final snapshot = await _firestore.collection(collectionPath).get();
      return snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
    } on FirebaseException catch (e) {
      throw _handleFirestoreException(e);
    } catch (e) {
      throw UnknownException(e.toString());
    }
  }

  /// Fetches documents matching a [query] built on top of a collection.
  ///
  /// Example:
  /// ```dart
  /// final results = await firestoreService.queryCollection(
  ///   collectionPath: 'bookings',
  ///   queryBuilder: (ref) => ref
  ///     .where('userId', isEqualTo: uid)
  ///     .orderBy('date', descending: true)
  ///     .limit(20),
  /// );
  /// ```
  Future<List<Map<String, dynamic>>> queryCollection({
    required String collectionPath,
    required Query<Map<String, dynamic>> Function(
      CollectionReference<Map<String, dynamic>> ref,
    )
    queryBuilder,
  }) async {
    try {
      final query = queryBuilder(_firestore.collection(collectionPath));
      final snapshot = await query.get();
      return snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
    } on FirebaseException catch (e) {
      throw _handleFirestoreException(e);
    } catch (e) {
      throw UnknownException(e.toString());
    }
  }

  /// Checks whether a document exists at the given path.
  Future<bool> documentExists({required String documentPath}) async {
    try {
      final snapshot = await _firestore.doc(documentPath).get();
      return snapshot.exists;
    } on FirebaseException catch (e) {
      throw _handleFirestoreException(e);
    } catch (e) {
      throw UnknownException(e.toString());
    }
  }

  // ---------------------------------------------------------------------------
  // Update
  // ---------------------------------------------------------------------------

  /// Updates specific fields on an existing document.
  ///
  /// Throws [FirestoreException] with code `not-found` if the document
  /// does not exist.
  Future<void> updateDocument({
    required String documentPath,
    required Map<String, dynamic> data,
  }) async {
    try {
      await _firestore.doc(documentPath).update(data);
    } on FirebaseException catch (e) {
      throw _handleFirestoreException(e);
    } catch (e) {
      throw UnknownException(e.toString());
    }
  }

  // ---------------------------------------------------------------------------
  // Delete
  // ---------------------------------------------------------------------------

  /// Deletes a document at the given path.
  Future<void> deleteDocument({required String documentPath}) async {
    try {
      await _firestore.doc(documentPath).delete();
    } on FirebaseException catch (e) {
      throw _handleFirestoreException(e);
    } catch (e) {
      throw UnknownException(e.toString());
    }
  }

  // ---------------------------------------------------------------------------
  // Real-time streams
  // ---------------------------------------------------------------------------

  /// Returns a real-time stream of a single document.
  ///
  /// Emits `null` when the document does not exist.
  Stream<Map<String, dynamic>?> documentStream({required String documentPath}) {
    return _firestore
        .doc(documentPath)
        .snapshots()
        .map((snapshot) => snapshot.data());
  }

  /// Returns a real-time stream of all documents in a collection.
  Stream<List<Map<String, dynamic>>> collectionStream({
    required String collectionPath,
  }) {
    return _firestore
        .collection(collectionPath)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => {'id': doc.id, ...doc.data()})
              .toList(),
        );
  }

  /// Returns a real-time stream for a custom query.
  Stream<List<Map<String, dynamic>>> queryStream({
    required String collectionPath,
    required Query<Map<String, dynamic>> Function(
      CollectionReference<Map<String, dynamic>> ref,
    )
    queryBuilder,
  }) {
    final query = queryBuilder(_firestore.collection(collectionPath));
    return query.snapshots().map(
      (snapshot) =>
          snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList(),
    );
  }

  // ---------------------------------------------------------------------------
  // Batch & Transactions
  // ---------------------------------------------------------------------------

  /// Executes multiple write operations atomically in a batch.
  ///
  /// The [actions] callback receives a [WriteBatch] to which you can add
  /// set / update / delete calls.
  Future<void> batchWrite({
    required void Function(WriteBatch batch) actions,
  }) async {
    try {
      final batch = _firestore.batch();
      actions(batch);
      await batch.commit();
    } on FirebaseException catch (e) {
      throw _handleFirestoreException(e);
    } catch (e) {
      throw UnknownException(e.toString());
    }
  }

  /// Runs a Firestore transaction.
  ///
  /// The [transactionHandler] receives a [Transaction] object and must
  /// return the result of type [T].
  Future<T> runTransaction<T>({
    required Future<T> Function(Transaction transaction) transactionHandler,
  }) async {
    try {
      return await _firestore.runTransaction(transactionHandler);
    } on FirebaseException catch (e) {
      throw _handleFirestoreException(e);
    } catch (e) {
      throw UnknownException(e.toString());
    }
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  /// Returns a server-generated timestamp sentinel value.
  ///
  /// Use this as a field value to let Firestore set the server timestamp.
  static FieldValue get serverTimestamp => FieldValue.serverTimestamp();

  /// Maps Firestore exception codes to app-specific exceptions.
  AppException _handleFirestoreException(FirebaseException e) {
    if (e.code == 'unavailable') {
      return const NetworkException();
    }
    return FirestoreException.fromCode(e.code, e.message);
  }
}
