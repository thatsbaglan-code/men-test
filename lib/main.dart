import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:docx_to_text/docx_to_text.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/* ================= GLOBAL STATE ================= */

final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.light);

enum AppLanguage { kk, ru, en }

final ValueNotifier<AppLanguage> languageNotifier =
    ValueNotifier(AppLanguage.kk);

final ValueNotifier<double> textScaleNotifier = ValueNotifier(1.0);

// ✅ Forces MyTestsPage to refresh even with IndexedStack
final ValueNotifier<int> testsRevision = ValueNotifier<int>(0);
void bumpTestsRevision() => testsRevision.value = testsRevision.value + 1;

Locale localeFor(AppLanguage lang) {
  
  switch (lang) {
    case AppLanguage.kk:
      return const Locale('kk');
    case AppLanguage.ru:
      return const Locale('ru');
    case AppLanguage.en:
      return const Locale('en');
  }
}

const Map<String, Map<AppLanguage, String>> _tr = {
  'app_title': {
    AppLanguage.en: 'Test Builder',
    AppLanguage.ru: 'Конструктор тестов',
    AppLanguage.kk: 'Тест құрастырушы',
  },
  'tab_my_tests': {
    AppLanguage.en: 'My tests',
    AppLanguage.ru: 'Мои тесты',
    AppLanguage.kk: 'Менің тесттерім',
  },
  'tab_create_test': {
    AppLanguage.en: 'Create test',
    AppLanguage.ru: 'Создать тест',
    AppLanguage.kk: 'Тест жасау',
  },
  'tab_settings': {
    AppLanguage.en: 'Settings',
    AppLanguage.ru: 'Настройки',
    AppLanguage.kk: 'Баптаулар',
  },
  'create_test_title': {
    AppLanguage.en: 'Create Test',
    AppLanguage.ru: 'Создать тест',
    AppLanguage.kk: 'Тест жасау',
  },
  'import_file': {
    AppLanguage.en: 'Import txt / docx',
    AppLanguage.ru: 'Импорт txt / docx',
    AppLanguage.kk: 'txt / docx импорттау',
  },
  'save_test': {
    AppLanguage.en: 'Save Test',
    AppLanguage.ru: 'Сохранить тест',
    AppLanguage.kk: 'Тестті сақтау',
  },
  'my_tests_title': {
    AppLanguage.en: 'My Tests',
    AppLanguage.ru: 'Мои тесты',
    AppLanguage.kk: 'Менің тесттерім',
  },
  'play_test': {
    AppLanguage.en: 'Play Test',
    AppLanguage.ru: 'Пройти тест',
    AppLanguage.kk: 'Тест тапсыру',
  },
  'review_test': {
    AppLanguage.en: 'Review Test',
    AppLanguage.ru: 'Просмотр теста',
    AppLanguage.kk: 'Тесті қарау',
  },
  'result': {
    AppLanguage.en: 'Result',
    AppLanguage.ru: 'Результат',
    AppLanguage.kk: 'Нәтиже',
  },
  'main_menu': {
    AppLanguage.en: 'Main Menu',
    AppLanguage.ru: 'Главное меню',
    AppLanguage.kk: 'Басты мәзір',
  },
  'language': {
    AppLanguage.en: 'Language',
    AppLanguage.ru: 'Язык',
    AppLanguage.kk: 'Тіл',
  },
  'theme': {
    AppLanguage.en: 'Theme',
    AppLanguage.ru: 'Тема',
    AppLanguage.kk: 'Тақырып',
  },
  'dark_mode': {
    AppLanguage.en: 'Dark mode',
    AppLanguage.ru: 'Тёмный режим',
    AppLanguage.kk: 'Қараңғы режим',
  },
  'instruction_title': {
    AppLanguage.en: 'How to create a test',
    AppLanguage.ru: 'Как создать тест',
    AppLanguage.kk: 'Тест қалай жасалады',
  },
  'instruction_content': {
    AppLanguage.en:
        '1. Prepare your file in .txt or .docx format.\n2. Use <question> tag for questions.\n3. Use <answer> tag for answer options.\n4. IMPORTANT: The first <answer> after a question must be the CORRECT one. The app will shuffle them randomly during the test.\n\nExample:\n<question> What is 2+2?\n<answer> 4\n<answer> 3\n<answer> 5',
    AppLanguage.ru:
        '1. Подготовьте файл в формате .txt или .docx.\n2. Используйте тег <question> для вопросов.\n3. Используйте тег <answer> для вариантов ответа.\n4. ВАЖНО: Первый <answer> после вопроса должен быть ПРАВИЛЬНЫМ. Приложение перемешает их случайно во время теста.\n\nПример:\n<question> Сколько будет 2+2?\n<answer> 4\n<answer> 3\n<answer> 5',
    AppLanguage.kk:
        '1. Файлды .txt немесе .docx форматында дайындаңыз.\n2. Сұрақтар үшін <question> тегін қолданыңыз.\n3. Жауап нұсқалары үшін <answer> тегін қолданыңыз.\n4. МАҢЫЗДЫ: Сұрақтан кейінгі бірінші <answer> ДҰРЫС жауап болуы керек. Қолданба тест кезінде оларды кездейсоқ араластырады.\n\nМысалы:\n<question> 2+2 қанша болады?\n<answer> 4\n<answer> 3\n<answer> 5',
  },
  'welcome_title': {
    AppLanguage.en: 'Welcome to Test Builder!',
    AppLanguage.ru: 'Добро пожаловать!',
    AppLanguage.kk: 'Қош келдіңіз!',
  },
  'welcome_desc': {
    AppLanguage.en: 'Create your first test by importing a file or pasting text. It\'s easy!',
    AppLanguage.ru: 'Создайте свой первый тест, импортировав файл или вставив текст. Это просто!',
    AppLanguage.kk: 'Файлды импорттау немесе мәтінді қою арқылы алғашқы тестіңізді жасаңыз. Бұл оңай!',
  },
  'font_size': {
    AppLanguage.en: 'Font size',
    AppLanguage.ru: 'Размер шрифта',
    AppLanguage.kk: 'Қаріп өлшемі',
  },
  'question_word': {
    AppLanguage.en: 'Question',
    AppLanguage.ru: 'Вопрос',
    AppLanguage.kk: 'Сұрақ',
  },
  'score': {
    AppLanguage.en: 'Score',
    AppLanguage.ru: 'Счет',
    AppLanguage.kk: 'Ұпай',
  },
  'start_mock': {
    AppLanguage.en: 'Start Mock Test',
    AppLanguage.ru: 'Начать пробный тест',
    AppLanguage.kk: 'Сынақ тестін бастау',
  },
  'prev': {
    AppLanguage.en: 'Prev',
    AppLanguage.ru: 'Назад',
    AppLanguage.kk: 'Артқа',
  },
  'next': {
    AppLanguage.en: 'Next',
    AppLanguage.ru: 'Далее',
    AppLanguage.kk: 'Келесі',
  },
  'finish': {
    AppLanguage.en: 'Finish',
    AppLanguage.ru: 'Завершить',
    AppLanguage.kk: 'Аяқтау',
  },
  'back_home': {
    AppLanguage.en: 'Back to Home',
    AppLanguage.ru: 'На главную',
    AppLanguage.kk: 'Басты бетке',
  },
  'review_answers': {
    AppLanguage.en: 'Review Answers',
    AppLanguage.ru: 'Просмотр ответов',
    AppLanguage.kk: 'Жауаптарды қарау',
  },
  'correct_label': {
    AppLanguage.en: 'Correct',
    AppLanguage.ru: 'Правильно',
    AppLanguage.kk: 'Дұрыс',
  },
  'great_job': {
    AppLanguage.en: 'Great Job!',
    AppLanguage.ru: 'Отлично!',
    AppLanguage.kk: 'Жарайсыз!',
  },
  'keep_practicing': {
    AppLanguage.en: 'Keep Practicing',
    AppLanguage.ru: 'Продолжайте практиковаться',
    AppLanguage.kk: 'Дайындала түсіңіз',
  },
};

