import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firestore_service.dart';

class FirestoreDiaryPage extends StatelessWidget {
  const FirestoreDiaryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('บันทึก Cloud (Firestore)'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => FirebaseAuth.instance.signOut(),   // ออกจากระบบ
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirestoreService.getMyDiaries(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('ผิดพลาด: ${snapshot.error}'));
          }
          final docs = snapshot.data!.docs;
          if (docs.isEmpty) {
            return const Center(child: Text('ยังไม่มีบันทึก กดปุ่ม +'));
          }
          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, i) {
              final data = docs[i].data() as Map<String, dynamic>;
              final docId = docs[i].id;      // id ของ document (String)
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: ListTile(
                  title: Text(data['title'] ?? ''),
                  subtitle: Text('${data['date'] ?? ''} • ${data['content'] ?? ''}',
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => FirestoreService.delete(docId),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(context,
              MaterialPageRoute(builder: (_) => const FirestoreFormPage()));
          if (result is Map) {
            await FirestoreService.add(
                result['title'], result['content'], result['date']);
            // ไม่ต้อง reload! StreamBuilder อัปเดตเอง
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

class FirestoreFormPage extends StatefulWidget {
  const FirestoreFormPage({super.key});
  @override
  State<FirestoreFormPage> createState() => _FirestoreFormPageState();
}

class _FirestoreFormPageState extends State<FirestoreFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  DateTime _selectedDate = DateTime.now();

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('เพิ่มบันทึก (Cloud)')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                    labelText: 'ชื่อเรื่อง', border: OutlineInputBorder()),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'กรอกชื่อเรื่อง' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _contentController,
                maxLines: 4,
                decoration: const InputDecoration(
                    labelText: 'เนื้อหา', border: OutlineInputBorder()),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'กรอกเนื้อหา' : null,
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.calendar_today),
                title: Text('วันที่: ${_selectedDate.toString().substring(0, 10)}'),
                trailing: const Icon(Icons.edit),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2030),
                  );
                  if (picked != null) setState(() => _selectedDate = picked);
                },
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      Navigator.pop(context, {
                        'title': _titleController.text.trim(),
                        'content': _contentController.text.trim(),
                        'date': _selectedDate.toString().substring(0, 10),
                      });
                    }
                  },
                  child: const Text('เพิ่ม'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}