import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirestoreService {
  static final _diaries = FirebaseFirestore.instance.collection('diaries');
  static String get _uid => FirebaseAuth.instance.currentUser!.uid;

  // CREATE (เทียบ SQLite: db.insert)
  static Future<void> add(String title, String content, String date) async {
    await _diaries.add({
      'title': title,
      'content': content,
      'date': date,
      'userId': _uid,        // ผูกกับเจ้าของ
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // READ (เทียบ SQLite: db.query) — เฉพาะของฉัน, เรียลไทม์
  static Stream<QuerySnapshot> getMyDiaries() {
    return _diaries
        .where('userId', isEqualTo: _uid)        // กรองเฉพาะของฉัน
        .snapshots();                            // Stream = เรียลไทม์
  }

  // UPDATE (เทียบ SQLite: db.update)
  static Future<void> update(String docId, String title, String content) async {
    await _diaries.doc(docId).update({'title': title, 'content': content});
  }

  // DELETE (เทียบ SQLite: db.delete)
  static Future<void> delete(String docId) async {
    await _diaries.doc(docId).delete();
  }
}