String tr(BuildContext context, String key) {
  final lang = languageNotifier.value;
  return _tr[key]?[lang] ?? _tr[key]?[AppLanguage.en] ?? key;
}

/* ================= MODELS ================= */

class Question {
  final String text;
  final List<String> answers;
  final String correct;

  Question({
    required this.text,
    required this.answers,
    required this.correct,
  });

  Map<String, dynamic> toJson() => {
        'text': text,
        'answers': answers,
        'correct': correct,
      };

  factory Question.fromJson(Map<String, dynamic> json) => Question(
        text: json['text'] as String,
        answers: List<String>.from(json['answers'] as List),
        correct: json['correct'] as String,
      );
}

class Test {
  final String name;
  final List<Question> questions;

  Test(this.name, this.questions);

  Map<String, dynamic> toJson() => {
        'name': name,
        'questions': questions.map((q) => q.toJson()).toList(),
      };

  factory Test.fromJson(Map<String, dynamic> json) => Test(
        json['name'] as String,
        (json['questions'] as List)
            .map((q) => Question.fromJson(q as Map<String, dynamic>))
            .toList(),
      );
}

class TestGroup {
  String name;
  final List<Test> tests;

  TestGroup({required this.name, required this.tests});

  Map<String, dynamic> toJson() => {
        'name': name,
        'tests': tests.map((t) => t.toJson()).toList(),
      };

  factory TestGroup.fromJson(Map<String, dynamic> json) => TestGroup(
        name: json['name'] as String,
        tests: (json['tests'] as List)
            .map((t) => Test.fromJson(t as Map<String, dynamic>))
            .toList(),
      );
}

/* ================= STORAGE ================= */

class TestStorage {
  static const _testsKey = 'saved_tests_v2'; // Changed key to force migration/separation or we can reuse check
  static const _oldTestsKey = 'saved_tests';

  static const _themeKey = 'theme_mode';
  static const _langKey = 'app_language';
  static const _textScaleKey = 'text_scale';

  static List<TestGroup> groups = [];

  static Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();

    final rawV2 = prefs.getString(_testsKey);
    if (rawV2 != null) {
      try {
        final decoded = jsonDecode(rawV2) as List;
        groups = decoded
            .map((e) => TestGroup.fromJson(e as Map<String, dynamic>))
            .toList();
      } catch (_) {
        groups = [];
      }
    } else {
      // Migration from v1
      final rawV1 = prefs.getString(_oldTestsKey);
      if (rawV1 != null) {
        try {
          final decoded = jsonDecode(rawV1) as List;
          final oldTests = decoded
              .map((e) => Test.fromJson(e as Map<String, dynamic>))
              .toList();
          
          groups = oldTests.map((t) => TestGroup(name: t.name, tests: [t])).toList();
          await saveTests(); // Save immediately in new format
        } catch (_) {
          groups = [];
        }
      }
    }

    final theme = prefs.getString(_themeKey);
    if (theme == 'dark') themeNotifier.value = ThemeMode.dark;
    if (theme == 'light') themeNotifier.value = ThemeMode.light;

    final lang = prefs.getString(_langKey);
    if (lang == 'kk') languageNotifier.value = AppLanguage.kk;
    if (lang == 'ru') languageNotifier.value = AppLanguage.ru;
    if (lang == 'en') languageNotifier.value = AppLanguage.en;

