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
        child: Scaffold(
          drawer: const CustomLeftDrawer(currentRoute: '/admin/reporting'),
          appBar: const CustomAppBar(),
          body: const _ReportingBody(),
        ),
      ),
    );
  }
}

class _ReportingBody extends StatelessWidget {
  const _ReportingBody();

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
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Page header
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
                const SizedBox(height: 20),

                if (state is AdminReportingLoadingState)
                  const Padding(
                    padding: EdgeInsets.all(60),
                    child: Center(child: CircularProgressIndicator(color: Color(0xFF0F172A))),
                  )
                else if (state is AdminReportingErrorState)
                  Center(
                    child: Column(
                      children: [
                        Text(state.message, style: const TextStyle(color: Colors.red)),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: () => context.read<AdminReportingBloc>().add(FetchReportingEvent()),
                          child: Text(s.retryButton),
                        ),
                      ],
                    ),
                  )
                else if (state is AdminReportingLoadedState)
                  _buildTable(context, s, state.people, isDark)
                else
                  const SizedBox.shrink(),

                const SizedBox(height: 40),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTable(BuildContext context, AppStrings s,
      List<ReportingPersonModel> people, bool isDark) {
    if (people.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Text(s.noReportingDataFound,
              style: TextStyle(
                  color: isDark ? Colors.white54 : Colors.grey.shade500)),
        ),
      );
    }

    // Build a lookup map
    final Map<int, ReportingPersonModel> lookup = {
      for (final p in people) p.id: p
    };

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          // Table header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF0F172A)
                  : const Color(0xFFF8FAFC),
              borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12), topRight: Radius.circular(12)),
            ),
            child: Row(
              children: [
                Expanded(
                    flex: 3,
                    child: Text(s.personColumn,
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: isDark
                                ? Colors.white60
                                : const Color(0xFF64748B)))),
                Expanded(
                    flex: 4,
                    child: Text(s.reportsToColumn,
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: isDark
                                ? Colors.white60
                                : const Color(0xFF64748B)))),
                Expanded(
                    flex: 4,
                    child: Text(s.dottedLineColumn,
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: isDark
                                ? Colors.white60
                                : const Color(0xFF64748B)))),
                SizedBox(
                  width: 60,
                  child: Text(
                    'Action',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: isDark
                          ? Colors.white60
                          : const Color(0xFF64748B),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Table rows
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: people.length,
            separatorBuilder: (_, index) => Divider(
                height: 1,
                color: isDark
                    ? const Color(0xFF334155)
                    : const Color(0xFFE2E8F0)),
            itemBuilder: (context, index) {
              final person = people[index];
              final primaryManagers =
                  person.primary.map((id) => lookup[id]).whereType<ReportingPersonModel>().toList();
              final secondaryManagers =
                  person.secondary.map((id) => lookup[id]).whereType<ReportingPersonModel>().toList();

              return _TableRow(
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
      ),
    );
  }
}

class _TableRow extends StatelessWidget {
  const _TableRow({
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Person cell
          Expanded(
            flex: 3,
            child: _PersonCell(person: person, isDark: isDark),
          ),
          // Primary managers cell
          Expanded(
            flex: 4,
            child: _ManagersCell(
              person: person,
              allPeople: allPeople,
              managers: primaryManagers,
              addLabel: s.addManagerLabel,
              isDark: isDark,
              accentColor: const Color(0xFF0F172A),
              isPrimary: true,
            ),
          ),
          // Dotted-line managers cell
          Expanded(
            flex: 4,
            child: _ManagersCell(
              person: person,
              allPeople: allPeople,
              managers: secondaryManagers,
              addLabel: s.addDottedLabel,
              isDark: isDark,
              accentColor: const Color(0xFF475569),
              dotted: true,
              isPrimary: false,
            ),
          ),
          // Action cell (Save button)
          SizedBox(
            width: 60,
            child: Align(
              alignment: Alignment.topCenter,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0F172A),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                  elevation: 0,
                ),
                onPressed: () {
                  context.read<AdminReportingBloc>().add(SaveReportingEvent(person.id));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Reporting structure saved for ${person.name}'),
                      backgroundColor: Colors.green.shade700,
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
                child: const Text(
                  'Save',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PersonCell extends StatelessWidget {
  const _PersonCell({required this.person, required this.isDark});
  final ReportingPersonModel person;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          radius: 18,
          backgroundColor: _hexToColor(person.avatarColor),
          child: Text(
            person.initials,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                person.name,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                person.levelLabel,
                style: TextStyle(
                  fontSize: 10,
                  color: isDark ? Colors.white54 : const Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
      ],
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

class _ManagersCell extends StatelessWidget {
  const _ManagersCell({
    required this.person,
    required this.allPeople,
    required this.managers,
    required this.addLabel,
    required this.isDark,
    required this.accentColor,
    required this.isPrimary,
    this.dotted = false,
  });

  final ReportingPersonModel person;
  final List<ReportingPersonModel> allPeople;
  final List<ReportingPersonModel> managers;
  final String addLabel;
  final bool isDark;
  final Color accentColor;
  final bool isPrimary;
  final bool dotted;

  @override
  Widget build(BuildContext context) {
    final existingIds = managers.map((m) => m.id).toSet();
    final availablePeople = allPeople
        .where((p) => p.id != person.id && !existingIds.contains(p.id))
        .toList();

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        // Existing manager chips
        ...managers.map((m) => _ManagerChip(
              name: m.name,
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
        // Add button chip with PopupMenuButton
        if (availablePeople.isNotEmpty)
          PopupMenuButton<int>(
            offset: const Offset(0, 30),
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            onSelected: (selectedManagerId) {
              context.read<AdminReportingBloc>().add(
                    AddManagerEvent(
                      personId: person.id,
                      managerId: selectedManagerId,
                      isPrimary: isPrimary,
                    ),
                  );
            },
            itemBuilder: (context) {
              return availablePeople.map((p) {
                return PopupMenuItem<int>(
                  value: p.id,
                  height: 36,
                  child: Text(
                    p.name,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                );
              }).toList();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                border: Border.all(
                  color: isDark ? Colors.white24 : Colors.grey.shade300,
                  style: BorderStyle.solid,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    addLabel,
                    style: TextStyle(
                      fontSize: 10,
                      color: isDark ? Colors.white54 : Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(width: 2),
                  Icon(Icons.arrow_drop_down_rounded,
                      size: 14,
                      color: isDark ? Colors.white54 : Colors.grey.shade600),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _ManagerChip extends StatelessWidget {
  const _ManagerChip({
    required this.name,
    required this.isDark,
    required this.accentColor,
    this.dotted = false,
    this.onDelete,
  });
  final String name;
  final bool isDark;
  final Color accentColor;
  final bool dotted;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isDark
            ? accentColor.withValues(alpha: 0.2)
            : accentColor.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? accentColor.withValues(alpha: 0.5)
              : accentColor.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            name,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.white : accentColor,
            ),
          ),
          const SizedBox(width: 4),
          InkWell(
            onTap: onDelete,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.all(2),
              child: Icon(Icons.close_rounded,
                  size: 13,
                  color: isDark
                      ? Colors.white70
                      : accentColor.withValues(alpha: 0.7)),
            ),
          ),
        ],
      ),
    );
  }
}
