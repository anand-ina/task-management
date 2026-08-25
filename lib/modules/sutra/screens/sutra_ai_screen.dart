import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../../../core/localization/app_strings.dart';
import '../../../shared_widgets/app_bar/custom_app_bar.dart';
import '../../../shared_widgets/drawer/custom_left_drawer.dart';
import '../../../shared_widgets/dialogs/exit_confirmation_dialog.dart';
import '../bloc/sutra_bloc.dart';
import '../bloc/sutra_event.dart';
import '../bloc/sutra_state.dart';
import '../repository/sutra_repository.dart';

class SutraAiScreen extends StatefulWidget {
  const SutraAiScreen({super.key});

  @override
  State<SutraAiScreen> createState() => _SutraAiScreenState();
}

class _SutraAiScreenState extends State<SutraAiScreen> {
  int _selectedTabIndex = 0; // 0 = Needs Human, 1 = Activity Feed, 2 = Compose, 3 = Active Tasks
  final TextEditingController _askSutraController = TextEditingController();
  final TextEditingController _composeController = TextEditingController();
  final SutraRepository _sutraRepository = SutraRepository();
  String? _interpretResultMessage;
  bool _isInterpreting = false;

  late stt.SpeechToText _speech;
  bool _isListening = false;
  bool _speechEnabled = false;

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _initSpeech();
  }

  void _initSpeech() async {
    try {
      _speechEnabled = await _speech.initialize(
        onError: (val) {
          if (mounted) setState(() => _isListening = false);
        },
        onStatus: (val) {
          if (val == 'done' || val == 'notListening') {
            if (mounted) setState(() => _isListening = false);
          }
        },
      );
    } catch (_) {
      _speechEnabled = false;
    }
  }

  void _toggleListening() async {
    if (_isListening) {
      setState(() => _isListening = false);
      await _speech.stop();
      return;
    }

    if (!_speechEnabled) {
      try {
        _speechEnabled = await _speech.initialize(
          onError: (val) {
            if (mounted) setState(() => _isListening = false);
          },
          onStatus: (val) {
            if (val == 'done' || val == 'notListening') {
              if (mounted) setState(() => _isListening = false);
            }
          },
        );
      } catch (_) {
        _speechEnabled = false;
      }
    }

    if (_speechEnabled) {
      setState(() => _isListening = true);
      await _speech.listen(
        onResult: (result) {
          if (mounted) {
            setState(() {
              _askSutraController.text = result.recognizedWords;
              _askSutraController.selection = TextSelection.fromPosition(
                TextPosition(offset: _askSutraController.text.length),
              );
            });
          }
        },
      );
    } else {
      _showDictationFallbackDialog();
    }
  }

  void _showDictationFallbackDialog() {
    final controller = TextEditingController(text: _askSutraController.text);
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: Row(
            children: const [
              Icon(Icons.mic_rounded, color: Colors.red),
              SizedBox(width: 8),
              Text('Voice Dictation', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Enter or dictate your command for Sutra AI:',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                maxLines: 3,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'e.g. Show pending tasks for my team...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0F172A),
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                if (mounted) {
                  setState(() {
                    _askSutraController.text = controller.text;
                    _askSutraController.selection = TextSelection.fromPosition(
                      TextPosition(offset: _askSutraController.text.length),
                    );
                  });
                }
                Navigator.of(ctx).pop();
              },
              child: const Text('Insert Text'),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _askSutraController.dispose();
    _composeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldExit = await ExitConfirmationDialog.show(context);
        if (shouldExit) {
          // Handled inside exit dialog
        }
      },
      child: BlocProvider(
        create: (_) => SutraBloc()..add(LoadSutraDataEvent()),
        child: Scaffold(
          appBar: const CustomAppBar(),
          drawer: const CustomLeftDrawer(currentRoute: '/sutra'),
          body: BlocBuilder<SutraBloc, SutraState>(
            builder: (context, state) {
              if (state is SutraLoadingState) {
                return const Center(child: CircularProgressIndicator());
              }
              if (state is SutraErrorState) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(state.message, style: const TextStyle(color: Colors.red)),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: () => context.read<SutraBloc>().add(LoadSutraDataEvent()),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                );
              }
              if (state is SutraLoadedState) {
                final stats = state.data.dashboardData.stats;
                final pendingCount = stats.toBeStarted + stats.inProgress;
                final emergencyCount = stats.emergency;
                final completedCount = stats.completed;

                return SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Title & Command Centre Badge
                      Row(
                        children: [
                          Text(
                            '✦ ${s.sutraTitle}',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              s.sutraBadge,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        s.sutraSubtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.grey[400] : const Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Red Bordered Ask Sutra Section (Command Box)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E293B) : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFEF4444), width: 1.5),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withAlpha(isDark ? 50 : 10),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              s.askSutraHeader,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                                color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _askSutraController,
                              maxLines: 2,
                              style: TextStyle(
                                fontSize: 13,
                                color: isDark ? Colors.white : const Color(0xFF0F172A),
                              ),
                              decoration: InputDecoration(
                                hintText: s.askSutraPlaceholder,
                                hintStyle: TextStyle(
                                  fontSize: 12,
                                  color: isDark ? Colors.grey[500] : const Color(0xFF94A3B8),
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(
                                    color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                                  ),
                                ),
                                contentPadding: const EdgeInsets.all(12),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                IconButton(
                                  onPressed: _toggleListening,
                                  icon: Icon(
                                    _isListening ? Icons.mic_rounded : Icons.mic_none_rounded,
                                    color: _isListening ? Colors.red : (isDark ? Colors.grey[400] : const Color(0xFF64748B)),
                                  ),
                                  tooltip: _isListening ? 'Listening... Tap to stop' : 'Record voice to text',
                                ),
                                const SizedBox(width: 8),
                                ElevatedButton(
                                  onPressed: _isInterpreting
                                      ? null
                                      : () async {
                                          if (_askSutraController.text.trim().isEmpty) return;
                                          setState(() => _isInterpreting = true);
                                          final res = await _sutraRepository.sendSutraCommand(_askSutraController.text);
                                          if (mounted) {
                                            setState(() {
                                              _isInterpreting = false;
                                              _interpretResultMessage = res['message']?.toString();
                                            });
                                          }
                                        },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF0F172A),
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                  ),
                                  child: _isInterpreting
                                      ? const SizedBox(
                                          width: 14,
                                          height: 14,
                                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                        )
                                      : Text(s.interpretButton, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                ),
                              ],
                            ),
                            if (_interpretResultMessage != null && _interpretResultMessage!.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  _interpretResultMessage!,
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    color: isDark ? Colors.white70 : const Color(0xFF334155),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Status Chips Row
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _buildStatusChip('${s.pendingBadge}$pendingCount', const Color(0xFFFEF08A), const Color(0xFF854D0E)),
                          _buildStatusChip('${s.emergencyBadge}$emergencyCount', const Color(0xFFFEE2E2), const Color(0xFF991B1B)),
                          _buildStatusChip('${s.completedBadge}$completedCount', const Color(0xFFDCFCE7), const Color(0xFF166534)),
                          _buildStatusChip('${s.needsHumanBadge}3', const Color(0xFFE0E7FF), const Color(0xFF3730A3)),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // 4 Segmented Navigation Tabs
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _buildTabItem(s.needsHumanTab, 0, isDark),
                            _buildTabItem(s.activityFeedTab, 1, isDark),
                            _buildTabItem(s.composeTab, 2, isDark),
                            _buildTabItem(s.activeTasksTab, 3, isDark),
                          ],
                        ),
                      ),
                      const Divider(height: 1),
                      const SizedBox(height: 16),

                      // Tab View Body
                      if (_selectedTabIndex == 0)
                        _buildNeedsHumanView(context, s, isDark)
                      else if (_selectedTabIndex == 1)
                        _buildActivityFeedView(context, s, isDark)
                      else if (_selectedTabIndex == 2)
                        _buildComposeView(context, s, isDark)
                      else if (_selectedTabIndex == 3)
                        _buildActiveTasksView(context, s, state.data.activeTasks, isDark),

                      const SizedBox(height: 40),
                    ],
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(String label, Color bgColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
      ),
    );
  }

  Widget _buildTabItem(String label, int index, bool isDark) {
    final isSelected = _selectedTabIndex == index;
    return InkWell(
      onTap: () => setState(() => _selectedTabIndex = index),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isSelected ? const Color(0xFFEF4444) : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected
                ? (isDark ? Colors.white : const Color(0xFF0F172A))
                : (isDark ? Colors.grey[400] : const Color(0xFF64748B)),
          ),
        ),
      ),
    );
  }

  // TAB 1: Needs Human View
  Widget _buildNeedsHumanView(BuildContext context, AppStrings s, bool isDark) {
    final items = [
      {
        'title': "Draft task: 'Renew fire-safety certificate'",
        'desc': 'Certificate expires in 14 days. Approve to assign to Admin.',
        'priority': 'Top Most',
        'pColor': const Color(0xFFFEF08A),
        'pTextColor': const Color(0xFF854D0E),
        'tag': 'AI-drafted · needs approval',
        'btn': s.approveButton,
      },
      {
        'title': 'Ambiguous enquiry — assign owner?',
        'desc': "Parent enquiry couldn't be auto-routed to a counsellor.",
        'priority': 'Medium',
        'pColor': const Color(0xFFDBEAFE),
        'pTextColor': const Color(0xFF1E40AF),
        'tag': 'AI needs input',
        'btn': s.assignButton,
      },
      {
        'title': 'Duplicate task detected across branches',
        'desc': 'Two similar "uniform vendor" tasks — merge or keep both?',
        'priority': 'High',
        'pColor': const Color(0xFFFEF08A),
        'pTextColor': const Color(0xFF854D0E),
        'tag': 'AI suggests merge',
        'btn': s.reviewButton,
      },
    ];

    return Column(
      children: items.map((item) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item['title'] as String,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item['desc'] as String,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.grey[400] : const Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: item['pColor'] as Color,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            item['priority'] as String,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: item['pTextColor'] as Color,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            item['tag'] as String,
                            style: TextStyle(
                              fontSize: 10,
                              color: isDark ? Colors.grey[300] : const Color(0xFF475569),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0F172A),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
                child: Text(item['btn'] as String, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // TAB 2: Activity Feed View
  Widget _buildActivityFeedView(BuildContext context, AppStrings s, bool isDark) {
    final activities = [
      {'time': '2:41 PM', 'text': 'Auto-closed 3 recurring cash-reconciliation tasks after receipts matched.', 'color': Colors.green},
      {'time': '1:10 PM', 'text': 'Flagged an overdue task & nudged the assignee on WhatsApp.', 'color': Colors.orange},
      {'time': '9:05 AM', 'text': "Drafted 4 tasks from last night's Principal email. 1 needs approval.", 'color': Colors.blue},
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: activities.map((act) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: act['color'] as Color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  act['time'] as String,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.grey[300] : const Color(0xFF334155),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    act['text'] as String,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.grey[400] : const Color(0xFF64748B),
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  // TAB 3: Compose View
  Widget _buildComposeView(BuildContext context, AppStrings s, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            s.composeHeader,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
              color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _composeController,
            maxLines: 4,
            style: TextStyle(fontSize: 13, color: isDark ? Colors.white : const Color(0xFF0F172A)),
            decoration: InputDecoration(
              hintText: s.composePlaceholder,
              hintStyle: TextStyle(fontSize: 12, color: isDark ? Colors.grey[500] : const Color(0xFF94A3B8)),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
              ),
              contentPadding: const EdgeInsets.all(12),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ActionChip(
                label: Text(s.suggestPriorityChip, style: const TextStyle(fontSize: 11)),
                onPressed: () {},
              ),
              ActionChip(
                label: Text(s.pickAssigneeChip, style: const TextStyle(fontSize: 11)),
                onPressed: () {},
              ),
              ActionChip(
                label: Text(s.setDueDateChip, style: const TextStyle(fontSize: 11)),
                onPressed: () {},
              ),
            ],
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0F172A),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            child: Text(s.createTaskButton, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // TAB 4: Active Tasks View
  Widget _buildActiveTasksView(BuildContext context, AppStrings s, List activeTasks, bool isDark) {
    if (activeTasks.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(30),
          child: Text('No active in-progress tasks', style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[600], fontSize: 13)),
        ),
      );
    }

    return Column(
      children: activeTasks.map((t) {
        final priority = (t.priority ?? 'medium').toString();
        Color pColor = const Color(0xFFDBEAFE);
        Color pText = const Color(0xFF1E40AF);
        if (priority.toLowerCase() == 'high') {
          pColor = const Color(0xFFFEF08A);
          pText = const Color(0xFF854D0E);
        } else if (priority.toLowerCase() == 'top_most' || priority.toLowerCase() == 'top most') {
          pColor = const Color(0xFFFEE2E2);
          pText = const Color(0xFF991B1B);
        }

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
          ),
          child: Row(
            children: [
              Text(
                t.taskNo.isNotEmpty ? t.taskNo : '#${t.id}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  t.title,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.grey[300] : const Color(0xFF334155),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: pColor,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  priority.toUpperCase(),
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: pText),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '• In Progress · ${t.progress}%',
                style: const TextStyle(fontSize: 11, color: Colors.blue, fontWeight: FontWeight.w600),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  s.trackingBadge,
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF166534)),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