    final scale = prefs.getDouble(_textScaleKey);
    if (scale != null) textScaleNotifier.value = scale;
  }

  static Future<void> saveTests() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _testsKey,
      jsonEncode(groups.map((g) => g.toJson()).toList()),
    );
  }

  static Future<void> saveTheme(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _themeKey,
      mode == ThemeMode.dark ? 'dark' : 'light',
    );
  }

  static Future<void> saveLanguage(AppLanguage lang) async {
    final prefs = await SharedPreferences.getInstance();
    final code = switch (lang) {
      AppLanguage.kk => 'kk',
      AppLanguage.ru => 'ru',
      AppLanguage.en => 'en',
    };
    await prefs.setString(_langKey, code);
  }

  static Future<void> saveTextScale(double scale) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_textScaleKey, scale);
  }
}

/* ================= PARSER ================= */

List<Question> parseQuestions(String raw) {
  final lines = raw
      .split('\n')
      .map((e) => e.trim())
      .where((e) => e.isNotEmpty)
      .toList();

  final List<Question> questions = [];

  String? currentQuestion;
  final List<String> currentVariants = [];

  // Robust Prefix Regexes
  // Detects start of line, optional junk, keyword, optional junk.
  // Stops matching before the "content" begins.
  // Does NOT use replaceAll on the whole line to avoid eating partial matches later.
  // REMOVED '<' from the suffix class to avoid eating start of content like "<<Quote"
  final qRegex = RegExp(r'^[<>;\s#]*question[>;:\s\.]*', caseSensitive: false);
  final vRegex = RegExp(r'^[<>;\s#]*(variant|answer)[>;:\s\.]*', caseSensitive: false);

  String cleanContent(String text) {
    // 1. Trim surrounding whitespace
    String s = text.trim();
    
    // 2. Remove standard bullet points if they exist at the start
    // Matches: "1. ", "1) ", "- ", "* ", "• "
    final bulletMatch = RegExp(r'^(\d+[\.\)]|[\-*\u2022])\s+').firstMatch(s);
    if (bulletMatch != null) {
      s = s.substring(bulletMatch.end).trim();
    }
    return s;
  }

  void flushQuestion() {
    if (currentQuestion != null && currentVariants.isNotEmpty) {
      questions.add(
        Question(
          text: currentQuestion!,
          answers: List<String>.from(currentVariants),
          correct: currentVariants.first,
        ),
      );
    }
  }

  for (final line in lines) {
    // 1. Check if line starts with Question tag
    final qMatch = qRegex.firstMatch(line);
    if (qMatch != null) {
      flushQuestion();
      // Extract everything AFTER the tag
      String content = line.substring(qMatch.end);
      currentQuestion = cleanContent(content);
      currentVariants.clear();
      continue; 
    }

    // 2. Check if line starts with Variant/Answer tag
    final vMatch = vRegex.firstMatch(line);
    if (vMatch != null) {
      String content = line.substring(vMatch.end);
      final cleaned = cleanContent(content);
      if (cleaned.isNotEmpty) {
        currentVariants.add(cleaned);
      }
      continue;
    }
  }

  flushQuestion();

  // Shuffle answers but keep correct answer tracked
  for (final q in questions) {
    final correct = q.correct;
    q.answers.shuffle(Random());
    if (!q.answers.contains(correct)) {
      q.answers.insert(0, correct);
    }
  }

  return questions;
}

/* ================= MAIN ================= */

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await TestStorage.load();
  runApp(const MyApp());
}

/* ================= APP ================= */

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: themeNotifier,
      builder: (_, ThemeMode mode, __) {
        return ValueListenableBuilder(
          valueListenable: languageNotifier,
          builder: (_, AppLanguage lang, __) {
            return ValueListenableBuilder(
              valueListenable: textScaleNotifier,
              builder: (_, double scale, __) {
                return MaterialApp(
                  debugShowCheckedModeBanner: false,
                  builder: (context, child) {
                    return MediaQuery(
                      data: MediaQuery.of(context).copyWith(
                        textScaler: TextScaler.linear(scale),
                      ),
                      child: child!,
                    );
                  },
                  theme: ThemeData(
                    useMaterial3: true,
                brightness: Brightness.light,
                colorScheme: ColorScheme.fromSeed(
                  seedColor: Colors.indigo,
                  primary: Colors.indigo,
                  secondary: Colors.indigo,
                  tertiary: Colors.amber,
                  background: Color(0xFFF5F7FA),
                  surface: Colors.white,
                ),
                scaffoldBackgroundColor: const Color(0xFFF5F7FA),
                appBarTheme: const AppBarTheme(
                  backgroundColor: Color(0xFFF5F7FA),
                  foregroundColor: Colors.indigo,
                  elevation: 0,
                  centerTitle: true,
                ),
                elevatedButtonTheme: ElevatedButtonThemeData(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo,
                    foregroundColor: Colors.white,
                  ),
                ),
                cardTheme: const CardThemeData(
                  color: Colors.white,
                  surfaceTintColor: Colors.white,
                  elevation: 2,
                ),
              ),
              darkTheme: ThemeData(
                useMaterial3: true,
                brightness: Brightness.dark,
                colorScheme: ColorScheme.fromSeed(
                  seedColor: Colors.indigo,
                  brightness: Brightness.dark,
                  primary: Colors.indigo[200],
                  secondary: Colors.indigo[200],
                  tertiary: Colors.amberAccent,
                  background: const Color(0xFF101014),
                  surface: const Color(0xFF1E1E1E),
                ),
                scaffoldBackgroundColor: const Color(0xFF101014),
                appBarTheme: const AppBarTheme(
                  backgroundColor: Color(0xFF1E1E1E),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  centerTitle: true,
                ),
                cardTheme: CardThemeData(
                  color: const Color(0xFF1E1E1E),
                  surfaceTintColor: const Color(0xFF1E1E1E),
                  elevation: 2,
                ),
              ),
              themeMode: mode,
              locale: localeFor(lang),
              localizationsDelegates: const [
                DefaultMaterialLocalizations.delegate,
                DefaultWidgetsLocalizations.delegate,
              ],
                  home: const HomeShell(),
                );
              },
            );
          },
        );
      },
    );
  }
}

