import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/localization/app_strings.dart';
import '../../../shared_widgets/app_bar/custom_app_bar.dart';
import '../../../shared_widgets/dialogs/exit_confirmation_dialog.dart';
import '../../../shared_widgets/drawer/custom_left_drawer.dart';
import '../bloc/admin_reporting_bloc.dart';
import '../bloc/admin_reporting_event.dart';
import '../bloc/admin_reporting_state.dart';
import '../models/reporting_person_model.dart';
import '../../../shared_widgets/dropdowns/searchable_filter_dropdown.dart';

class AdminReportingStructureScreen extends StatelessWidget {
  const AdminReportingStructureScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AdminReportingBloc()..add(FetchReportingEvent()),
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) async {
          if (!didPop) await ExitConfirmationDialog.show(context);
        },
        child: const Scaffold(
          drawer: CustomLeftDrawer(currentRoute: '/admin/reporting'),
          appBar: CustomAppBar(),
          body: _ReportingBody(),
        ),
      ),
    );
  }
}

class _ReportingBody extends StatefulWidget {
  const _ReportingBody();

  @override
  State<_ReportingBody> createState() => _ReportingBodyState();
}

class _ReportingBodyState extends State<_ReportingBody> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocBuilder<AdminReportingBloc, AdminReportingState>(
      builder: (context, state) {
        return RefreshIndicator(
          onRefresh: () async =>
              context.read<AdminReportingBloc>().add(FetchReportingEvent()),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Text(
                  s.reportingStructure,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  s.reportingStructureSubtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.white54 : const Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 16),

                if (state is AdminReportingLoadingState)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 80),
                    child: Center(
                      child: CircularProgressIndicator(color: Color(0xFF0F172A)),
                    ),
                  )
                else if (state is AdminReportingErrorState)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 40),
                      child: Column(
                        children: [
                          Text(state.message,
                              style: const TextStyle(color: Colors.red)),
                          const SizedBox(height: 12),
                          ElevatedButton(
                            onPressed: () => context
                                .read<AdminReportingBloc>()
                                .add(FetchReportingEvent()),
                            child: Text(s.retryButton),
                          ),
                        ],
                      ),
                    ),
                  )
                else if (state is AdminReportingLoadedState) ...[
                  // Search Bar
                  Container(
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDark
                            ? const Color(0xFF334155)
                            : const Color(0xFFE2E8F0),
                      ),
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (val) {
                        setState(() {
                          _searchQuery = val.trim().toLowerCase();
                        });
                      },
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                      decoration: InputDecoration(
                        hintText: s.searchStaffPlaceholder,
                        hintStyle: TextStyle(
                          fontSize: 13,
                          color: isDark ? Colors.white38 : Colors.grey.shade400,
                        ),
                        prefixIcon: Icon(
                          Icons.search_rounded,
                          size: 20,
                          color: isDark ? Colors.white54 : Colors.grey.shade500,
                        ),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear_rounded, size: 18),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() {
                                    _searchQuery = '';
                                  });
                                },
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  _buildContainerList(context, s, state.people, isDark),
                ] else
                  const SizedBox.shrink(),

                const SizedBox(height: 40),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildContainerList(
    BuildContext context,
    AppStrings s,
    List<ReportingPersonModel> people,
    bool isDark,
  ) {
    if (people.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 40),
          child: Text(
            s.noReportingDataFound,
            style: TextStyle(
              color: isDark ? Colors.white54 : Colors.grey.shade500,
            ),
          ),
        ),
      );
    }

    // Filter people by search query
    final filtered = _searchQuery.isEmpty
        ? people
        : people.where((p) {
            return p.name.toLowerCase().contains(_searchQuery) ||
                p.levelLabel.toLowerCase().contains(_searchQuery);
          }).toList();

    if (filtered.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 40),
          child: Column(
            children: [
              Icon(Icons.search_off_rounded,
                  size: 40,
                  color: isDark ? Colors.white38 : Colors.grey.shade400),
              const SizedBox(height: 8),
              Text(
                s.noReportingDataFound,
                style: TextStyle(
                  color: isDark ? Colors.white54 : Colors.grey.shade500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Build lookup map
    final Map<int, ReportingPersonModel> lookup = {
      for (final p in people) p.id: p
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Counter row
        Padding(
          padding: const EdgeInsets.only(left: 2, bottom: 10),
          child: Text(
            '${filtered.length} staff member${filtered.length == 1 ? '' : 's'}',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white54 : const Color(0xFF64748B),
            ),
          ),
        ),

        // Container List of Person Cards
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: filtered.length,
          itemBuilder: (context, index) {
            final person = filtered[index];
            final primaryManagers = person.primary
                .map((id) => lookup[id])
                .whereType<ReportingPersonModel>()
                .toList();
            final secondaryManagers = person.secondary
                .map((id) => lookup[id])
                .whereType<ReportingPersonModel>()
                .toList();

            return _PersonReportingCard(
              person: person,
              allPeople: people,
              primaryManagers: primaryManagers,
              secondaryManagers: secondaryManagers,
              isDark: isDark,
              s: s,
            );
          },
        ),
      ],
    );
  }
}

