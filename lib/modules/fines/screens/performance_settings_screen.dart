import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/localization/app_strings.dart';
import '../../../shared_widgets/announcement_banner_wrapper.dart';
import '../../../shared_widgets/app_bar/custom_app_bar.dart';
import '../../../shared_widgets/dialogs/exit_confirmation_dialog.dart';
import '../../../shared_widgets/drawer/custom_left_drawer.dart';
import '../../../shared_widgets/floating_action_button/todo_floating_action_button.dart';
import '../bloc/fines_bloc.dart';
import '../bloc/fines_event.dart';
import '../bloc/fines_state.dart';
import '../models/fine_type_model.dart';

class PerformanceSettingsScreen extends StatefulWidget {
  const PerformanceSettingsScreen({super.key});

  @override
  State<PerformanceSettingsScreen> createState() => _PerformanceSettingsScreenState();
}

class _PolicyRowData {
  final int id;
  final String kind;
  final TextEditingController labelController;
  final TextEditingController amountController;
  final String initialLabel;
  final String initialAmount;

  _PolicyRowData({
    required this.id,
    required this.kind,
    required this.labelController,
    required this.amountController,
    required this.initialLabel,
    required this.initialAmount,
  });

  bool get isModified =>
      labelController.text.trim() != initialLabel ||
      amountController.text.trim() != initialAmount;

  void dispose() {
    labelController.dispose();
    amountController.dispose();
  }
}

class _PerformanceSettingsScreenState extends State<PerformanceSettingsScreen> {
  final List<_PolicyRowData> _fineRows = [];
  final List<_PolicyRowData> _rewardRows = [];
  List<FineTypeModel> _latestLoadedTypes = [];
  bool _isSaving = false;

  @override
  void dispose() {
    _clearRows();
    super.dispose();
  }

  void _clearRows() {
    for (final r in _fineRows) {
      r.dispose();
    }
    _fineRows.clear();

    for (final r in _rewardRows) {
      r.dispose();
    }
    _rewardRows.clear();
  }

  void _populateRows(List<FineTypeModel> types) {
    _clearRows();
    _latestLoadedTypes = List.from(types);

    for (final item in types) {
      final row = _PolicyRowData(
        id: item.id,
        kind: item.kind,
        labelController: TextEditingController(text: item.label),
        amountController: TextEditingController(text: item.amount),
        initialLabel: item.label,
        initialAmount: item.amount,
      );

      if (item.kind.toLowerCase() == 'reward') {
        _rewardRows.add(row);
      } else {
        _fineRows.add(row);
      }
    }
  }

  void _discardChanges() {
    setState(() {
      _populateRows(_latestLoadedTypes);
    });
  }

  void _saveSettings(BuildContext blocContext) {
    final s = AppStrings.of(context);
    final allRows = [..._fineRows, ..._rewardRows];

    final payloadList = <Map<String, dynamic>>[];
    for (final row in allRows) {
      final label = row.labelController.text.trim();
      final amountStr = row.amountController.text.trim();

      if (label.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(s.pleaseEnterValidLabel),
            backgroundColor: Colors.red.shade700,
          ),
        );
        return;
      }

