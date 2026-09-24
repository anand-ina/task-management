import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/localization/app_strings.dart';
import '../../../shared_widgets/app_bar/custom_app_bar.dart';
import '../../../shared_widgets/dialogs/exit_confirmation_dialog.dart';
import '../../../shared_widgets/drawer/custom_left_drawer.dart';
import '../../announcements/bloc/announcements_bloc.dart';
import '../../announcements/bloc/announcements_event.dart';
import '../../announcements/bloc/announcements_state.dart';
import '../../announcements/widgets/announcement_ticker_bar.dart';
import '../bloc/hourly_log_bloc.dart';
import '../bloc/hourly_log_event.dart';
import '../bloc/hourly_log_state.dart';
import '../models/hourly_log_model.dart';

class HourlyLogScreen extends StatefulWidget {
  const HourlyLogScreen({super.key});

  @override
  State<HourlyLogScreen> createState() => _HourlyLogScreenState();
}

class _HourlyLogScreenState extends State<HourlyLogScreen> {
  DateTime _selectedDate = DateTime.now();
  final Map<String, TextEditingController> _controllers = {};

  @override
  void initState() {
    super.initState();
    _fetchLogs();
    context.read<AnnouncementsBloc>().add(const FetchAnnouncementsEvent());
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _fetchLogs() {
    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
    context.read<HourlyLogBloc>().add(FetchHourlyLogEvent(date: dateStr));
  }

  TextEditingController _getController(String slot) {
    if (!_controllers.containsKey(slot)) {
      _controllers[slot] = TextEditingController();
    }
    return _controllers[slot]!;
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.fromSeed(
              seedColor: AppColors.button(context),
              brightness: Theme.of(context).brightness,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
      _fetchLogs();
    }
  }

  void _showSubmitDsrConfirmDialog() {
    final s = AppStrings.of(context);
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: AppColors.surface(ctx),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(Icons.assignment_turned_in_outlined, color: AppColors.button(ctx), size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  s.submitDsrConfirmTitle,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary(ctx),
                  ),
                ),
              ),
            ],
          ),
          content: Text(
            s.submitDsrConfirmMessage,
            style: TextStyle(
              fontSize: 14,
              height: 1.4,
              color: AppColors.textSecondary(ctx),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(s.cancelButton, style: TextStyle(color: AppColors.textSecondary(ctx))),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.button(ctx),
                foregroundColor: AppColors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () {
                Navigator.pop(ctx);
                context.read<HourlyLogBloc>().add(const SubmitDsrEvent());
              },
              child: Text(s.submitDsr),
            ),
          ],
        );
      },
    );
  }

  void _showEditDialog(HourlyItemModel item, String slot) {
    final s = AppStrings.of(context);
    final editController = TextEditingController(text: item.body);

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: AppColors.surface(ctx),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            s.editLogEntry,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary(ctx),
            ),
          ),
          content: TextField(
            controller: editController,
            autofocus: true,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: s.whatDidYouWorkOn,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(s.cancelButton, style: TextStyle(color: AppColors.textSecondary(ctx))),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.button(ctx),
                foregroundColor: AppColors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () {
                final newText = editController.text.trim();
                if (newText.isNotEmpty && newText != item.body) {
                  context.read<HourlyLogBloc>().add(
                    EditHourlyItemEvent(id: item.id, slot: slot, body: newText),
                  );
                }
                Navigator.pop(ctx);
              },
              child: Text(s.saveButton),
            ),
          ],
        );
      },
    );
  }

  void _confirmDelete(HourlyItemModel item, String slot) {
    final s = AppStrings.of(context);
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: AppColors.surface(ctx),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            s.delete,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary(ctx),
            ),
          ),
          content: Text(
            s.deleteItemConfirm,
            style: TextStyle(color: AppColors.textSecondary(ctx)),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(s.cancelButton, style: TextStyle(color: AppColors.textSecondary(ctx))),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.red700,
                foregroundColor: AppColors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () {
                context.read<HourlyLogBloc>().add(
                  DeleteHourlyItemEvent(id: item.id, slot: slot),
                );
                Navigator.pop(ctx);
              },
              child: Text(s.deleteButton),
            ),
          ],
        );
      },
    );
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
        if (shouldExit == true && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.scaffoldBg(context),
        appBar: const CustomAppBar(),
        drawer: const CustomLeftDrawer(),
        body: BlocConsumer<HourlyLogBloc, HourlyLogState>(
          listener: (context, state) {
            if (state is HourlyLogLoadedState && state.actionMessage != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.actionMessage!),
                  backgroundColor: state.isSuccess ? AppColors.green600 : AppColors.red700,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          },
          builder: (context, state) {
            if (state is HourlyLogLoadingState || state is HourlyLogInitialState) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state is HourlyLogErrorState) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.error_outline_rounded, size: 48, color: AppColors.red),
                    const SizedBox(height: 12),
                    Text(
                      state.message,
                      style: TextStyle(
                        fontSize: 15,
                        color: AppColors.textSecondary(context),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.button(context),
                        foregroundColor: AppColors.white,
                      ),
                      onPressed: _fetchLogs,
                      child: Text(s.retryButton),
                    ),
                  ],
                ),
              );
            }

            final loaded = state as HourlyLogLoadedState;
            final hourlyLog = loaded.hourlyLog;
            final formattedDate = DateFormat('EEE d MMM').format(_selectedDate);

            final filledSlots = hourlyLog.filledSlots;
            final totalSlots = hourlyLog.totalSlots > 0 ? hourlyLog.totalSlots : 10;
            final progress = totalSlots > 0 ? (filledSlots / totalSlots).clamp(0.0, 1.0) : 0.0;
            final isSubmitted = hourlyLog.isSubmitted;

            return Column(
              children: [
                // Announcements Ticker Bar
                BlocBuilder<AnnouncementsBloc, AnnouncementsState>(
                  builder: (context, aState) {
                    if (aState is AnnouncementsLoadedState && aState.activeAnnouncements.isNotEmpty) {
                      return AnnouncementTickerBar(announcements: aState.activeAnnouncements);
                    }
                    return const SizedBox.shrink();
                  },
                ),
                // Main Content
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () async => _fetchLogs(),
                    child: ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      children: [
                        // Header Card
                        Card(
                          elevation: 0,
                          color: AppColors.card(context),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(color: AppColors.border(context)),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Title + Chips Row / Wrap
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  children: [
                                    Text(
                                      s.dailyHourlyLog,
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.textPrimary(context),
                                      ),
                                    ),
                                    // Date Chip
                                    InkWell(
                                      onTap: _pickDate,
                                      borderRadius: BorderRadius.circular(8),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: AppColors.chipBg(context),
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(color: AppColors.border(context)),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.calendar_today_outlined,
                                              size: 13,
                                              color: AppColors.textSecondary(context),
                                            ),
                                            const SizedBox(width: 6),
                                            Text(
                                              formattedDate,
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                                color: AppColors.textPrimary(context),
                                              ),
                                            ),
                                            const SizedBox(width: 4),
                                            Icon(
                                              Icons.arrow_drop_down_rounded,
                                              size: 16,
                                              color: AppColors.textSecondary(context),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    // Slots Filled Chip
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: AppColors.chipBg(context),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: AppColors.border(context)),
                                      ),
                                      child: Text(
                                        s.slotsFilledCount(filledSlots, totalSlots),
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.textSecondary(context),
                                        ),
                                      ),
                                    ),
                                    // Submitted Badge or Submit DSR Button
                                    if (isSubmitted)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: AppColors.green.withValues(alpha: 0.12),
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(color: AppColors.green.withValues(alpha: 0.35)),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(
                                              Icons.check_circle_rounded,
                                              size: 14,
                                              color: AppColors.green,
                                            ),
                                            const SizedBox(width: 5),
                                            Text(
                                              s.submittedStatus,
                                              style: const TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                                color: AppColors.green,
                                              ),
                                            ),
                                          ],
                                        ),
                                      )
                                    else
                                      ElevatedButton.icon(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppColors.button(context),
                                          foregroundColor: AppColors.white,
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          elevation: 0,
                                          visualDensity: VisualDensity.compact,
                                        ),
                                        onPressed: loaded.isSubmitting ? null : _showSubmitDsrConfirmDialog,
                                        icon: loaded.isSubmitting
                                            ? SizedBox(
                                                width: 14,
                                                height: 14,
                                                child: CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                  color: AppColors.white,
                                                ),
                                              )
                                            : const Icon(Icons.send_rounded, size: 14),
                                        label: Text(
                                          s.submitDsr,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 12),

                                // Subtitle
                                Text(
                                  s.dailyHourlyLogSubtitle,
                                  style: TextStyle(
                                    fontSize: 13,
                                    height: 1.4,
                                    color: AppColors.textSecondary(context),
                                  ),
                                ),
                                const SizedBox(height: 14),

                                // Progress bar
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: LinearProgressIndicator(
                                    value: progress,
                                    minHeight: 6,
                                    backgroundColor: isDark
                                        ? AppColors.white.withValues(alpha: 0.12)
                                        : AppColors.black.withValues(alpha: 0.08),
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      progress >= 1.0 ? AppColors.green : AppColors.button(context),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Slot Cards (Standard 10 slots)
                        ...hourlyLog.slots.map((slot) => _buildSlotCard(slot, loaded, isSubmitted)),

                        // Extended Slot if available
                        if (hourlyLog.extSlot != null && hourlyLog.extSlot!.isNotEmpty)
                          _buildSlotCard(
                            HourlySlotModel(
                              slot: hourlyLog.extSlot!,
                              items: hourlyLog.extItems,
                              lunch: false,
                            ),
                            loaded,
                            isSubmitted,
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildSlotCard(HourlySlotModel slot, HourlyLogLoadedState state, bool isSubmitted) {
    final s = AppStrings.of(context);
    final controller = _getController(slot.slot);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border(context)),
      ),
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Left Blue Accent Bar (matching Image 2)
            Container(
              width: 4,
              color: AppColors.accentBlue(context),
            ),
            // Card Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Slot Header Row: Time + Lunch action/badge
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.access_time_rounded,
                              size: 16,
                              color: AppColors.textSecondary(context),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              slot.slot,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary(context),
                              ),
                            ),
                          ],
                        ),
                        if (!isSubmitted)
                          OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              visualDensity: VisualDensity.compact,
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              side: BorderSide(
                                color: slot.lunch ? AppColors.orange800 : AppColors.border(context),
                              ),
                              backgroundColor: slot.lunch
                                  ? AppColors.orange.withValues(alpha: 0.12)
                                  : AppColors.transparent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            onPressed: () {
                              context.read<HourlyLogBloc>().add(SetLunchSlotEvent(slot: slot.slot));
                            },
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (slot.lunch) const Text('🍽️ ', style: TextStyle(fontSize: 11)),
                                Text(
                                  slot.lunch ? s.lunchHour : s.setAsLunch,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: slot.lunch
                                        ? AppColors.orange800
                                        : AppColors.textSecondary(context),
                                  ),
                                ),
                              ],
                            ),
                          )
                        else if (slot.lunch)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.orange.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: AppColors.orange.withValues(alpha: 0.3)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text('🍽️ ', style: TextStyle(fontSize: 11)),
                                Text(
                                  s.lunchHour,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.orange800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // If it's a lunch hour during editable mode, display banner
                    if (slot.lunch && !isSubmitted)
                      Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.orange.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.orange.withValues(alpha: 0.2)),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.restaurant_rounded, size: 16, color: AppColors.orange800),
                            const SizedBox(width: 8),
                            Text(
                              s.lunchHour,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.orange800,
                              ),
                            ),
                          ],
                        ),
                      ),

                    // Items or "Not filled" (matching Image 2)
                    if (slot.items.isEmpty && !slot.lunch)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Text(
                          s.notFilledStatus,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: AppColors.red,
                          ),
                        ),
                      )
                    else
                      ...slot.items.map((item) {
                        return Container(
                          margin: const EdgeInsets.only(bottom: 6),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.chipBg(context),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Container(
                                width: 5,
                                height: 5,
                                margin: const EdgeInsets.only(right: 8),
                                decoration: BoxDecoration(
                                  color: AppColors.textPrimary(context),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  item.body,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: AppColors.textPrimary(context),
                                  ),
                                ),
                              ),
                              if (!isSubmitted) ...[
                                const SizedBox(width: 6),
                                InkWell(
                                  onTap: () => _showEditDialog(item, slot.slot),
                                  borderRadius: BorderRadius.circular(4),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: AppColors.surface(context),
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(color: AppColors.border(context)),
                                    ),
                                    child: Text(
                                      s.edit,
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textSecondary(context),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                InkWell(
                                  onTap: () => _confirmDelete(item, slot.slot),
                                  borderRadius: BorderRadius.circular(10),
                                  child: Container(
                                    width: 20,
                                    height: 20,
                                    decoration: BoxDecoration(
                                      color: AppColors.red.withValues(alpha: 0.12),
                                      shape: BoxShape.circle,
                                    ),
                                    alignment: Alignment.center,
                                    child: const Icon(
                                      Icons.close_rounded,
                                      size: 12,
                                      color: AppColors.red,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        );
                      }),

                    // Add input field row (only if NOT submitted)
                    if (!isSubmitted) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              height: 38,
                              decoration: BoxDecoration(
                                color: AppColors.surface(context),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: AppColors.border(context)),
                              ),
                              alignment: Alignment.center,
                              child: TextField(
                                controller: controller,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textPrimary(context),
                                ),
                                decoration: InputDecoration(
                                  hintText: s.whatDidYouWorkOn,
                                  hintStyle: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary(context).withValues(alpha: 0.7),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                  border: InputBorder.none,
                                  isDense: true,
                                ),
                                onSubmitted: (val) {
                                  final text = val.trim();
                                  if (text.isNotEmpty) {
                                    context.read<HourlyLogBloc>().add(
                                      AddHourlyItemEvent(slot: slot.slot, body: text),
                                    );
                                    controller.clear();
                                  }
                                },
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          SizedBox(
                            height: 38,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.button(context),
                                foregroundColor: AppColors.white,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(horizontal: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              onPressed: () {
                                final text = controller.text.trim();
                                if (text.isNotEmpty) {
                                  context.read<HourlyLogBloc>().add(
                                    AddHourlyItemEvent(slot: slot.slot, body: text),
                                  );
                                  controller.clear();
                                }
                              },
                              child: Text(
                                s.addEntry,
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
