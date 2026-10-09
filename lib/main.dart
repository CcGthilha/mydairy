import 'package:flutter/material.dart';
import 'api_service.dart';
import 'database_helper.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'login_page.dart';
import 'firestore_diary.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

// ==========================================
// 1. Models
// ==========================================

// แม่พิมพ์บันทึกไดอารี (SQLite)
class Diary {
  final int? id;
  final String title;
  final String content;
  final String date;
  final String mood;

  Diary({
    this.id,
    required this.title,
    required this.content,
    required this.date,
    required this.mood,
  });

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'title': title,
      'content': content,
      'date': date,
      'mood': mood,
    };
    if (id != null) {
      map['id'] = id;
    }
    return map;
  }

  factory Diary.fromMap(Map<String, dynamic> map) {
    return Diary(
      id: map['id'] as int?,
      title: map['title'] as String,
      content: map['content'] as String,
      date: map['date'] as String,
      mood: map['mood'] ?? 'เฉยๆ',
    );
  }
}

// แม่พิมพ์คำคมจาก API (Lab 2)
class Quote {
  final int id;
  final String quote;
  final String author;

  Quote({required this.id, required this.quote, required this.author});

  factory Quote.fromJson(Map<String, dynamic> json) {
    return Quote(
      id: json['id'] as int? ?? 0,
      quote: json['quote'] as String? ?? 'ไม่มีข้อความ',
      author: json['author'] as String? ?? 'ไม่ระบุผู้แต่ง',
    );
  }
}

// ==========================================
// 3. Application Root
// ==========================================
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MyDiary',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.indigo),
      home: const AuthGate(),
    );
  }
}

// ==========================================
// 4. หน้าหลัก (BottomNavigationBar)
// ==========================================
class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const DiaryListPage(), // แท็บ SQLite + คำคม (ของเดิม)
    const ApiDiaryPage(), // แท็บ REST API (สัปดาห์ 4)
    const FirestoreDiaryPage(), // แท็บ Cloud (สัปดาห์นี้)
    const AboutPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.book), label: 'บันทึก'),
          BottomNavigationBarItem(icon: Icon(Icons.cloud), label: 'ออนไลน์'),
          BottomNavigationBarItem(icon: Icon(Icons.cloud), label: 'Cloud'),
          BottomNavigationBarItem(icon: Icon(Icons.info), label: 'เกี่ยวกับ'),
        ],
      ),
    );
  }
}

// ==========================================
// 5. หน้ารายการบันทึก (มี FutureBuilder การ์ดคำคม + SQLite)
// ==========================================
class DiaryListPage extends StatefulWidget {
  const DiaryListPage({super.key});

  @override
  State<DiaryListPage> createState() => _DiaryListPageState();
}

class _DiaryListPageState extends State<DiaryListPage> {
  List<Diary> diaries = [];
  late Future<Quote> _quoteFuture;

  final List<Color> colors = [
    Colors.indigo,
    Colors.teal,
    Colors.orange,
    Colors.pink,
    Colors.green,
  ];

  @override
  void initState() {
    super.initState();
    _loadDiaries();
    _fetchNewQuote();
  }

  void _fetchNewQuote() {
    setState(() {
      _quoteFuture = ApiService.fetchQuote();
    });
  }

  Future<void> _loadDiaries() async {
    final data = await DatabaseHelper.getAll();
    setState(() {
      diaries = data;
    });
  }

  Future<void> _addDiary(Diary diary) async {
    await DatabaseHelper.insert(diary);
    await _loadDiaries();
  }

  Future<void> _updateDiary(Diary diary) async {
    await DatabaseHelper.update(diary);
    await _loadDiaries();
  }

  Future<void> _deleteDiary(int id) async {
    await DatabaseHelper.delete(id);
    await _loadDiaries();
  }

  Future<void> _confirmDelete(int index) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('ลบบันทึก?'),
        content: Text('ต้องการลบ "${diaries[index].title}" ใช่ไหม'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('ยกเลิก'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('ลบ', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      _deleteDiary(diaries[index].id!);
    }
  }

  // Lab 3: บันทึกคำคมที่ดึงมาจาก API ลงใน SQLite
  Future<void> _saveQuoteToDiary(Quote quote) async {
    final today = DateTime.now().toString().substring(0, 10);
    final diaryFromQuote = Diary(
      title: 'คำคมโดนใจ: ${quote.author}',
      content: '"${quote.quote}"\n\n(บันทึกอัตโนมัติจากคำคมออนไลน์)',
      date: today,
      mood: 'ตื่นเต้น',
    );

    await _addDiary(diaryFromQuote);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('บันทึกคำคมของ "${quote.author}" ลงไดอารีเรียบร้อยแล้ว!'),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // Widget การ์ดแสดงคำคมจากเน็ต (Lab 1)
  Widget _buildQuoteCard() {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: FutureBuilder<Quote>(
        future: _quoteFuture,
        builder: (context, snapshot) {
          // Lab 1 (ขั้นที่ 2): แสดงสถานะโหลดพร้อมข้อความ
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 10),
                    Text(
                      'กำลังโหลดคำคม...',
                      style: TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                  ],
                ),
              ),
            );
          }

