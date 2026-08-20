import 'package:flutter/material.dart';
import '../../../core/localization/app_strings.dart';
import '../../../shared_widgets/app_bar/custom_app_bar.dart';
import '../../../shared_widgets/drawer/custom_left_drawer.dart';
import '../../../shared_widgets/dialogs/exit_confirmation_dialog.dart';

class FaqScreen extends StatefulWidget {
  const FaqScreen({super.key});

  @override
  State<FaqScreen> createState() => _FaqScreenState();
}

class _FaqScreenState extends State<FaqScreen> {
  final Set<int> _expandedIndices = {0}; // First open by default

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final faqs = [
      {'q': s.faqQ1, 'a': s.faqA1},
      {'q': s.faqQ2, 'a': s.faqA2},
      {'q': s.faqQ3, 'a': s.faqA3},
      {'q': s.faqQ4, 'a': s.faqA4},
      {'q': s.faqQ5, 'a': s.faqA5},
    ];

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldExit = await ExitConfirmationDialog.show(context);
        if (shouldExit) {
          // Handled inside exit dialog
        }
      },
      child: Scaffold(
        appBar: const CustomAppBar(),
        drawer: const CustomLeftDrawer(currentRoute: '/faq'),
        body: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Title & Subtitle
              Row(
                children: [
                  Icon(Icons.help_outline_rounded, size: 24, color: isDark ? Colors.white : const Color(0xFF0F172A)),
                  const SizedBox(width: 8),
                  Text(
                    s.faqTitle,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                s.faqSubtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.grey[400] : const Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 20),

              // FAQ Expandable List
              Column(
                children: List.generate(faqs.length, (index) {
                  final isExpanded = _expandedIndices.contains(index);
                  final item = faqs[index];

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                    ),
                    child: Theme(
                      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                      child: ExpansionTile(
                        initiallyExpanded: isExpanded,
                        onExpansionChanged: (expanded) {
                          setState(() {
                            if (expanded) {
                              _expandedIndices.add(index);
                            } else {
                              _expandedIndices.remove(index);
                            }
                          });
                        },
                        title: Text(
                          item['q']!,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                        ),
                        trailing: Icon(
                          isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                          color: isDark ? Colors.grey[400] : const Color(0xFF64748B),
                        ),
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                item['a']!,
                                style: TextStyle(
                                  fontSize: 13,
                                  height: 1.5,
                                  color: isDark ? Colors.grey[300] : const Color(0xFF334155),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
