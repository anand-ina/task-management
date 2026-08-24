import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../core/localization/app_strings.dart';
import '../../../shared_widgets/app_bar/custom_app_bar.dart';
import '../../../shared_widgets/dialogs/exit_confirmation_dialog.dart';
import '../../../shared_widgets/drawer/custom_left_drawer.dart';
import '../bloc/todos_bloc.dart';
import '../bloc/todos_event.dart';
import '../bloc/todos_state.dart';
import '../models/today_todo_model.dart';

class TodayScreen extends StatefulWidget {
  const TodayScreen({super.key});

  @override
  State<TodayScreen> createState() => _TodayScreenState();
}

class _TodayScreenState extends State<TodayScreen> {
  final TextEditingController _todoController = TextEditingController();

  @override
  void dispose() {
    _todoController.dispose();
    super.dispose();
  }

  void _onAddTodo(BuildContext context) {
    final text = _todoController.text.trim();
    if (text.isEmpty) return;
    context.read<TodosBloc>().add(AddTodayTodoEvent(text: text));
    _todoController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final formattedTodayDate = DateFormat('EEEE, d MMMM yyyy').format(DateTime.now());

    return BlocProvider(
      create: (context) => TodosBloc()..add(FetchTodayTodosEvent()),
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) async {
          if (didPop) return;
          final shouldExit = await ExitConfirmationDialog.show(context);
          if (shouldExit) {
            // Handled inside exit dialog
          }
        },
        child: Scaffold(
          drawer: const CustomLeftDrawer(currentRoute: '/todo'),
          appBar: const CustomAppBar(),
          body: BlocBuilder<TodosBloc, TodosState>(
            builder: (context, state) {
              return RefreshIndicator(
                onRefresh: () async {
                  context.read<TodosBloc>().add(FetchTodayTodosEvent());
                },
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Title & Subtitle
                      Text(
                        'To-Do · Today',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Your personal checklist for $formattedTodayDate',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.white60 : Colors.black54,
                        ),
                      ),
                      const SizedBox(height: 16),

                      if (state is TodosLoadingState)
                        const Padding(
                          padding: EdgeInsets.all(60),
                          child: Center(child: CircularProgressIndicator(color: Color(0xFF0F172A))),
                        )
                      else if (state is TodosErrorState)
                        Center(
                          child: Column(
                            children: [
                              Text(state.message, style: const TextStyle(color: Colors.red)),
                              const SizedBox(height: 12),
                              ElevatedButton(
                                onPressed: () => context.read<TodosBloc>().add(FetchTodayTodosEvent()),
                                child: Text(s.retryButton),
                              ),
                            ],
                          ),
                        )
                      else if (state is TodayTodosLoadedState) ...[
                        // Badges Pill Summary Row matching Image 2 mockup
                        Row(
                          children: [
                            _buildPillBadge(
                              '${state.data.openCount} open',
                              isDark ? const Color(0xFF451A1A) : const Color(0xFFFEE2E2),
                              isDark ? const Color(0xFFFCA5A5) : const Color(0xFF991B1B),
                            ),
                            const SizedBox(width: 8),
                            _buildPillBadge(
                              '${state.data.doneCount} done',
                              isDark ? const Color(0xFF14532D) : const Color(0xFFDCFCE7),
                              isDark ? const Color(0xFF86EFAC) : const Color(0xFF166534),
                            ),
                            const SizedBox(width: 8),
                            _buildPillBadge(
                              '${state.data.carriedCount} carried forward',
                              isDark ? const Color(0xFF422006) : const Color(0xFFFEF3C7),
                              isDark ? const Color(0xFFFDE68A) : const Color(0xFF92400E),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Main To-Do Card Box matching Image 2 mockup
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF1E293B) : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Input Field Row (Add a to-do for today... + Add button)
                              Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: _todoController,
                                      style: const TextStyle(fontSize: 12),
                                      decoration: InputDecoration(
                                        hintText: 'Add a to-do for today...',
                                        hintStyle: const TextStyle(fontSize: 12, color: Colors.grey),
                                        isDense: true,
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                        filled: true,
                                        fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(8),
                                          borderSide: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                                        ),
                                      ),
                                      onSubmitted: (_) => _onAddTodo(context),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF0F172A),
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                                    ),
                                    onPressed: () => _onAddTodo(context),
                                    child: const Text('Add', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),

                              // CARRIED FORWARD Section
                              if (state.data.carriedItems.isNotEmpty) ...[
                                Text(
                                  'CARRIED FORWARD',
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5,
                                    color: isDark ? const Color(0xFFFDE68A) : const Color(0xFFD97706),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                const Divider(height: 1),
                                const SizedBox(height: 8),
                                Column(
                                  children: state.data.carriedItems
                                      .map((item) => _buildTodoItemRow(context, item, isCarried: true))
                                      .toList(),
                                ),
                                const SizedBox(height: 16),
                              ],

                              // TODAY Section
                              Text(
                                'TODAY',
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                  color: isDark ? Colors.white60 : Colors.black54,
                                ),
                              ),
                              const SizedBox(height: 8),
                              if (state.data.todayItems.isEmpty)
                                const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 20),
                                  child: Center(
                                    child: Text(
                                      'No new items for today yet.',
                                      style: TextStyle(fontSize: 12, color: Colors.grey),
                                    ),
                                  ),
                                )
                              else
                                Column(
                                  children: state.data.todayItems
                                      .map((item) => _buildTodoItemRow(context, item, isCarried: false))
                                      .toList(),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Footer Note matching Image 2 mockup
                        Text(
                          'Unfinished items roll over to the next day automatically until you tick them off. Every day is kept in History.',
                          style: TextStyle(fontSize: 11, color: isDark ? Colors.white60 : Colors.black54),
                        ),
                      ] else
                        const SizedBox.shrink(),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildPillBadge(String label, Color bg, Color text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: text),
      ),
    );
  }

  Widget _buildTodoItemRow(BuildContext context, TodayTodoItemModel item, {required bool isCarried}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Checkbox(
            value: item.done,
            onChanged: (val) {
              if (val != null) {
                context.read<TodosBloc>().add(ToggleTodoEvent(id: item.id, done: val));
              }
            },
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
            activeColor: const Color(0xFF0F172A),
          ),
          Expanded(
            child: Text(
              item.text,
              style: TextStyle(
                fontSize: 12,
                decoration: item.done ? TextDecoration.lineThrough : null,
                color: item.done
                    ? (isDark ? Colors.white38 : Colors.grey)
                    : (isDark ? Colors.white : const Color(0xFF0F172A)),
              ),
            ),
          ),
          if (isCarried) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF422006) : const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '⇆ carried · ${item.ageDays == 1 ? "yesterday" : "${item.ageDays} days ago"}',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: isDark ? const Color(0xFFFDE68A) : const Color(0xFF92400E),
                ),
              ),
            ),
          ],
          IconButton(
            icon: const Icon(Icons.close_rounded, size: 16, color: Colors.grey),
            onPressed: () {
              context.read<TodosBloc>().add(DeleteTodoEvent(id: item.id));
            },
          ),
        ],
      ),
    );
  }
}
