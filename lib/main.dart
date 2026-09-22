import 'package:flutter/material.dart';
import 'database_helper.dart';

void main() => runApp(const MyApp());

// แม่พิมพ์บันทึก
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

  // แปลง object -> Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'date': date,
      'mood': mood,
    };
  }

  // แปลง Map -> object
  factory Diary.fromMap(Map<String, dynamic> map) {
    return Diary(
      id: map['id'],
      title: map['title'],
      content: map['content'],
      date: map['date'],
      mood: map['mood'] ?? 'เฉยๆ',
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MyDiary',
      theme: ThemeData(
        colorSchemeSeed: Colors.indigo,
      ),
      home: const MainPage(),
    );
  }
}

// หน้าหลัก ควบคุมเมนูล่าง
class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const DiaryListPage(),
    const AboutPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.book),
            label: 'บันทึก',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.info),
            label: 'เกี่ยวกับ',
          ),
        ],
      ),
    );
  }
}

// หน้าเกี่ยวกับ
class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('เกี่ยวกับ'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircleAvatar(
                radius: 50,
                backgroundColor: Colors.indigo,
                child: Icon(
                  Icons.book,
                  size: 50,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'MyDiary',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text('แอปสมุดบันทึกส่วนตัว'),
              const SizedBox(height: 4),
              const Text('สร้างโดย นางสาวช่อทิพย์ ลือจันดา'),
              const Text('รหัสนักศึกษา 67011212113'),
              const SizedBox(height: 16),
              const Text(
                'เวอร์ชัน 1.0',
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// หน้ารายการบันทึก
class DiaryListPage extends StatefulWidget {
  const DiaryListPage({super.key});

  @override
  State<DiaryListPage> createState() => _DiaryListPageState();
}

class _DiaryListPageState extends State<DiaryListPage> {
  // เก็บข้อมูลที่โหลดมาจาก SQLite
  List<Diary> diaries = [];

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
  }

  // โหลดข้อมูลจาก DB
  Future<void> _loadDiaries() async {
    final data = await DatabaseHelper.getAll();

    setState(() {
      diaries = data;
    });
  }

  // เพิ่มบันทึก
  Future<void> _addDiary(Diary diary) async {
    await DatabaseHelper.insert(diary);
    await _loadDiaries();
  }

  // แก้ไขบันทึก (Lab 2)
  Future<void> _updateDiary(Diary diary) async {
    await DatabaseHelper.update(diary);
    _loadDiaries();
  }

  // ลบบันทึก
  Future<void> _deleteDiary(int id) async {
    await DatabaseHelper.delete(id);
    await _loadDiaries();
  }

  // ยืนยันก่อนลบ (Lab 3)
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // Challenge: นับจำนวนบันทึกบน AppBar
        title: Text('บันทึกของฉัน (${diaries.length})'),
      ),

      body: diaries.isEmpty
          // Lab 4: ข้อความเมื่อยังไม่มีบันทึก
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
                    'กดปุ่ม + เพื่อเขียนบันทึกแรก',
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

                    title: Text(
                      diaries[i].title,
                    ),

                    subtitle: Text(
                      '${diaries[i].mood} • ${diaries[i].date}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),

                    // Lab 2 + Lab 3: ปุ่มแก้ไข + ปุ่มลบ (พร้อมยืนยัน)
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue),
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
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _confirmDelete(i),
                        ),
                      ],
                    ),

                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => DiaryDetailPage(
                            diary: diaries[i],
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),

      // ปุ่มเพิ่มบันทึก
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AddDiaryPage(),
            ),
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

// หน้าเพิ่ม / แก้ไขบันทึก
class AddDiaryPage extends StatefulWidget {
  final Diary? existing; // ถ้าส่งมา = โหมดแก้ไข / null = เพิ่มใหม่

  const AddDiaryPage({super.key, this.existing});

  @override
  State<AddDiaryPage> createState() => _AddDiaryPageState();
}

class _AddDiaryPageState extends State<AddDiaryPage> {
  final _formKey = GlobalKey<FormState>();

  final _titleController = TextEditingController();
  final _contentController = TextEditingController();

  // อารมณ์
  String _selectedMood = 'มีความสุข';

  final List<String> _moods = [
    'มีความสุข',
    'เฉยๆ',
    'เศร้า',
    'เหนื่อย',
    'ตื่นเต้น',
  ];

  // วันที่
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    if (existing != null) {
      // โหมดแก้ไข: เติมค่าเดิมลงช่องกรอก
      _titleController.text = existing.title;
      _contentController.text = existing.content;
      _selectedMood = existing.mood;
      _selectedDate = DateTime.parse(existing.date);
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

      body: Padding(
        padding: const EdgeInsets.all(16),

        child: Form(
          key: _formKey,

          child: Column(
            children: [
              // ชื่อเรื่อง
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

              // เนื้อหา
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

              // เลือกอารมณ์
              DropdownButtonFormField<String>(
                initialValue: _selectedMood,
                decoration: const InputDecoration(
                  labelText: 'อารมณ์วันนี้',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.mood),
                ),

                items: _moods.map((mood) {
                  return DropdownMenuItem(
                    value: mood,
                    child: Text(mood),
                  );
                }).toList(),

                onChanged: (value) {
                  setState(() {
                    _selectedMood = value!;
                  });
                },
              ),

              const SizedBox(height: 16),

              // เลือกวันที่
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

              // ปุ่มบันทึก
              SizedBox(
                width: double.infinity,

                child: ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      final newDiary = Diary(
                        id: widget.existing?.id, // คง id เดิมไว้ตอนแก้ไข
                        title: _titleController.text.trim(),
                        content: _contentController.text.trim(),
                        date: _selectedDate
                            .toString()
                            .substring(0, 10),
                        mood: _selectedMood,
                      );

                      // ส่งข้อมูลกลับหน้ารายการ
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

// หน้ารายละเอียดบันทึก
class DiaryDetailPage extends StatelessWidget {
  final Diary diary;

  const DiaryDetailPage({
    super.key,
    required this.diary,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('รายละเอียด'),
      ),

      body: Padding(
        padding: const EdgeInsets.all(20),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [
            Text(
              diary.title,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 4),

            Text(
              diary.date,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              'อารมณ์: ${diary.mood}',
              style: const TextStyle(
                fontSize: 16,
              ),
            ),

            const Divider(height: 32),

            Text(
              diary.content,
              style: const TextStyle(
                fontSize: 16,
                height: 1.6,
              ),
            ),
          ],
        ),
      ),
    );
  }
}