          // Lab 1 (ขั้นที่ 1) & Lab 2: แสดงสถานะ Error พร้อมปุ่มลองใหม่
          if (snapshot.hasError) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.wifi_off, color: Colors.redAccent, size: 36),
                  const SizedBox(height: 6),
                  Text(
                    snapshot.error.toString().replaceAll('Exception: ', ''),
                    style: const TextStyle(color: Colors.grey, fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                  TextButton.icon(
                    onPressed: _fetchNewQuote,
                    icon: const Icon(Icons.refresh, size: 18),
                    label: const Text('ลองใหม่'),
                  ),
                ],
              ),
            );
          }

          // เมื่อโหลดข้อมูลสำเร็จ (ก4)
          final quote = snapshot.data!;
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.format_quote,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 6),
                        const Text(
                          'คำคมประจำวัน (API)',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.refresh, size: 20),
                      tooltip: 'รีเฟรชคำคมใหม่',
                      onPressed: _fetchNewQuote,
                    ),
                  ],
                ),
                Text(
                  '"${quote.quote}"',
                  style: const TextStyle(
                    fontStyle: FontStyle.italic,
                    fontSize: 15,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 6),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    '— ${quote.author}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.black54,
                    ),
                  ),
                ),
                const Divider(height: 20),
                // Lab 3: ปุ่มบันทึกคำคมลง SQLite
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _saveQuoteToDiary(quote),
                    icon: const Icon(Icons.bookmark_add_outlined, size: 18),
                    label: const Text('บันทึกคำคมที่ชอบลงสมุดบันทึก'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('บันทึกของฉัน (${diaries.length})'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // ส่วนที่ 1: การ์ดคำคมจากเน็ต (Lab 1, 2, 3)
          _buildQuoteCard(),

          // ส่วนที่ 2: รายการบันทึกจาก SQLite
          Expanded(
            child: diaries.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.book_outlined, size: 80, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'ยังไม่มีบันทึก',
                          style: TextStyle(fontSize: 18, color: Colors.grey),
                        ),
                        Text(
                          'กดปุ่ม + หรือบันทึกจากคำคมด้านบน',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: diaries.length,
                    itemBuilder: (context, i) {
                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        child: ListTile(
                          leading: Icon(
                            Icons.book,
                            color: colors[i % colors.length],
                          ),
                          title: Text(diaries[i].title),
                          subtitle: Text(
                            '${diaries[i].mood} • ${diaries[i].date}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(
                                  Icons.edit,
                                  color: Colors.blue,
                                ),
                                onPressed: () async {
                                  final result = await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          AddDiaryPage(existing: diaries[i]),
                                    ),
                                  );
                                  if (result != null && result is Diary) {
                                    await _updateDiary(result);
                                  }
                                },
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.red,
                                ),
                                onPressed: () => _confirmDelete(i),
                              ),
                            ],
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    DiaryDetailPage(diary: diaries[i]),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddDiaryPage()),
          );

          if (result != null && result is Diary) {
            await _addDiary(result);
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

// ==========================================
// 6. หน้าเพิ่ม / แก้ไขบันทึก (เดิม)
// ==========================================
class AddDiaryPage extends StatefulWidget {
  final Diary? existing;

  const AddDiaryPage({super.key, this.existing});

  @override
  State<AddDiaryPage> createState() => _AddDiaryPageState();
}

class _AddDiaryPageState extends State<AddDiaryPage> {
  final _formKey = GlobalKey<FormState>();

  final _titleController = TextEditingController();
  final _contentController = TextEditingController();

  String _selectedMood = 'มีความสุข';

  final List<String> _moods = [
    'มีความสุข',
    'เฉยๆ',
    'เศร้า',
    'เหนื่อย',
    'ตื่นเต้น',
  ];

  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    if (existing != null) {
      _titleController.text = existing.title;
      _contentController.text = existing.content;
      _selectedMood = existing.mood;
      _selectedDate = DateTime.tryParse(existing.date) ?? DateTime.now();
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existing != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'แก้ไขบันทึก' : 'เขียนบันทึกใหม่'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'ชื่อเรื่อง',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'กรุณากรอกชื่อเรื่อง';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _contentController,
                maxLines: 5,
                decoration: const InputDecoration(
                  labelText: 'เนื้อหา',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'กรุณากรอกเนื้อหา';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _selectedMood,
                decoration: const InputDecoration(
                  labelText: 'อารมณ์วันนี้',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.mood),
                ),
                items: _moods.map((mood) {
                  return DropdownMenuItem(value: mood, child: Text(mood));
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedMood = value!;
                  });
                },
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.calendar_today),
                title: Text(
                  'วันที่: ${_selectedDate.toString().substring(0, 10)}',
                ),
                trailing: const Icon(Icons.edit),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2030),
                  );

                  if (picked != null) {
                    setState(() {
                      _selectedDate = picked;
                    });
                  }
                },
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      final newDiary = Diary(
                        id: widget.existing?.id,
                        title: _titleController.text.trim(),
                        content: _contentController.text.trim(),
                        date: _selectedDate.toString().substring(0, 10),
                        mood: _selectedMood,
                      );

                      Navigator.pop(context, newDiary);
                    }
                  },
                  child: Text(isEditing ? 'บันทึกการแก้ไข' : 'บันทึก'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ==========================================
// 7. หน้ารายละเอียดบันทึก (เดิม)
// ==========================================
class DiaryDetailPage extends StatelessWidget {
  final Diary diary;

  const DiaryDetailPage({super.key, required this.diary});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('รายละเอียด')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              diary.title,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              diary.date,
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Text('อารมณ์: ${diary.mood}', style: const TextStyle(fontSize: 16)),
            const Divider(height: 32),
            Text(
              diary.content,
              style: const TextStyle(fontSize: 16, height: 1.6),
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// 8. หน้าเกี่ยวกับ (โบนัส +1: แสดงข้อมูลเน็ตหลายหน้า)
// ==========================================
class AboutPage extends StatefulWidget {
  const AboutPage({super.key});

  @override
  State<AboutPage> createState() => _AboutPageState();
}

class _AboutPageState extends State<AboutPage> {
  late Future<String> _quoteFuture;

  @override
  void initState() {
    super.initState();
    _quoteFuture = ApiService.fetchDailyInspiration();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('เกี่ยวกับ')),
      body: SingleChildScrollView(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.indigo,
                  child: Icon(Icons.book, size: 50, color: Colors.white),
                ),
                const SizedBox(height: 20),
                const Text(
                  'MyDiary',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text('แอปสมุดบันทึกส่วนตัว'),
                const SizedBox(height: 4),
                const Text('สร้างโดย นางสาวช่อทิพย์ ลือจันดา'),
                const Text('รหัสนักศึกษา 67011212113'),
                const SizedBox(height: 8),
                const Text(
                  'เวอร์ชัน 3.0 (SQLite + Online API)',
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 24),

                // ข้อความสร้างแรงบันดาลใจจากเน็ต (API ตัวที่สอง)
                FutureBuilder<String>(
                  future: _quoteFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const LinearProgressIndicator();
                    }
                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.indigo.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.indigo.shade200),
                      ),
                      child: Column(
                        children: [
                          const Icon(Icons.format_quote, color: Colors.indigo),
                          const SizedBox(height: 6),
                          Text(
                            snapshot.data ?? '',
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontStyle: FontStyle.italic),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ==========================================
// 9. แท็บออนไลน์ (REST API CRUD — สัปดาห์ 4)
// ==========================================
class ApiDiaryPage extends StatefulWidget {
  const ApiDiaryPage({super.key});
  @override
  State<ApiDiaryPage> createState() => _ApiDiaryPageState();
}

class _ApiDiaryPageState extends State<ApiDiaryPage> {
  late Future<List<dynamic>> _diariesFuture;

  @override
  void initState() {
    super.initState();
    _loadDiaries();
  }

  void _loadDiaries() {
    setState(() {
      _diariesFuture = ApiService.getDiaries();
    });
  }

  void _err(String msg) {
    if (mounted)
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _addDiary(
    String title,
    String content,
    String mood,
    String date,
  ) async {
    try {
      await ApiService.createDiary(title, content, mood, date);
      _loadDiaries();
    } catch (e) {
      _err('เพิ่มไม่สำเร็จ ตรวจสอบอินเทอร์เน็ต');
    }
  }

  Future<void> _updateDiary(
    dynamic id,
    String title,
    String content,
    String mood,
    String date,
  ) async {
    try {
      await ApiService.updateDiary(id, title, content, mood, date);
      _loadDiaries();
    } catch (e) {
      _err('แก้ไขไม่สำเร็จ ตรวจสอบอินเทอร์เน็ต');
    }
  }

  Future<void> _deleteDiary(dynamic id) async {
    try {
      await ApiService.deleteDiary(id);
      _loadDiaries();
    } catch (e) {
      _err('ลบไม่สำเร็จ ตรวจสอบอินเทอร์เน็ต');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('บันทึกบน Cloud (REST API)'),
        centerTitle: true,
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _diariesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('ผิดพลาด: ${snapshot.error}'),
                  TextButton(
                    onPressed: _loadDiaries,
                    child: const Text('ลองใหม่'),
                  ),
                ],
              ),
            );
          }
          final diaries = snapshot.data!;
          if (diaries.isEmpty)
            return const Center(child: Text('ยังไม่มีบันทึก กดปุ่ม +'));
          return ListView.builder(
            itemCount: diaries.length,
            itemBuilder: (context, i) {
              final obj = diaries[i];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: ListTile(
                  title: Text(obj['title'] ?? ''),
                  subtitle: Text(
                    '${obj['mood'] ?? ''} • ${obj['date'] ?? ''} • ${obj['content'] ?? ''}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // ── แก้ไข (Update) ──
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ApiFormPage(existing: obj),
                            ),
                          );
                          if (result is Map) {
                            await _updateDiary(
                              obj['id'],
                              result['title'],
                              result['content'],
                              result['mood'],
                              result['date'],
                            );
                          }
                        },
                      ),
                      // ── ลบ (Delete) + ยืนยันก่อนลบ ──
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('ลบบันทึก?'),
                              content: Text(
                                'ต้องการลบ "${obj['title']}" ใช่ไหม',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx, false),
                                  child: const Text('ยกเลิก'),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx, true),
                                  child: const Text(
                                    'ลบ',
                                    style: TextStyle(color: Colors.red),
                                  ),
                                ),
                              ],
                            ),
                          );
                          if (confirm == true) await _deleteDiary(obj['id']);
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ApiFormPage()),
          );
          if (result is Map) {
            await _addDiary(
              result['title'],
              result['content'],
              result['mood'],
              result['date'],
            );
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

// ==========================================
// 10. ฟอร์มเพิ่ม/แก้ไข สำหรับแท็บออนไลน์ (ส่ง Map กลับ)
// ==========================================
class ApiFormPage extends StatefulWidget {
  final Map? existing;
  const ApiFormPage({super.key, this.existing});
  @override
  State<ApiFormPage> createState() => _ApiFormPageState();
}

class _ApiFormPageState extends State<ApiFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  String _mood = 'มีความสุข';
  final List<String> _moods = [
    'มีความสุข',
    'เฉยๆ',
    'เศร้า',
    'เหนื่อย',
    'ตื่นเต้น',
  ];
  DateTime _date = DateTime.now();

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e != null) {
      _titleController.text = e['title'] ?? '';
      _contentController.text = e['content'] ?? '';
      _mood = _moods.contains(e['mood']) ? e['mood'] : 'เฉยๆ';
      _date = DateTime.tryParse(e['date'] ?? '') ?? DateTime.now();
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existing == null ? 'เพิ่มบันทึก' : 'แก้ไขบันทึก'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              children: [
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'ชื่อเรื่อง',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'กรุณากรอกชื่อเรื่อง'
                      : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _contentController,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'เนื้อหา',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'กรุณากรอกเนื้อหา'
                      : null,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: _mood,
                  decoration: const InputDecoration(
                    labelText: 'อารมณ์',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.mood),
                  ),
                  items: _moods
                      .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                      .toList(),
                  onChanged: (v) => setState(() => _mood = v!),
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: const Icon(Icons.calendar_today),
                  title: Text('วันที่: ${_date.toString().substring(0, 10)}'),
                  trailing: const Icon(Icons.edit),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _date,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2030),
                    );
                    if (picked != null) setState(() => _date = picked);
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
                          'mood': _mood,
                          'date': _date.toString().substring(0, 10),
                        });
                      }
                    },
                    child: const Text('บันทึก'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