/* ================= HOME SHELL ================= */

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _currentIndex = 0;

  void _goToMyTests() {
    setState(() => _currentIndex = 0);
  }

  final List<Widget> _pages = [];

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    // Rebuild pages when index changes is standard for simple nav, 
    // but for persistence we might use IndexedStack. 
    // The original used CupertinoTabScaffold which keeps state.
    // We'll use IndexedStack to match that behavior.
    
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
           MyTestsPage(onCreateTest: () => setState(() => _currentIndex = 1)),
           CreateTestPage(onSaved: _goToMyTests),
           const SettingsPage(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.description_outlined),
            selectedIcon: const Icon(Icons.description),
            label: tr(context, 'tab_my_tests'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.add_circle_outline),
            selectedIcon: const Icon(Icons.add_circle),
            label: tr(context, 'tab_create_test'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.settings_outlined),
            selectedIcon: const Icon(Icons.settings),
            label: tr(context, 'tab_settings'),
          ),
        ],
      ),
    );
  }
}

/* ================= SETTINGS ================= */

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  void _showLanguagePicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(tr(context, 'language'), style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            ...AppLanguage.values.map((lang) => ListTile(
              title: Text(_getLangName(lang)),
              onTap: () {
                languageNotifier.value = lang;
                TestStorage.saveLanguage(lang);
                Navigator.pop(context);
              },
              trailing: languageNotifier.value == lang ? const Icon(Icons.check) : null,
            )),
          ],
        ),
      ),
    );
  }

  String _getLangName(AppLanguage lang) {
    return switch (lang) {
      AppLanguage.kk => 'Қазақша',
      AppLanguage.ru => 'Русский',
      AppLanguage.en => 'English',
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(tr(context, 'tab_settings')),
      ),
      body: ListView(
        children: [
          _buildSectionHeader(context, tr(context, 'language')),
          ValueListenableBuilder(
            valueListenable: languageNotifier,
            builder: (_, AppLanguage lang, __) {
              return ListTile(
                title: Text(tr(context, 'language')),
                subtitle: Text(_getLangName(lang)),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showLanguagePicker(context),
              );
            },
          ),
          const Divider(),
          _buildSectionHeader(context, tr(context, 'theme')),
          ValueListenableBuilder(
            valueListenable: themeNotifier,
            builder: (_, ThemeMode mode, __) {
              final isDark = mode == ThemeMode.dark;
              return SwitchListTile(
                title: Text(tr(context, 'dark_mode')),
                value: isDark,
                onChanged: (v) async {
                  themeNotifier.value = v ? ThemeMode.dark : ThemeMode.light;
                  await TestStorage.saveTheme(themeNotifier.value);
                },
              );
            },
          ),
          const Divider(),
          _buildSectionHeader(context, tr(context, 'font_size')),
          ValueListenableBuilder(
            valueListenable: textScaleNotifier,
            builder: (_, double scale, __) {
              return Column(
                children: [
                  Slider(
                    value: scale,
                    min: 0.8,
                    max: 1.4,
                    divisions: 6,
                    label: scale.toStringAsFixed(1),
                    onChanged: (v) {
                      textScaleNotifier.value = v;
                      TestStorage.saveTextScale(v);
                    },
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('A', style: TextStyle(fontSize: 14 * 0.8 / scale)), // Visual hint small
                        Text('A', style: TextStyle(fontSize: 14 * 1.4 / scale)), // Visual hint large
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }
}

/* ================= CREATE TEST ================= */

class CreateTestPage extends StatefulWidget {
  final VoidCallback? onSaved;

  const CreateTestPage({super.key, this.onSaved});

  @override
  State<CreateTestPage> createState() => _CreateTestPageState();
}

class _CreateTestPageState extends State<CreateTestPage> {
  final TextEditingController nameCtrl = TextEditingController();
  final TextEditingController textCtrl = TextEditingController();

  @override
  void dispose() {
    nameCtrl.dispose();
    textCtrl.dispose();
    super.dispose();
  }

  void _showAlert(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showInstructions() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(tr(context, 'instruction_title')),
        content: SingleChildScrollView(
          child: Text(tr(context, 'instruction_content')),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> importFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.any,
      withData: true,
    );

    if (result == null || result.files.single.bytes == null) return;

    final file = result.files.single;
    final bytes = file.bytes!;
    final name = file.name.toLowerCase();
    
    if (!name.endsWith('.txt') && !name.endsWith('.docx')) {
      if (!mounted) return;
      _showAlert('Invalid File', 'Please select a .txt or .docx file.');
      return;
    }

    String content = '';

    try {
      if (name.endsWith('.txt')) {
        content = utf8.decode(bytes);
      } else if (name.endsWith('.docx')) {
        content = docxToText(bytes);
      }
    } catch (e) {
      if (!mounted) return;
      _showAlert('Import Failed', e.toString());
      return;
    }

    textCtrl.text = content;
    setState(() {});
  }

  Future<void> saveTest() async {
    final testName = nameCtrl.text.trim();
    if (testName.isEmpty) {
      _showAlert('Missing Info', 'Please enter a test name');
      return;
    }

    final raw = textCtrl.text.trim();
    if (raw.isEmpty) {
      _showAlert('Missing Info', 'Please paste/import test text');
      return;
    }

    try {
      final questions = parseQuestions(raw);

      if (questions.isEmpty) {
        if (!mounted) return;
        _showAlert('Format Error', 'No questions found. Use <question> and <answer> tags.');
        return;
      }

      final List<Test> subTests = [];
      const chunkSize = 50;

      for (var i = 0; i < questions.length; i += chunkSize) {
        final end = (i + chunkSize < questions.length) ? i + chunkSize : questions.length;
        final subQuestions = questions.sublist(i, end);
        final subName = '$testName ${subTests.length + 1}';
        subTests.add(Test(subName, subQuestions));
      }

      TestStorage.groups.add(TestGroup(name: testName, tests: subTests));
      await TestStorage.saveTests();

      // ✅ important for IndexedStack refresh
      bumpTestsRevision();

      if (!mounted) return;

      // Navigate back / switch tab
      widget.onSaved?.call();
      
    } catch (e) {
      if (!mounted) return;
      _showAlert('Save Failed', e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(tr(context, 'create_test_title')),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: _showInstructions,
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              TextField(
                controller: nameCtrl,
                decoration: InputDecoration(
                  labelText: 'Test name',
                  border: const OutlineInputBorder(),
                  filled: true,
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: importFile,
                  child: Text(tr(context, 'import_file')),
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: TextField(
                  controller: textCtrl,
                  minLines: null,
                  maxLines: null,
                  expands: true,
                  textAlignVertical: TextAlignVertical.top,
                  decoration: InputDecoration(
                    hintText: '<question> Question text\n<answer> Correct answer first\n<answer> Option 2\n<answer> Option 3',
                    border: const OutlineInputBorder(),
                    filled: true,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: saveTest,
                  child: Text(tr(context, 'save_test')),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/* ================= MY TESTS ================= */

class MyTestsPage extends StatefulWidget {
  final VoidCallback? onCreateTest;
  const MyTestsPage({super.key, this.onCreateTest});

  @override
  State<MyTestsPage> createState() => _MyTestsPageState();
}

class _MyTestsPageState extends State<MyTestsPage> {
  // UI: compact list by default (grid is optional).
  bool _useGridView = false;

  // Selection Mode
  bool _isSelectionMode = false;
  final Set<int> _selectedGroups = {};

  void _toggleSelectionMode(TestGroup? group, int index) {
    setState(() {
      _isSelectionMode = !_isSelectionMode;
      _selectedGroups.clear();
      if (_isSelectionMode && group != null) {
        _selectedGroups.add(index);
      }
    });
  }

  void _toggleGroupSelection(int index) {
    setState(() {
      if (_selectedGroups.contains(index)) {
        _selectedGroups.remove(index);
        if (_selectedGroups.isEmpty) {
          _isSelectionMode = false;
        }
      } else {
        _selectedGroups.add(index);
      }
    });
  }

  Future<void> _deleteSelectedGroups() async {
    final count = _selectedGroups.length;
    if (count == 0) return;

    final confirm = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Delete $count Group${count > 1 ? 's' : ''}?'),
            content: const Text('This will delete all tests in selected groups. Action cannot be undone.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Delete', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        ) ??
        false;

    if (confirm) {
      // Delete in descending order of index to avoid shifting issues
      final indices = _selectedGroups.toList()..sort((a, b) => b.compareTo(a));
      for (final i in indices) {
        TestStorage.groups.removeAt(i);
      }
      await TestStorage.saveTests();
      bumpTestsRevision();
      setState(() {
        _selectedGroups.clear();
        _isSelectionMode = false;
      });
    }
  }

  Future<void> deleteGroup(int i) async {
    TestStorage.groups.removeAt(i);
    await TestStorage.saveTests();
    bumpTestsRevision();
    setState(() {});
  }

  void _openGroup(BuildContext context, TestGroup group, int index) {
    if (_isSelectionMode) {
      _toggleGroupSelection(index);
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => GroupDetailPage(group: group)),
    );
  }

  Future<void> _confirmDeleteGroup(BuildContext context, int i) async {
    final confirm = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete Group?'),
            content: const Text('This will delete all tests in this group. Action cannot be undone.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Delete', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        ) ??
        false;
    if (confirm) await deleteGroup(i);
  }

  Widget _buildGroupItem(BuildContext context, TestGroup group, int i, {required bool grid}) {
    final scheme = Theme.of(context).colorScheme;
    final leading = Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: scheme.tertiary.withOpacity(0.18),
        borderRadius: BorderRadius.circular(10),
      ),
      alignment: Alignment.center,
      child: Icon(Icons.folder_rounded, size: 20, color: scheme.tertiary),
    );

    if (!grid) {
      return Hero(
        tag: 'group_${group.name}',
        child: Material(
          color: Colors.transparent,
          child: Card(
            margin: EdgeInsets.zero,
            elevation: 1,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            clipBehavior: Clip.antiAlias,
            child: ListTile(
              dense: true,
              visualDensity: const VisualDensity(vertical: -2),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              leading: SizedBox(
                width: 36,
                height: 36,
                child: leading,
              ),
              minLeadingWidth: 40,
              title: Text(group.name, maxLines: 1, overflow: TextOverflow.ellipsis),
              subtitle: Text('${group.tests.length} tests', maxLines: 1, overflow: TextOverflow.ellipsis),
              trailing: IconButton(
                tooltip: 'Delete group',
                icon: const Icon(Icons.delete_outline, size: 20),
                onPressed: () => _confirmDeleteGroup(context, i),
              ),
              onTap: () => _openGroup(context, group, i),
              onLongPress: () => _toggleSelectionMode(group, i),
              selected: _selectedGroups.contains(i),
              selectedTileColor: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.2),
            ),
          ),
        ),
      );
    }

    // Grid variant (still compact)
    return Hero(
      tag: 'group_${group.name}',
      child: Material(
        color: Colors.transparent,
        child: Card(
          margin: EdgeInsets.zero,
          elevation: 1,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          clipBehavior: Clip.antiAlias,
          color: _selectedGroups.contains(i)
              ? Theme.of(context).colorScheme.primaryContainer.withOpacity(0.2)
              : null,
          child: InkWell(
            onTap: () => _openGroup(context, group, i),
            onLongPress: () => _toggleSelectionMode(group, i),
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  leading,
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          group.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${group.tests.length} tests',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Delete group',
                    icon: const Icon(Icons.delete_outline, size: 20),
                    onPressed: () => _confirmDeleteGroup(context, i),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: testsRevision,
      builder: (context, _, __) {
        return Scaffold(
          body: CustomScrollView(
            slivers: [
              SliverAppBar(
                floating: true,
                pinned: true,
                expandedHeight: 120.0,
                leading: _isSelectionMode
                    ? IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => _toggleSelectionMode(null, -1),
                      )
                    : null,
                actions: [
                  if (_isSelectionMode)
                   IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      onPressed: _deleteSelectedGroups,
                    )
                  else
                    IconButton(
                      tooltip: _useGridView ? 'List view' : 'Grid view',
                      icon: Icon(_useGridView ? Icons.view_list_rounded : Icons.grid_view_rounded),
                      onPressed: () => setState(() => _useGridView = !_useGridView),
                    ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  centerTitle: true,
                  title: Text(
                      _isSelectionMode
                          ? '${_selectedGroups.length} selected'
                          : tr(context, 'my_tests_title'),
                      style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
                  background: Container(
                    color: Theme.of(context).scaffoldBackgroundColor,
                  ),
                ),
              ),
              if (TestStorage.groups.isEmpty)
                SliverFillRemaining(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.library_books_rounded,
                            size: 80,
                            color: Theme.of(context).colorScheme.tertiary,
                          ),
                          const SizedBox(height: 24),
                          Text(
                            tr(context, 'welcome_title'),
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            tr(context, 'welcome_desc'),
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 32),
                          FilledButton.icon(
                            onPressed: widget.onCreateTest,
                            icon: const Icon(Icons.add_circle_outline),
                            label: Text(tr(context, 'tab_create_test')),
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: _useGridView
                      ? SliverGrid(
                          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                            maxCrossAxisExtent: 260,
                            mainAxisSpacing: 8,
                            crossAxisSpacing: 8,
                            childAspectRatio: 2.4,
                          ),
                          delegate: SliverChildBuilderDelegate(
                            (context, i) {
                              final group = TestStorage.groups[i];
                              return _buildGroupItem(context, group, i, grid: true);
                            },
                            childCount: TestStorage.groups.length,
                          ),
                        )
                      : SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, i) {
                              final group = TestStorage.groups[i];
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: _buildGroupItem(context, group, i, grid: false),
                              );
                            },
                            childCount: TestStorage.groups.length,
                          ),
                        ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class GroupDetailPage extends StatefulWidget {
  final TestGroup group;
  const GroupDetailPage({super.key, required this.group});

  @override
  State<GroupDetailPage> createState() => _GroupDetailPageState();
}

class _GroupDetailPageState extends State<GroupDetailPage> {
  // Selection Mode
  bool _isSelectionMode = false;
  final Set<Test> _selectedTests = {};

  void _toggleSelectionMode(Test? test) {
    setState(() {
      _isSelectionMode = !_isSelectionMode;
      _selectedTests.clear();
      if (_isSelectionMode && test != null) {
        _selectedTests.add(test);
      }
    });
  }

  void _toggleTestSelection(Test test) {
    setState(() {
      if (_selectedTests.contains(test)) {
        _selectedTests.remove(test);
        if (_selectedTests.isEmpty) {
          _isSelectionMode = false;
        }
      } else {
        _selectedTests.add(test);
      }
    });
  }

  Future<void> _deleteSelectedTests() async {
    final count = _selectedTests.length;
    if (count == 0) return;

    final confirm = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Delete $count Test${count > 1 ? 's' : ''}?'),
            content: const Text('This action cannot be undone.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Delete', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        ) ??
        false;

    if (confirm) {
      widget.group.tests.removeWhere((t) => _selectedTests.contains(t));
      await TestStorage.saveTests();
      setState(() {
        _selectedTests.clear();
        _isSelectionMode = false;
      });
    }
  }

  Future<void> deleteTest(int i) async {
    widget.group.tests.removeAt(i);
    await TestStorage.saveTests();
    setState(() {});
  }

  void _showActionSheet(BuildContext context, Test test) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: Text(test.name, style: Theme.of(context).textTheme.titleLarge),
              ),
              ListTile(
                leading: const Icon(Icons.play_arrow),
                title: Text(tr(context, 'play_test')),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => PlayTestPage(test: test)),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.rate_review),
                title: Text(tr(context, 'review_test')),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => ReviewPage(test: test)),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Delete Test', style: TextStyle(color: Colors.red)),
                onTap: () async {
                  Navigator.pop(context);
                  final idx = widget.group.tests.indexOf(test);
                  if (idx != -1) {
                     final confirm = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Delete Test?'),
                          content: const Text('This action cannot be undone.'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text('Delete', style: TextStyle(color: Colors.red)),
                            ),
                          ],
                        ),
                      ) ?? false;
                     if (confirm) deleteTest(idx);
                  }
                },
              ),
            ],
          ),
        ),
      ),

    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: widget.group.tests.isNotEmpty && !_isSelectionMode
          ? FloatingActionButton.extended(
              onPressed: () {
                // Flatten all questions
                final allQuestions = widget.group.tests.expand((t) => t.questions).toList();
                if (allQuestions.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No questions available')));
                  return;
                }
                // Shuffle and pick 50
                allQuestions.shuffle();
                final mockQuestions = allQuestions.take(50).toList();

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => MockTestPage(
                      groupName: widget.group.name,
                      questions: mockQuestions,
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.timer_outlined),
              label: Text(tr(context, 'start_mock')),
            )
          : null,
      appBar: AppBar(
        title: _isSelectionMode
            ? Text('${_selectedTests.length} selected', style: const TextStyle(color: Colors.white))
            : Hero(
                tag: 'group_${widget.group.name}',
                child: Material(
                  color: Colors.transparent,
                  child: Text(
                    widget.group.name,
                    style: const TextStyle(color: Colors.white), // Ensure text color is fixed during hero
                  ),
                ),
              ),
        leading: _isSelectionMode
            ? IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => _toggleSelectionMode(null),
              )
            : null,
        actions: [
          if (_isSelectionMode)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: _deleteSelectedTests,
            )
        ],
      ),
      body: widget.group.tests.isEmpty
          ? Center(
              child: Text(
                'No tests in group',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.secondary,
                ),
              ),
            )
          : ListView.builder(
              itemCount: widget.group.tests.length,
              itemBuilder: (context, i) {
                final test = widget.group.tests[i];
                final isSelected = _selectedTests.contains(test);
                
                if (_isSelectionMode) {
                   return ListTile(
                    leading: isSelected 
                        ? Icon(Icons.check_circle, color: Theme.of(context).primaryColor)
                        : const Icon(Icons.circle_outlined),
                    title: Text(test.name),
                    selected: isSelected,
                    selectedTileColor: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.2),
                    onTap: () => _toggleTestSelection(test),
                    onLongPress: () => _toggleSelectionMode(test),
                  );
                }

                return Dismissible(
                  key: ValueKey(test),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    color: Colors.red,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 16),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  onDismissed: (_) => deleteTest(i),
                  confirmDismiss: (_) async {
                    return await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Delete Test?'),
                            content: const Text('This action cannot be undone.'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(context, true),
                                child: const Text('Delete', style: TextStyle(color: Colors.red)),
                              ),
                            ],
                          ),
                        ) ??
                        false;
                  },
                  child: ListTile(
                    leading: const Icon(Icons.assignment_outlined, color: Colors.blue),
                    title: Text(test.name),
                    trailing: const Icon(Icons.more_vert),
                    onTap: () => _showActionSheet(context, test),
                    onLongPress: () => _toggleSelectionMode(test),
                  ),
                );
              },
            ),
    );
  }
}

