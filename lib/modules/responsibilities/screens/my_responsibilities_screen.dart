import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/localization/app_strings.dart';
import '../../../shared_widgets/floating_action_button/todo_floating_action_button.dart';
import '../../../shared_widgets/app_bar/custom_app_bar.dart';
import '../../../shared_widgets/dialogs/exit_confirmation_dialog.dart';
import '../../../shared_widgets/drawer/custom_left_drawer.dart';
import '../bloc/responsibilities_bloc.dart';
import '../bloc/responsibilities_event.dart';
import '../bloc/responsibilities_state.dart';
import '../models/responsibility_model.dart';

class MyResponsibilitiesScreen extends StatefulWidget {
  const MyResponsibilitiesScreen({super.key});

  @override
  State<MyResponsibilitiesScreen> createState() => _MyResponsibilitiesScreenState();
}

class _MyResponsibilitiesScreenState extends State<MyResponsibilitiesScreen> {
  final TextEditingController _primaryController = TextEditingController();
  final TextEditingController _secondaryController = TextEditingController();

  @override
  void dispose() {
    _primaryController.dispose();
    _secondaryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ResponsibilitiesBloc()..add(FetchResponsibilitiesEvent()),
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) async {
          if (!didPop) await ExitConfirmationDialog.show(context);
        },
        child: Scaffold(
          floatingActionButton: const TodoFloatingActionButton(),
          drawer: const CustomLeftDrawer(currentRoute: '/responsibilities'),
          appBar: const CustomAppBar(),
          body: _ResponsibilitiesContent(
            primaryController: _primaryController,
            secondaryController: _secondaryController,
          ),
        ),
      ),
    );
  }
}

class _ResponsibilitiesContent extends StatelessWidget {
  final TextEditingController primaryController;
  final TextEditingController secondaryController;

  const _ResponsibilitiesContent({
    required this.primaryController,
    required this.secondaryController,
  });

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocBuilder<ResponsibilitiesBloc, ResponsibilitiesState>(
      builder: (context, state) {
        return RefreshIndicator(
          onRefresh: () async =>
              context.read<ResponsibilitiesBloc>().add(FetchResponsibilitiesEvent()),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title & Subtitle
                Text(
                  s.myResponsibilities,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  s.myResponsibilitiesSubtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.white54 : const Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 20),

                if (state is ResponsibilitiesLoadingState)
                  const Padding(
                    padding: EdgeInsets.all(60),
                    child: Center(
                      child: CircularProgressIndicator(color: Color(0xFF0F172A)),
                    ),
                  )
                else if (state is ResponsibilitiesErrorState)
                  Center(
                    child: Column(
                      children: [
                        Text(state.message, style: const TextStyle(color: Colors.red)),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: () => context
                              .read<ResponsibilitiesBloc>()
                              .add(FetchResponsibilitiesEvent()),
                          child: Text(s.retryButton),
                        ),
                      ],
                    ),
                  )
                else if (state is ResponsibilitiesLoadedState) ...[
                  // Person Card
                  if (state.data.person != null) ...[
                    _buildPersonHeaderCard(state.data.person!, isDark),
                    const SizedBox(height: 24),
                  ],

                  // Responsibilities Columns
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isWide = constraints.maxWidth > 800;
                      final primaryBox = _buildCategoryCard(
                        context,
                        title: s.primaryResponsibilitiesTitle,
                        indicatorColor: const Color(0xFF16A34A),
                        items: state.data.primary,
                        kind: 'primary',
                        inputController: primaryController,
                        hintText: s.addPrimaryResponsibilityPlaceholder,
                        s: s,
                        isDark: isDark,
                      );

                      final secondaryBox = _buildCategoryCard(
                        context,
                        title: s.secondaryResponsibilitiesTitle,
                        indicatorColor: const Color(0xFFEA580C),
                        items: state.data.secondary,
                        kind: 'secondary',
                        inputController: secondaryController,
                        hintText: s.addSecondaryResponsibilityPlaceholder,
                        s: s,
                        isDark: isDark,
                      );

                      if (isWide) {
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: primaryBox),
                            const SizedBox(width: 20),
                            Expanded(child: secondaryBox),
                          ],
                        );
                      } else {
                        return Column(
                          children: [
                            primaryBox,
                            const SizedBox(height: 20),
                            secondaryBox,
                          ],
                        );
                      }
                    },
                  ),
                ],

                const SizedBox(height: 40),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPersonHeaderCard(ResponsibilityPersonModel person, bool isDark) {
    final subtitle = [
      person.designation,
      person.department,
      person.branchName,
    ].where((e) => e.isNotEmpty).join(' · ');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: _hexToColor(person.avatarColor),
            child: Text(
              person.initials,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  person.name,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? Colors.white54 : const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryCard(
    BuildContext context, {
    required String title,
    required Color indicatorColor,
    required List<ResponsibilityItemModel> items,
    required String kind,
    required TextEditingController inputController,
    required String hintText,
    required AppStrings s,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: indicatorColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${items.length}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white70 : const Color(0xFF64748B),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Items List
          if (items.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  s.noneYetText,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.white38 : Colors.grey.shade400,
                  ),
                ),
              ),
            )
          else
            Column(
              children: items.map((item) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF0F172A) : Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.text,
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                        ),
                      ),
                      InkWell(
                        onTap: () {
                          context.read<ResponsibilitiesBloc>().add(
                                DeleteResponsibilityEvent(id: item.id, kind: kind),
                              );
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.all(4),
                          child: Icon(
                            Icons.close_rounded,
                            size: 16,
                            color: isDark ? Colors.white38 : Colors.grey.shade400,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),

          const SizedBox(height: 12),

          // Add Input Row
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 38,
                  child: TextField(
                    controller: inputController,
                    style: const TextStyle(fontSize: 12),
                    decoration: InputDecoration(
                      hintText: hintText,
                      hintStyle: TextStyle(
                        fontSize: 11,
                        color: isDark ? Colors.white38 : Colors.grey.shade400,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      isDense: true,
                      filled: true,
                      fillColor: isDark ? const Color(0xFF0F172A) : Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                height: 38,
                child: ElevatedButton(
                  onPressed: () {
                    final text = inputController.text.trim();
                    if (text.isNotEmpty) {
                      context.read<ResponsibilitiesBloc>().add(
                            AddResponsibilityEvent(kind: kind, text: text),
                          );
                      inputController.clear();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0F172A),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    s.addButton,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _hexToColor(String? hex) {
    if (hex == null || hex.trim().isEmpty) return const Color(0xFF132A50);
    try {
      String h = hex.replaceAll('#', '').replaceAll('0x', '').trim();
      if (h.length == 6) h = 'FF$h';
      return Color(int.parse(h, radix: 16));
    } catch (_) {
      return const Color(0xFF132A50);
    }
  }
}