      final parsedAmount = num.tryParse(amountStr);
      if (parsedAmount == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(s.pleaseEnterValidAmount),
            backgroundColor: Colors.red.shade700,
          ),
        );
        return;
      }

      payloadList.add({
        'id': row.id,
        'label': label,
        'amount': (parsedAmount % 1 == 0) ? parsedAmount.toInt() : parsedAmount,
      });
    }

    blocContext.read<FinesBloc>().add(UpdateFineTypesEvent(payloadList));
  }

  Future<void> _showDeleteConfirmDialog({
    required BuildContext blocContext,
    required int id,
    required String kind,
    required String label,
  }) async {
    final s = AppStrings.of(context);
    final isFine = kind.toLowerCase() == 'fine';
    final finesBloc = blocContext.read<FinesBloc>();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            isFine ? s.deleteFineTypeConfirmTitle : s.deleteRewardTypeConfirmTitle,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Text(
            isFine
                ? s.deleteFineTypeConfirmMessage(label)
                : s.deleteRewardTypeConfirmMessage(label),
            style: const TextStyle(fontSize: 14, height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogCtx).pop(false),
              child: Text(s.cancelButton),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade700,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () => Navigator.of(dialogCtx).pop(true),
              child: Text(s.deleteButton),
            ),
          ],
        );
      },
    );

    if (confirmed == true && mounted) {
      finesBloc.add(
        DeleteFineTypeEvent(id: id, kind: kind, label: label),
      );
    }
  }

  Future<void> _showAddTypeDialog({
    required BuildContext blocContext,
    required bool isFine,
  }) async {
    final s = AppStrings.of(context);
    final labelCtrl = TextEditingController();
    final amountCtrl = TextEditingController(text: isFine ? '10' : '0');
    final formKey = GlobalKey<FormState>();
    final finesBloc = blocContext.read<FinesBloc>();

    final added = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) {
        final isDark = Theme.of(dialogCtx).brightness == Brightness.dark;

        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            isFine ? s.addFineTypeDialogTitle : s.addRewardTypeDialogTitle,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    s.policyNameLabel,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white70 : const Color(0xFF475569),
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: labelCtrl,
                    decoration: InputDecoration(
                      hintText: isFine ? 'e.g. Overdue > 3 days' : 'e.g. Star performer',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return s.pleaseEnterValidLabel;
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  Text(
                    isFine ? s.policyAmountLabel : s.policyPointsLabel,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white70 : const Color(0xFF475569),
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: amountCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      prefixText: isFine ? '₹ ' : null,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return s.pleaseEnterValidAmount;
                      }
                      if (num.tryParse(val.trim()) == null) {
                        return s.pleaseEnterValidAmount;
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogCtx).pop(false),
              child: Text(s.cancelButton),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.button(dialogCtx),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () {
                if (formKey.currentState?.validate() == true) {
                  Navigator.of(dialogCtx).pop(true);
                }
              },
              child: Text(s.addButton),
            ),
          ],
        );
      },
    );

    if (added == true && mounted) {
      final label = labelCtrl.text.trim();
      final numVal = num.tryParse(amountCtrl.text.trim()) ?? 0;
      final dynamic amount = (numVal % 1 == 0) ? numVal.toInt() : numVal;

      finesBloc.add(
        AddFineTypeEvent(
          kind: isFine ? 'fine' : 'reward',
          label: label,
          amount: amount,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocProvider(
      create: (context) => FinesBloc()..add(FetchFineTypesEvent()),
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) async {
          if (didPop) return;
          final shouldExit = await ExitConfirmationDialog.show(context);
          if (shouldExit) {
            // Handled in dialog
          }
        },
        child: Scaffold(
          floatingActionButton: const TodoFloatingActionButton(),
          drawer: const CustomLeftDrawer(currentRoute: '/performance-settings'),
          appBar: const CustomAppBar(),
          body: AnnouncementBannerWrapper(
            child: BlocConsumer<FinesBloc, FinesState>(
            listener: (context, state) {
              if (state is FineTypesLoadedState) {
                setState(() {
                  _isSaving = false;
                  _populateRows(state.fineTypes);
                });
              } else if (state is FineTypesSavingState) {
                setState(() {
                  _isSaving = true;
                });
              } else if (state is FineTypesActionSuccessState) {
                setState(() {
                  _isSaving = false;
                  _populateRows(state.fineTypes);
                });

                String successMessage = s.settingsSavedSuccessfully;
                if (state.message == 'added') {
                  successMessage = s.fineTypeAddedSuccessfully;
                } else if (state.message == 'deleted') {
                  successMessage = s.fineTypeDeletedSuccessfully;
                }

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(successMessage),
                    backgroundColor: Colors.green.shade700,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              } else if (state is FineTypesActionErrorState) {
                setState(() {
                  _isSaving = false;
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.message),
                    backgroundColor: Colors.red.shade700,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            builder: (blocContext, state) {
              if (state is FinesLoadingState) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }

              if (state is FinesErrorState && _fineRows.isEmpty && _rewardRows.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          state.message,
                          style: const TextStyle(color: Colors.red),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () =>
                              blocContext.read<FinesBloc>().add(FetchFineTypesEvent()),
                          child: Text(s.retryButton),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: () async {
                  blocContext.read<FinesBloc>().add(FetchFineTypesEvent());
                },
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header with Title and "Director only" badge
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 10,
                        runSpacing: 6,
                        children: [
                          Text(
                            s.performanceSettingsTitle,
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                              letterSpacing: -0.2,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              s.directorOnlyBadge,
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                                color: isDark ? Colors.white70 : const Color(0xFF475569),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        s.performanceSettingsSubtitle,
                        style: TextStyle(
                          fontSize: 12.5,
                          color: isDark ? Colors.white60 : const Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Responsive Cards: Row on Desktop/Tablet, Column on Mobile
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final isWide = constraints.maxWidth >= 768;

                          final fineCard = _buildPolicyCard(
                            blocContext: blocContext,
                            title: s.finePolicyHeader,
                            colHeader: s.rupeeAmountColumnHeader,
                            rows: _fineRows,
                            isFine: true,
                            addButtonText: s.addFineTypeButton,
                            isDark: isDark,
                          );

                          final rewardCard = _buildPolicyCard(
                            blocContext: blocContext,
                            title: s.rewardPolicyHeader,
                            colHeader: s.pointsColumnHeader,
                            rows: _rewardRows,
                            isFine: false,
                            addButtonText: s.addRewardTypeButton,
                            isDark: isDark,
                          );

                          if (isWide) {
                            return Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(child: fineCard),
                                const SizedBox(width: 16),
                                Expanded(child: rewardCard),
                              ],
                            );
                          } else {
                            return Column(
                              children: [
                                fineCard,
                                const SizedBox(height: 20),
                                rewardCard,
                              ],
                            );
                          }
                        },
                      ),
                      const SizedBox(height: 28),

                      // Bottom Action Buttons: Save Settings & Discard Changes
                      Row(
                        children: [
                          ElevatedButton(
                            onPressed: _isSaving ? null : () => _saveSettings(blocContext),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.button(context),
                              foregroundColor: Colors.white,
                              disabledBackgroundColor: const Color(0xFF64748B),
                              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              elevation: 0,
                            ),
                            child: _isSaving
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : Text(
                                    s.saveSettingsButton,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                          ),
                          const SizedBox(width: 12),
                          OutlinedButton(
                            onPressed: _isSaving ? null : _discardChanges,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: isDark ? Colors.white70 : const Color(0xFF334155),
                              side: BorderSide(
                                color: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1),
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            child: Text(
                              s.discardChangesButton,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 48),
                    ],
                  ),
                ),
              );
            },
          ),
          ),
        ),
      ),
    );
  }

  Widget _buildPolicyCard({
    required BuildContext blocContext,
    required String title,
    required String colHeader,
    required List<_PolicyRowData> rows,
    required bool isFine,
    required String addButtonText,
    required bool isDark,
  }) {
    final s = AppStrings.of(context);

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
        boxShadow: isDark
            ? null
            : const [
                BoxShadow(
                  color: Color.fromRGBO(0, 0, 0, 0.02),
                  blurRadius: 6,
                  offset: Offset(0, 2),
                ),
              ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card Section Header
          Text(
            title,
            style: const TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
              color: Color(0xFF64748B),
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 14),

          // Column Headers
          Row(
            children: [
              Expanded(
                child: Text(
                  s.typeColumnHeader,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white60 : const Color(0xFF64748B),
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 86,
                child: Text(
                  colHeader,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white60 : const Color(0xFF64748B),
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const SizedBox(width: 44), // Space matching delete icon button
            ],
          ),
          Divider(
            height: 18,
            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          ),

          // Policy List Rows
          if (rows.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  s.noDataAvailable,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.white38 : Colors.black38,
                  ),
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: rows.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final row = rows[index];

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Editable Label
                    Expanded(
                      child: SizedBox(
                        height: 40,
                        child: TextField(
                          controller: row.labelController,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                          decoration: InputDecoration(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            isDense: true,
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
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(
                                color: Color(0xFF0F172A),
                                width: 1.5,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Editable Amount / Points
                    SizedBox(
                      width: 86,
                      height: 40,
                      child: TextField(
                        controller: row.amountController,
                        textAlign: TextAlign.center,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                        decoration: InputDecoration(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                          isDense: true,
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
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                              color: Color(0xFF0F172A),
                              width: 1.5,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),

                    // Delete Trash Icon Button
                    SizedBox(
                      width: 40,
                      height: 40,
                      child: IconButton(
                        icon: const Icon(Icons.delete_outline_rounded, size: 20),
                        color: isDark ? Colors.white54 : const Color(0xFF94A3B8),
                        splashRadius: 20,
                        tooltip: isFine ? s.deleteFineTypeConfirmTitle : s.deleteRewardTypeConfirmTitle,
                        onPressed: () => _showDeleteConfirmDialog(
                          blocContext: blocContext,
                          id: row.id,
                          kind: row.kind,
                          label: row.labelController.text.trim().isNotEmpty
                              ? row.labelController.text.trim()
                              : row.initialLabel,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          const SizedBox(height: 16),

          // Add Button
          OutlinedButton.icon(
            onPressed: () => _showAddTypeDialog(
              blocContext: blocContext,
              isFine: isFine,
            ),
            icon: const Icon(Icons.add, size: 16),
            label: Text(
              addButtonText,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: isDark ? Colors.white : const Color(0xFF0F172A),
              side: BorderSide(
                color: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ],
      ),
    );
  }
}