/* ================= PLAY TEST ================= */

class PlayTestPage extends StatefulWidget {
  final Test test;

  const PlayTestPage({super.key, required this.test});

  @override
  State<PlayTestPage> createState() => _PlayTestPageState();
}

class _PlayTestPageState extends State<PlayTestPage> {
  int index = 0;
  final Map<int, String> selected = {};
  
  // New state for instant feedback
  bool isAnswered = false;
  int currentScore = 0;

  List<Question> get questions => widget.test.questions;

  @override
  void initState() {
    super.initState();
    // Helper to restore state if revisiting index (though simple logic resets on next/prev for now or persists)
    // For this requirements: "instant feedback", usually implies strict forward flow or state retention.
    // We'll keep it simple: reset isAnswered when moving, unless we want to keep history.
    // But since score is live, we should probably just lock the question once answered.
    // Let's check if we have an answer for current index.
  }

  void pick(String ans) {
    if (isAnswered) return; // Lock if already answered

    final correct = questions[index].correct;
    selected[index] = ans;
    isAnswered = true;

    if (ans == correct) {
      currentScore++;
    }

    setState(() {});
  }

  void next() {
    if (index < questions.length - 1) {
      setState(() {
        index++;
        // Reset state for next question if not already answered (persistence check)
        // If we want to allow going back and seeing result, we need to track "isAnswered" per question.
        // For simplicity and standard quiz flow, we'll assume forward progress or re-check.
        // Let's check if we have a selected answer for the new index.
        final prevAns = selected[index];
        isAnswered = prevAns != null; 
      });
      return;
    }

    // Finish
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => ResultPage(
          test: widget.test,
          selected: selected,
          score: currentScore,
        ),
      ),
    );
  }

  void prev() {
    if (index > 0) {
      setState(() {
        index--;
        final prevAns = selected[index];
        isAnswered = prevAns != null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final q = questions[index];
    final sel = selected[index];

    return Scaffold(
      appBar: AppBar(
        title: Text('${tr(context, "question_word")} ${index + 1} / ${questions.length}'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(20),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                Text("${tr(context, 'score')}: "),
                Expanded(
                  child: LinearProgressIndicator(
                    value: questions.isNotEmpty ? currentScore / questions.length : 0,
                    backgroundColor: Colors.grey[300],
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
                  ),
                ),
                const SizedBox(width: 8),
                Text("$currentScore"),
              ],
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder: (child, animation) {
                   return FadeTransition(opacity: animation, child: SlideTransition(
                     position: Tween<Offset>(begin: const Offset(0.2, 0), end: Offset.zero).animate(animation),
                     child: child,
                   ));
                },
                child: KeyedSubtree(
                  key: ValueKey<int>(index),
                  child: Column(
                    children: [
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.all(16),
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.secondaryContainer.withOpacity(0.4),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          q.text,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      Expanded(
                        child: ListView(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          children: q.answers.map((a) {
                            // Determine color
                            Color? tileColor;
                            Color? textColor;
                            IconData? icon;
                            Color? iconColor;

                            if (isAnswered) {
                              if (a == q.correct) {
                                tileColor = Colors.green.withOpacity(0.1);
                                textColor = Colors.green[800];
                                icon = Icons.check_circle;
                                iconColor = Colors.green;
                              } else if (sel == a) {
                                // This was the wrong answer picked
                                tileColor = Colors.red.withOpacity(0.1);
                                textColor = Colors.red[800];
                                icon = Icons.cancel;
                                iconColor = Colors.red;
                              }
                            } else {
                              if (sel == a) {
                                 tileColor = Theme.of(context).colorScheme.primaryContainer;
                              }
                            }

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Material(
                                color: tileColor ?? Theme.of(context).cardColor,
                                borderRadius: BorderRadius.circular(12),
                                elevation: isAnswered ? 0 : 2,
                                child: InkWell(
                                  onTap: isAnswered ? null : () => pick(a),
                                  borderRadius: BorderRadius.circular(12),
                                  child: Container(
                                    padding: const EdgeInsets.all(20),
                                    decoration: BoxDecoration(
                                      border: sel == a && !isAnswered 
                                          ? Border.all(color: Theme.of(context).primaryColor, width: 2)
                                          : null,
                                       borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            a,
                                            style: TextStyle(
                                              fontSize: 18,
                                              color: textColor,
                                              fontWeight: (isAnswered && a == q.correct) ? FontWeight.bold : null,
                                            ),
                                          ),
                                        ),
                                        if (icon != null) ...[
                                          const SizedBox(width: 8),
                                          Icon(icon, color: iconColor),
                                        ]
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  if (index > 0)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: prev,
                        child: Text(tr(context, 'prev')),
                      ),
                    )
                  else
                    const Spacer(),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: next,
                      child: Text(index == questions.length - 1 ? tr(context, 'finish') : tr(context, 'next')),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ReviewPage extends StatelessWidget {
  final Test test;
  const ReviewPage({super.key, required this.test});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${test.name} (Review)'),
      ),
      backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
      body: SafeArea(
        child: ListView.builder(
          itemCount: test.questions.length,
          itemBuilder: (_, i) {
            final q = test.questions[i];
            return Card(
              margin: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ListTile(
                    title: Text(
                      'Q${i + 1}: ${q.text}',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  ...q.answers.map(
                    (a) => ListTile(
                      title: Text(
                        a,
                        style: TextStyle(
                          color: a == q.correct ? Colors.green : null,
                          fontWeight: a == q.correct ? FontWeight.bold : null,
                        ),
                      ),
                      trailing: a == q.correct ? const Icon(Icons.check, color: Colors.green) : null,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class ResultPage extends StatelessWidget {
  final Test test;
  final Map<int, String> selected;
  final int score;

  const ResultPage({
    super.key,
    required this.test,
    required this.selected,
    required this.score,
  });

  @override
  Widget build(BuildContext context) {
    final percentage = (score / test.questions.length * 100).round();
    
    return Scaffold(
      appBar: AppBar(
        title: Text(tr(context, 'result')),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 200,
                  height: 200,
                  child: CircularProgressIndicator(
                    value: test.questions.isNotEmpty ? score / test.questions.length : 0,
                    strokeWidth: 20,
                    backgroundColor: Colors.grey[200],
                    valueColor: AlwaysStoppedAnimation<Color>(
                      score / test.questions.length > 0.7 ? Colors.green : Colors.orange,
                    ),
                    strokeCap: StrokeCap.round,
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$percentage%',
                      style: Theme.of(context).textTheme.displayLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    Text(
                      tr(context, 'score'),
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 48),
            Text(
              '$score / ${test.questions.length} ${tr(context, "correct_label")}',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              score / test.questions.length > 0.7 ? tr(context, 'great_job') : tr(context, 'keep_practicing'),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 60),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
                textStyle: const TextStyle(fontSize: 18),
              ),
              child: Text(tr(context, 'back_home')),
              onPressed: () => Navigator.pop(context),
            ),
            const SizedBox(height: 20),
            TextButton(
              onPressed: () {
                 // Create a temp test for review
                 final reviewTest = Test('Mock Review', test.questions);
                 Navigator.push(
                   context, 
                   MaterialPageRoute(builder: (_) => ReviewPage(test: reviewTest))
                 );
              }, 
              child: Text(tr(context, 'review_answers')),
            ),
          ],
        ),
      ),
    );
  }
}

class MockTestPage extends StatefulWidget {
  final String groupName;
  final List<Question> questions;

  const MockTestPage({super.key, required this.groupName, required this.questions});

  @override
  State<MockTestPage> createState() => _MockTestPageState();
}

class _MockTestPageState extends State<MockTestPage> {
  int index = 0;
  final Map<int, String> selected = {};
  late Timer _timer;
  int _secondsRemaining = 55 * 60; // 55 minutes

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        setState(() {
          _secondsRemaining--;
        });
      } else {
        _finishTest();
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  void _finishTest() {
    _timer.cancel();
    int score = 0;
    for (int i = 0; i < widget.questions.length; i++) {
      if (selected[i] == widget.questions[i].correct) score++;
    }

    // Create a temp test object to pass to ResultPage
    // Note: We need a test object to pass to result. We can construct one.
    final mockTestResult = Test('Mock Test: ${widget.groupName}', widget.questions);

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => ResultPage(
          test: mockTestResult,
          selected: selected,
          score: score,
        ),
      ),
    );
  }

  String get _timerString {
    final minutes = (_secondsRemaining / 60).floor();
    final seconds = _secondsRemaining % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  void pick(String ans) {
    selected[index] = ans;
    setState(() {});
  }

  void next() {
    if (index < widget.questions.length - 1) {
      setState(() => index++);
    } else {
      _finishTest();
    }
  }

  void prev() {
    if (index > 0) setState(() => index--);
  }

  @override
  Widget build(BuildContext context) {
    final q = widget.questions[index];
    final sel = selected[index];
    final isLowTime = _secondsRemaining < 60; // Red if under 1 min

    return Scaffold(
      appBar: AppBar(
        title: Text(_timerString),
        backgroundColor: isLowTime ? Colors.red[100] : null,
        foregroundColor: isLowTime ? Colors.red[900] : null,
        actions: [
           TextButton(
             onPressed: _finishTest,
             child: Text(tr(context, 'finish')),
           )
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Text(
                    '${tr(context, "question_word")} ${index + 1} / ${widget.questions.length}',
                    style: Theme.of(context).textTheme.titleMedium!.copyWith(color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.secondaryContainer.withOpacity(0.4),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      q.text,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                children: q.answers.map((a) {
                  return RadioListTile<String>(
                    title: Text(a, style: const TextStyle(fontSize: 18)),
                    value: a,
                    groupValue: sel,
                    onChanged: (v) => pick(v!),
                  );
                }).toList(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  if (index > 0)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: prev,
                        child: Text(tr(context, 'prev')),
                      ),
                    )
                  else
                    const Spacer(),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: next,
                      child: Text(index == widget.questions.length - 1 ? tr(context, 'finish') : tr(context, 'next')),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}