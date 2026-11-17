import 'package:flutter/material.dart';

void main() => runApp(const StudyTrackerApp());

// ---------------- Data Model ----------------
class Subject {
  String name;
  double progress; // 0.0 - 100.0, increments of 0.1
  final List<DateTime> history; // dates the subject was clicked/studied

  Subject({required this.name, this.progress = 0.0, List<DateTime>? history})
      : history = history ?? [];

  DateTime? get lastStudied => history.isEmpty ? null : history.last;

  String get progressLabel => '${progress.toStringAsFixed(1)}%';
}

// ---------------- App Root ----------------
class StudyTrackerApp extends StatelessWidget {
  const StudyTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Study Tracker',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: const SubjectListScreen(),
    );
  }
}

// ---------------- Main Screen ----------------
class SubjectListScreen extends StatefulWidget {
  const SubjectListScreen({super.key});

  @override
  State<SubjectListScreen> createState() => _SubjectListScreenState();
}

class _SubjectListScreenState extends State<SubjectListScreen> {
  final List<Subject> _subjects = [];

  static const double _progressStep = 0.1; // +0.1% per confirmed click

  // ---------- Add subject ----------
  void _addSubject() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('New Subject'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Subject name',
            hintText: 'e.g. Mathematics',
          ),
          onSubmitted: (_) => _saveSubject(controller, ctx),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => _saveSubject(controller, ctx),
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _saveSubject(TextEditingController controller, BuildContext ctx) {
    final name = controller.text.trim();
    if (name.isNotEmpty) {
      setState(() => _subjects.add(Subject(name: name)));
    }
    Navigator.pop(ctx);
  }