class _PersonReportingCard extends StatelessWidget {
  const _PersonReportingCard({
    required this.person,
    required this.allPeople,
    required this.primaryManagers,
    required this.secondaryManagers,
    required this.isDark,
    required this.s,
  });

  final ReportingPersonModel person;
  final List<ReportingPersonModel> allPeople;
  final List<ReportingPersonModel> primaryManagers;
  final List<ReportingPersonModel> secondaryManagers;
  final bool isDark;
  final AppStrings s;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Avatar + Name & Level + Save Button
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: _hexToColor(person.avatarColor),
                child: Text(
                  person.initials,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      person.name,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF334155)
                            : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        person.levelLabel,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? Colors.blue.shade300
                              : const Color(0xFF1E3A8A),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Save Button
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0F172A),
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 0,
                ),
                icon: const Icon(Icons.check_rounded, size: 14),
                label: Text(
                  s.saveButton,
                  style: const TextStyle(
                      fontSize: 11, fontWeight: FontWeight.bold),
                ),
                onPressed: () {
                  context
                      .read<AdminReportingBloc>()
                      .add(SaveReportingEvent(person.id));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content:
                          Text('Reporting structure saved for ${person.name}'),
                      backgroundColor: Colors.green.shade700,
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
              ),
            ],
          ),

          Divider(
            height: 24,
            thickness: 1,
            color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
          ),

          // Primary Managers ("Reports To")
          Row(
            children: [
              Icon(
                Icons.arrow_upward_rounded,
                size: 14,
                color: isDark ? Colors.blue.shade400 : const Color(0xFF2563EB),
              ),
              const SizedBox(width: 6),
              Text(
                s.reportsToColumn,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white70 : const Color(0xFF475569),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '(${primaryManagers.length})',
                style: TextStyle(
                  fontSize: 11,
                  color: isDark ? Colors.white38 : Colors.grey.shade500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildManagersWrap(
            context: context,
            person: person,
            allPeople: allPeople,
            managers: primaryManagers,
            addLabel: s.addManagerLabel,
            isPrimary: true,
            isDark: isDark,
            accentColor: const Color(0xFF2563EB),
            dotted: false,
          ),

          const SizedBox(height: 14),

          // Secondary Managers ("Dotted-Line")
          Row(
            children: [
              Icon(
                Icons.alt_route_rounded,
                size: 14,
                color:
                    isDark ? Colors.amber.shade400 : const Color(0xFFD97706),
              ),
              const SizedBox(width: 6),
              Text(
                s.dottedLineColumn,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white70 : const Color(0xFF475569),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '(${secondaryManagers.length})',
                style: TextStyle(
                  fontSize: 11,
                  color: isDark ? Colors.white38 : Colors.grey.shade500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildManagersWrap(
            context: context,
            person: person,
            allPeople: allPeople,
            managers: secondaryManagers,
            addLabel: s.addDottedLabel,
            isPrimary: false,
            isDark: isDark,
            accentColor: const Color(0xFF64748B),
            dotted: true,
          ),
        ],
      ),
    );
  }

  Widget _buildManagersWrap({
    required BuildContext context,
    required ReportingPersonModel person,
    required List<ReportingPersonModel> allPeople,
    required List<ReportingPersonModel> managers,
    required String addLabel,
    required bool isPrimary,
    required bool isDark,
    required Color accentColor,
    bool dotted = false,
  }) {
    final existingIds = managers.map((m) => m.id).toSet();
    final availablePeople = allPeople
        .where((p) => p.id != person.id && !existingIds.contains(p.id))
        .toList();

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        if (managers.isEmpty && availablePeople.isEmpty)
          Text(
            'None',
            style: TextStyle(
              fontSize: 12,
              fontStyle: FontStyle.italic,
              color: isDark ? Colors.white38 : Colors.grey.shade500,
            ),
          ),
        ...managers.map((m) => _ManagerChip(
              name: m.name,
              initials: m.initials,
              avatarColor: m.avatarColor,
              isDark: isDark,
              accentColor: accentColor,
              dotted: dotted,
              onDelete: () {
                context.read<AdminReportingBloc>().add(
                      RemoveManagerEvent(
                        personId: person.id,
                        managerId: m.id,
                        isPrimary: isPrimary,
                      ),
                    );
              },
            )),
        if (availablePeople.isNotEmpty)
          SearchableFilterDropdown<int?>(
            value: null,
            hint: addLabel,
            searchHint: 'Search manager...',
            maxVisibleCount: 4,
            minPopupWidth: 260,
            items: availablePeople.map((p) {
              return SearchableDropdownItem<int?>(
                value: p.id,
                label: p.name,
                subtitle: p.levelLabel,
                leading: CircleAvatar(
                  radius: 12,
                  backgroundColor: _hexToColor(p.avatarColor),
                  child: Text(
                    p.initials,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              );
            }).toList(),
            onChanged: (selectedManagerId) {
              if (selectedManagerId != null) {
                context.read<AdminReportingBloc>().add(
                      AddManagerEvent(
                        personId: person.id,
                        managerId: selectedManagerId,
                        isPrimary: isPrimary,
                      ),
                    );
              }
            },
            customTrigger: (context, onTap, isOpen) {
              return InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF1E293B)
                        : const Color(0xFFF8FAFC),
                    border: Border.all(
                      color: isOpen
                          ? const Color(0xFF991B1B)
                          : (isDark
                              ? const Color(0xFF475569)
                              : const Color(0xFFCBD5E1)),
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.add_rounded,
                        size: 14,
                        color:
                            isDark ? Colors.white70 : const Color(0xFF475569),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        addLabel,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color:
                              isDark ? Colors.white70 : const Color(0xFF475569),
                        ),
                      ),
                      const SizedBox(width: 2),
                      Icon(
                        isOpen
                            ? Icons.arrow_drop_up_rounded
                            : Icons.arrow_drop_down_rounded,
                        size: 16,
                        color: isDark ? Colors.white54 : Colors.grey.shade600,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
      ],
    );
  }
}

class _ManagerChip extends StatelessWidget {
  const _ManagerChip({
    required this.name,
    required this.initials,
    required this.avatarColor,
    required this.isDark,
    required this.accentColor,
    this.dotted = false,
    this.onDelete,
  });

  final String name;
  final String initials;
  final String avatarColor;
  final bool isDark;
  final Color accentColor;
  final bool dotted;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(left: 4, top: 4, bottom: 4, right: 8),
      decoration: BoxDecoration(
        color: isDark
            ? (dotted
                ? const Color(0xFF334155).withValues(alpha: 0.35)
                : accentColor.withValues(alpha: 0.2))
            : (dotted
                ? const Color(0xFFF1F5F9)
                : accentColor.withValues(alpha: 0.08)),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? (dotted
                  ? const Color(0xFF64748B)
                  : accentColor.withValues(alpha: 0.5))
              : (dotted
                  ? const Color(0xFFCBD5E1)
                  : accentColor.withValues(alpha: 0.3)),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 10,
            backgroundColor: _hexToColor(avatarColor),
            child: Text(
              initials,
              style: const TextStyle(
                fontSize: 8,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 6),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 160),
            child: Text(
              name,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isDark
                    ? (dotted ? Colors.white70 : Colors.white)
                    : (dotted ? const Color(0xFF334155) : accentColor),
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
          const SizedBox(width: 4),
          InkWell(
            onTap: onDelete,
            borderRadius: BorderRadius.circular(10),
            child: Padding(
              padding: const EdgeInsets.all(2),
              child: Icon(
                Icons.close_rounded,
                size: 14,
                color: isDark
                    ? Colors.white60
                    : (dotted
                        ? Colors.grey.shade600
                        : accentColor.withValues(alpha: 0.8)),
              ),
            ),
          ),
        ],
      ),
    );
  }
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