  // ---------- Confirm popup before clicking ----------
  void _onSubjectTap(Subject subject) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.menu_book_outlined, size: 36),
        title: Text(subject.name),
        content: Text(
          'Mark "${subject.name}" as studied?\n\n'
          'Progress will increase by ${_progressStep.toStringAsFixed(1)}%.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              _confirmStudy(subject);
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  // ---------- Record the click ----------
  void _confirmStudy(Subject subject) {
    setState(() {
      subject.history.add(DateTime.now());
      if (subject.progress < 100.0) {
        subject.progress =
            double.parse((subject.progress + _progressStep).toStringAsFixed(1));
        if (subject.progress > 100.0) subject.progress = 100.0;
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${subject.name}: ${subject.progressLabel} '
          '(${subject.history.length} sessions)',
        ),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  // ---------- History sheet ----------
  void _showHistory(Subject subject) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.5,
        maxChildSize: 0.85,
        builder: (_, scrollCtrl) => Padding(
          padding: const EdgeInsets.all(16),
          child: ListView(
            controller: scrollCtrl,
            children: [
              Center(
                child: Text(
                  '${subject.name} — Study History',
                  style: Theme.of(ctx).textTheme.titleLarge,
                ),
              ),
              const SizedBox(height: 12),
              if (subject.history.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: Text('No sessions recorded yet.')),
                )
              else
                ...subject.history.reversed.map(
                  (d) => Card(
                    child: ListTile(
                      leading: const Icon(Icons.check_circle_outline),
                      title: Text(_formatDateTime(d)),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDateTime(DateTime d) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(d.day)}-${two(d.month)}-${d.year}  '
        '${two(d.hour)}:${two(d.minute)}';
  }

  // ---------- Which subject needs attention? ----------
  Subject? get _needsAttention {
    if (_subjects.isEmpty) return null;
    final studied = _subjects.where((s) => s.lastStudied != null).toList();
    final notStudied = _subjects.where((s) => s.lastStudied == null).toList();
    if (notStudied.isNotEmpty) return notStudied.first;
    studied.sort((a, b) => a.lastStudied!.compareTo(b.lastStudied!));
    return studied.first;
  }

  @override
  Widget build(BuildContext context) {
    final attention = _needsAttention;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Study Tracker'),
        actions: [
          IconButton(
            icon: const Icon(Icons.bar_chart),
            tooltip: 'Progress chart',
            onPressed: _subjects.isEmpty
                ? null
                : () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ProgressChartScreen(subjects: _subjects),
                      ),
                    ),
          ),
        ],
      ),
      body: Column(
        children: [
          if (attention != null)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.fromLTRB(12, 12, 12, 0),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.priority_high, color: Colors.deepOrange),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Needs attention: ${attention.name}'
                      '${attention.lastStudied == null ? " (never studied)" : ""}',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: _subjects.isEmpty
                ? const Center(
                    child: Text(
                      'No subjects yet.\nTap + to add one.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: _subjects.length,
                    itemBuilder: (ctx, i) {
                      final s = _subjects[i];
                      final isAttention = s == attention;
                      return Card(
                        color: isAttention
                            ? Colors.orange.shade50
                            : null,
                        child: ListTile(
                          onTap: () => _onSubjectTap(s),
                          onLongPress: () => _showHistory(s),
                          leading: CircleAvatar(
                            child: Text(
                              s.progressLabel,
                              style: const TextStyle(fontSize: 11),
                            ),
                          ),
                          title: Text(
                            s.name,
                            style: TextStyle(
                              fontWeight: isAttention
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 6),
                              LinearProgressIndicator(
                                value: s.progress / 100,
                                minHeight: 6,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                s.lastStudied == null
                                    ? 'Never studied'
                                    : 'Last: ${_formatDateTime(s.lastStudied!)}',
                                style: const TextStyle(fontSize: 12),
                              ),
                            ],
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.history),
                            tooltip: 'History',
                            onPressed: () => _showHistory(s),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addSubject,
        child: const Icon(Icons.add),
      ),
    );
  }
}

// ---------------- Progress Chart Screen ----------------
class ProgressChartScreen extends StatelessWidget {
  final List<Subject> subjects;
  const ProgressChartScreen({super.key, required this.subjects});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Progress Chart')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Progress per subject',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            Expanded(
              child: subjects.isEmpty
                  ? const Center(child: Text('No data'))
                  : CustomPaint(
                      painter: BarChartPainter(subjects),
                      size: Size.infinite,
                    ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 12,
              runSpacing: 4,
              children: subjects
                  .map(
                    (s) => Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          color: _colorFor(s.name),
                        ),
                        const SizedBox(width: 4),
                        Text('${s.name} (${s.progressLabel})'),
                      ],
                    ),
                  )
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }

  static Color _colorFor(String name) {
    final hue = name.hashCode % 360;
    return HSLColor.fromAHSL(1, hue.toDouble(), 0.65, 0.5).toColor();
  }
}

// Simple custom bar chart painter (no external packages needed)
class BarChartPainter extends CustomPainter {
  final List<Subject> subjects;
  BarChartPainter(this.subjects);

  @override
  void paint(Canvas canvas, Size size) {
    if (subjects.isEmpty) return;

    const double bottomPad = 40; // room for labels
    const double topPad = 20;
    const double barGap = 12;
    final double chartH = size.height - bottomPad - topPad;
    final double barW =
        (size.width - barGap * (subjects.length + 1)) / subjects.length;

    // Gridlines at 0,25,50,75,100
    final gridPaint = Paint()
      ..color = Colors.grey.shade300
      ..strokeWidth = 1;
    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    for (int g = 0; g <= 4; g++) {
      final y = topPad + chartH - (chartH * g / 4);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
      textPainter.text = TextSpan(
        text: '${g * 25}',
        style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(2, y - textPainter.height));
    }

    for (int i = 0; i < subjects.length; i++) {
      final s = subjects[i];
      final h = chartH * (s.progress / 100);
      final x = barGap + i * (barW + barGap);
      final y = topPad + chartH - h;

      final barPaint = Paint()
        ..color = ProgressChartScreen._colorFor(s.name)
        ..style = PaintingStyle.fill;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, y, barW, h),
          const Radius.circular(6),
        ),
        barPaint,
      );

      // Value on top of bar (1 decimal, e.g. 0.1)
      final label = s.progress.toStringAsFixed(1);
      textPainter.text = TextSpan(
        text: label,
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
      );
      textPainter.layout();
      if (h > textPainter.height + 4) {
        textPainter.paint(
            canvas, Offset(x + barW / 2 - textPainter.width / 2, y + 3));
      } else {
        textPainter.paint(
            canvas, Offset(x + barW / 2 - textPainter.width / 2, y - 14));
      }

      // Label under bar (truncated)
      final nameLabel =
          s.name.length > 8 ? '${s.name.substring(0, 8)}…' : s.name;
      textPainter.text = TextSpan(
        text: nameLabel,
        style: TextStyle(fontSize: 10, color: Colors.grey.shade700),
      );
      textPainter.layout();
      textPainter.paint(
          canvas, Offset(x + barW / 2 - textPainter.width / 2, topPad + chartH + 6));
    }
  }

  @override
  bool shouldRepaint(covariant BarChartPainter oldDelegate) =>
      oldDelegate.subjects != subjects;
}

