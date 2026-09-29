import '../../../shared_widgets/floating_action_button/todo_floating_action_button.dart';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/localization/app_strings.dart';
import '../../../core/network/dio_client.dart';
import '../../../shared_widgets/announcement_banner_wrapper.dart';
import '../../../shared_widgets/app_bar/custom_app_bar.dart';
import '../../dashboard/screens/dashboard_screen.dart';
import '../../../shared_widgets/drawer/custom_left_drawer.dart';
import '../../../shared_widgets/dialogs/schedule_meeting_dialog.dart';
import '../bloc/meetings_bloc.dart';
import '../bloc/meetings_event.dart';
import '../bloc/meetings_state.dart';
import '../models/google_calendar_status_model.dart';
import '../models/meeting_model.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../auth/bloc/auth_state.dart';
import '../../reports/screens/status_reports_screen.dart';
import 'google_calendar_auth_webview_screen.dart';

class MyScheduledMeetingsScreen extends StatefulWidget {
  const MyScheduledMeetingsScreen({super.key});

  @override
  State<MyScheduledMeetingsScreen> createState() => _MyScheduledMeetingsScreenState();
}

class _MyScheduledMeetingsScreenState extends State<MyScheduledMeetingsScreen>
    with WidgetsBindingObserver {
  int _selectedTabIndex = 0; // 0: All, 1: Initiated by Me, 2: Received by Me
  final DioClient _dioClient = DioClient();
  final Set<dynamic> _attendedMeetingIds = {};
  bool _isAwaitingGoogleAuthReturn = false;

  late final MeetingsBloc _meetingsBloc;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _meetingsBloc = MeetingsBloc()..add(FetchMyScheduledMeetingsEvent());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _meetingsBloc.close();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _isAwaitingGoogleAuthReturn) {
      _isAwaitingGoogleAuthReturn = false;
      _handleReturnFromGoogleAuth();
    }
  }

  Future<void> _handleReturnFromGoogleAuth() async {
    if (!mounted) return;
    try {
      final repo = _meetingsBloc.repository;
      // 1. Call API 3 (The OAuth Callback check)
      await repo.callGoogleCalendarCallback();
      if (!mounted) return;
      // 2. Dispatch event to refresh state with API 1: /google-calendar/status
      _meetingsBloc.add(CompleteGoogleCalendarCallbackEvent());
      // 3. Verify status for user notification
      final status = await repo.getGoogleCalendarStatus();
      if (!mounted) return;
      final s = AppStrings.of(context);
      if (status != null && status.connected) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(s.googleCalendarConnectedSuccess),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (_) {}
  }

  String _extractErrorMessage(dynamic error) {
    if (error is DioException) {
      final data = error.response?.data;
      if (data is Map) {
        final msg = data['message'];
        if (msg != null) {
          if (msg is List) return msg.join(', ');
          if (msg.toString().trim().isNotEmpty) return msg.toString();
        }
        final err = data['error'];
        if (err != null && err.toString().trim().isNotEmpty) {
          return err.toString();
        }
      } else if (data is String && data.trim().isNotEmpty) {
        try {
          final decoded = jsonDecode(data);
          if (decoded is Map) {
            final msg = decoded['message'];
            if (msg != null) {
              if (msg is List) return msg.join(', ');
              if (msg.toString().trim().isNotEmpty) return msg.toString();
            }
            final err = decoded['error'];
            if (err != null && err.toString().trim().isNotEmpty) {
              return err.toString();
            }
          }
        } catch (_) {
          return data;
        }
      }
      if (error.message != null && error.message!.trim().isNotEmpty) {
        return error.message!;
      }
    }
    final str = error.toString();
    if (str.startsWith('Exception: ')) return str.substring(11);
    return str;
  }

  void _showErrorToast(BuildContext context, dynamic error) {
    final msg = _extractErrorMessage(error);
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Colors.red,
      ),
    );
  }

  Future<void> _markAttended(MeetingItemModel item) async {
    try {
      final meetingId = item.rawId ?? item.id;
      final response = await _dioClient.dio.post('${ApiConstants.baseUrl}/meetings/$meetingId/attend');
      debugPrint('[Meetings] attend API URL: ${ApiConstants.baseUrl}/meetings/$meetingId/attend, response: ${response.data}');
      if (!mounted) return;
      setState(() {
        _attendedMeetingIds.add(item.id);
        if (item.rawId != null) _attendedMeetingIds.add(item.rawId);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Attendance marked! +2 points earned 🎉'),
          backgroundColor: Colors.green,
        ),
      );
      _meetingsBloc.add(FetchMyScheduledMeetingsEvent());
    } catch (e) {
      if (mounted) {
        _showErrorToast(context, e);
      }
    }
  }

  void _showMeetingReminder(BuildContext context, MeetingItemModel item) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Dialog(
          alignment: Alignment.topRight,
                insetPadding: const EdgeInsets.only(top: 60, right: 20),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                child: Container(
                  width: 320,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: const [
                          Text('🔔 ', style: TextStyle(fontSize: 12)),
                          Text(
                            'MEETING REMINDER',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.red),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        item.title,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${_formatMeetingDate(item.startsAt)} · ${item.location ?? "Online"}',
                        style: const TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.button(context),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                              ),
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Join', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                              ),
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Snooze', style: TextStyle(fontSize: 11)),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red.shade800,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                              ),
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Not available', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Delivery follows your notification preferences.',
                        style: TextStyle(fontSize: 9.5, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              );
      },
    );
  }
  void _showPreviewRemindersDialog(BuildContext context, List<MeetingItemModel> meetings) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final upcomingMeetings = meetings.take(5).toList();

        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
          child: Container(
            width: 380,
            padding: const EdgeInsets.all(18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.notifications_active_outlined, size: 18, color: Colors.amber),
                        SizedBox(width: 8),
                        Text(
                          'Upcoming Meeting Reminders',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 18),
                      onPressed: () => Navigator.pop(context),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                if (upcomingMeetings.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(
                      child: Text('No upcoming meeting reminders scheduled.', style: TextStyle(color: Colors.grey, fontSize: 12)),
                    ),
                  )
                else
                  Column(
                    children: upcomingMeetings.map((item) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.alarm, size: 16, color: Colors.amber),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.title.isNotEmpty ? item.title : 'Scheduled Meeting',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                                    ),
                                  ),
                                  Text(
                                    '${_formatMeetingDate(item.startsAt)} · ${item.location ?? "In person"}',
                                    style: const TextStyle(fontSize: 10, color: Colors.grey),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.button(context),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Close', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _showMeetingHappenedDialog(MeetingItemModel item) async {
    final controller = TextEditingController();

    final result = await showDialog<String>(
      context: context,
      barrierDismissible: true,
      builder: (dialogCtx) {
        final isDark = Theme.of(dialogCtx).brightness == Brightness.dark;
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
          title: const Text('dev-task.srivyn.in says', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Add a note for the approver (what was covered, who attended):',
                style: TextStyle(fontSize: 12),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: controller,
                maxLines: 2,
                style: const TextStyle(fontSize: 12),
                decoration: InputDecoration(
                  isDense: true,
                  contentPadding: const EdgeInsets.all(10),
                  filled: true,
                  fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                ),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEAB308),
                foregroundColor: Colors.black87,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
              onPressed: () => Navigator.pop(dialogCtx, null),
              child: const Text('Cancel', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF65A30D),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
              onPressed: () => Navigator.pop(dialogCtx, controller.text),
              child: const Text('OK', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );

    if (result != null && result.isNotEmpty) {
      try {
        await _dioClient.dio.post(
          '${ApiConstants.baseUrl}/meetings/${item.id}/complete',
          data: {'note': result},
        );
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Meeting marked as completed!'), backgroundColor: Colors.green),
        );
        _meetingsBloc.add(FetchMyScheduledMeetingsEvent());
      } catch (e) {
        if (mounted) {
          _showErrorToast(context, e);
        }
      }
    }
  }

  Future<void> _handleConnectGoogleCalendar() async {
    try {
      final repo = _meetingsBloc.repository;
      // 1. Call API 2: Initiate Google Calendar Connection (Get OAuth URL)
      final url = await repo.getGoogleCalendarAuthUrl();
      if (url != null && url.isNotEmpty) {
        if (!mounted) return;
        // 2. Open Google Login directly in-app (not external browser, no web redirection)
        final result = await Navigator.of(context).push<dynamic>(
          MaterialPageRoute(
            builder: (_) => GoogleCalendarAuthWebViewScreen(authUrl: url),
          ),
        );

        if (!mounted) return;

        if (result == true) {
          // 3. Authenticated: Call API 3 callback check and refresh status via API 1
          await repo.callGoogleCalendarCallback();
          _meetingsBloc.add(CompleteGoogleCalendarCallbackEvent());
          await repo.getGoogleCalendarStatus();
          if (mounted) {
            final s = AppStrings.of(context);
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(s.googleCalendarConnectedSuccess),
                backgroundColor: Colors.green,
              ),
            );
          }
        } else if (result is String && result.isNotEmpty) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result),
              backgroundColor: Colors.red,
            ),
          );
        } else {
          // Check status in case connection was established before dismissing
          final status = await repo.getGoogleCalendarStatus();
          if (status != null && status.connected) {
            _meetingsBloc.add(CompleteGoogleCalendarCallbackEvent());
          }
        }
        return;
      }
      throw Exception('Failed to obtain Google Calendar authorization URL.');
    } catch (e) {
      if (mounted) {
        _showErrorToast(context, e);
      }
    }
  }

  Future<void> _confirmDisconnectGoogleCalendar(BuildContext parentContext) async {
    final s = AppStrings.of(parentContext);
    final isDark = Theme.of(parentContext).brightness == Brightness.dark;

    final confirm = await showDialog<bool>(
      context: parentContext,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        title: Text(
          s.disconnectGoogleCalendarTitle,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
          ),
        ),
        content: Text(
          s.disconnectGoogleCalendarConfirmation,
          style: TextStyle(
            fontSize: 14,
            color: isDark ? Colors.white70 : const Color(0xFF475569),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(s.cancelButton),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              s.disconnect,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      _meetingsBloc.add(DisconnectGoogleCalendarEvent());
    }
  }

  Widget _buildGoogleCalendarIntegrationBanner(
    BuildContext context,
    AppStrings s,
    bool isDark,
    GoogleCalendarStatusModel? calendarStatus,
  ) {
    final isConnected = calendarStatus?.connected == true;

    if (isConnected) {
      final email = calendarStatus?.googleAccountEmail ??
          calendarStatus?.systemAccountEmail ??
          '';

      return Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isNarrow = constraints.maxWidth < 600;

            final calendarIcon = Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF334155) : const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text('📅', style: TextStyle(fontSize: 20)),
            );

            final contentDetails = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    Text(
                      s.googleCalendarIntegration,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF064E3B) : const Color(0xFFDCFCE7),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDark ? const Color(0xFF047857) : const Color(0xFF86EFAC),
                        ),
                      ),
                      child: Text(
                        s.connectedStatus,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isDark ? const Color(0xFF6EE7B7) : const Color(0xFF16A34A),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  s.googleCalendarConnectedDescription(email),
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.white60 : const Color(0xFF64748B),
                    height: 1.35,
                  ),
                ),
              ],
            );

            final disconnectButton = OutlinedButton(
              style: OutlinedButton.styleFrom(
                side: BorderSide(
                  color: isDark ? const Color(0xFF7F1D1D) : const Color(0xFFFECACA),
                ),
                backgroundColor: isDark
                    ? const Color(0xFF451A1A).withValues(alpha: 0.3)
                    : const Color(0xFFFEF2F2),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () => _confirmDisconnectGoogleCalendar(context),
              child: Text(
                s.disconnect,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFDC2626),
                ),
              ),
            );

            if (isNarrow) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      calendarIcon,
                      const SizedBox(width: 12),
                      Expanded(child: contentDetails),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerRight,
                    child: disconnectButton,
                  ),
                ],
              );
            }

            return Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                calendarIcon,
                const SizedBox(width: 12),
                Expanded(child: contentDetails),
                const SizedBox(width: 16),
                disconnectButton,
              ],
            );
          },
        ),
      );
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF334155) : const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text('📅', style: TextStyle(fontSize: 20)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        Text(
                          s.googleCalendarIntegration,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF451A1A) : const Color(0xFFFEE2E2),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isDark ? const Color(0xFF7F1D1D) : const Color(0xFFFECACA),
                            ),
                          ),
                          child: Text(
                            s.notConnected,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFFDC2626),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      s.googleCalendarConnectDescription,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.white60 : const Color(0xFF64748B),
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ElevatedButton.icon(
            onPressed: _handleConnectGoogleCalendar,
            icon: const Icon(Icons.sync_rounded, size: 15),
            label: Text(
              s.connectGoogleCalendar,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocProvider<MeetingsBloc>.value(
      value: _meetingsBloc,
      child: BlocListener<MeetingsBloc, MeetingsState>(
        listener: (context, state) {
          if (state is MeetingsErrorState) {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          } else if (state is MyScheduledMeetingsLoadedState && state.isDisconnected) {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(s.googleCalendarDisconnectedSuccess),
                backgroundColor: const Color(0xFF16A34A),
              ),
            );
          }
        },
        child: PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, result) {
            if (didPop) return;
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const DashboardScreen()),
              (route) => false,
            );
          },
          child: Scaffold(
            floatingActionButton: const TodoFloatingActionButton(),
          drawer: const CustomLeftDrawer(currentRoute: '/my-meetings'),
            appBar: const CustomAppBar(),
          body: AnnouncementBannerWrapper(
            child: BlocBuilder<MeetingsBloc, MeetingsState>(
            builder: (context, state) {
              return RefreshIndicator(
                onRefresh: () async {
                  context.read<MeetingsBloc>().add(FetchMyScheduledMeetingsEvent());
                },
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Row
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  s.myScheduledMeetings,
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  s.meetingsOrganizeOrInvitedSubtitle,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDark ? Colors.white60 : Colors.black54,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            children: [
                              ElevatedButton.icon(
                                onPressed: () => ScheduleMeetingDialog.show(context),
                                 label: const Text(
                                  '+ New meeting',
                                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.button(context),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                              ),
                              OutlinedButton.icon(
                                onPressed: () => _showPreviewRemindersDialog(context, state is MyScheduledMeetingsLoadedState ? state.meetings : []),
                                icon: const Icon(Icons.notifications_active_outlined, size: 14, color: Colors.amber),
                                label: Text(s.previewRemindersButton, style: const TextStyle(fontSize: 11)),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                  side: BorderSide(color: isDark ? Colors.white24 : Colors.black12),
                                ),
                              ),
                            ],
                          ),

                        ],
                      ),
                      const SizedBox(height: 16),

                      // Auto status-report slots banner
                      InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const StatusReportsScreen()),
                          );
                        },
                        child: Container(
                          width: double.infinity,
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF1E293B) : const Color(0xFFFFFBEB),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFFDE68A)),
                          ),
                          child: Row(
                            children: [
                              const Text('📝 ', style: TextStyle(fontSize: 14)),
                              Expanded(
                                child: RichText(
                                  text: TextSpan(
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isDark ? Colors.white70 : const Color(0xFF92400E),
                                    ),
                                    children: [
                                      TextSpan(
                                        text: s.autoStatusReportSlotsToday,
                                        style: const TextStyle(fontWeight: FontWeight.w600),
                                      ),
                                      WidgetSpan(
                                        alignment: PlaceholderAlignment.middle,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFFEF3C7),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            s.dsrTimeSlot,
                                            style: const TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFFB45309),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Google Calendar Integration Banner
                      if (state is MyScheduledMeetingsLoadedState) ...[
                        _buildGoogleCalendarIntegrationBanner(
                          context,
                          s,
                          isDark,
                          state.calendarStatus,
                        ),
                      ],

                      // Segmented Tab Control
                      if (state is MyScheduledMeetingsLoadedState) ...[
                        Builder(
                          builder: (context) {
                            final meetings = state.meetings;
                            final initiated = meetings.where((m) => m.isOrganizer == true).length;
                            final received = meetings.where((m) => m.isOrganizer != true).length;
                            final total = meetings.length;

                            return Container(
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(24),
                              ),
                              padding: const EdgeInsets.all(4),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _buildTabPill(
                                    title: s.allTab,
                                    count: total,
                                    isSelected: _selectedTabIndex == 0,
                                    onTap: () => setState(() => _selectedTabIndex = 0),
                                  ),
                                  _buildTabPill(
                                    title: s.initiatedByMe,
                                    count: initiated,
                                    isSelected: _selectedTabIndex == 1,
                                    onTap: () => setState(() => _selectedTabIndex = 1),
                                  ),
                                  _buildTabPill(
                                    title: s.receivedByMe,
                                    count: received,
                                    isSelected: _selectedTabIndex == 2,
                                    onTap: () => setState(() => _selectedTabIndex = 2),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 20),
                      ],

                      // State Handling
                      if (state is MeetingsLoadingState)
                        const Padding(
                          padding: EdgeInsets.all(48),
                          child: Center(child: CircularProgressIndicator()),
                        )
                      else if (state is MeetingsErrorState)
                        Center(
                          child: Column(
                            children: [
                              Text(state.message, style: const TextStyle(color: Colors.red)),
                              const SizedBox(height: 12),
                              ElevatedButton(
                                onPressed: () {
                                  context.read<MeetingsBloc>().add(FetchMyScheduledMeetingsEvent());
                                },
                                child: Text(s.retryButton),
                              ),
                            ],
                          ),
                        )
                      else if (state is MyScheduledMeetingsLoadedState)
                        _buildMeetingsList(
                          context,
                          s,
                          state.meetings,
                          isCalendarConnected: state.calendarStatus?.connected == true,
                        )
                      else
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
      ),)
    );
  }

  Widget _buildTabPill({
    required String title,
    required int count,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? const Color(0xFF0F172A) : const Color(0xFF0F172A))
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
              ),
            ),
            const SizedBox(width: 3),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1.5),
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.white.withValues(alpha: 0.2)
                    : (isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.white : (isDark ? Colors.white70 : const Color(0xFF475569)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMeetingsList(
    BuildContext context,
    AppStrings s,
    List<MeetingItemModel> meetings, {
    bool isCalendarConnected = false,
  }) {
    final filtered = meetings.where((m) {
      if (_selectedTabIndex == 1) return m.isOrganizer == true;
      if (_selectedTabIndex == 2) return m.isOrganizer != true;
      return true;
    }).toList();

    if (filtered.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(40),
        child: Center(
          child: Text('No meetings found.', style: TextStyle(color: Colors.grey)),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > 700) {
          return GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
              mainAxisExtent: 265,
            ),
            itemCount: filtered.length,
            itemBuilder: (context, index) {
              return _buildMeetingCard(
                context,
                s,
                filtered[index],
                isCalendarConnected: isCalendarConnected,
              );
            },
          );
        }
        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: filtered.length,
          separatorBuilder: (context, index) => const SizedBox(height: 14),
          itemBuilder: (context, index) {
            return _buildMeetingCard(
              context,
              s,
              filtered[index],
              isCalendarConnected: isCalendarConnected,
            );
          },
        );
      },
    );
  }

  Future<void> _submitRsvp(MeetingItemModel item, String responseValue) async {
    try {
      final meetingId = item.rawId ?? item.id;
      await _dioClient.dio.post(
        '${ApiConstants.baseUrl}/meetings/$meetingId/rsvp',
        data: {'response': responseValue},
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('RSVP submitted as $responseValue'),
          backgroundColor: Colors.green,
        ),
      );
      context.read<MeetingsBloc>().add(FetchMyScheduledMeetingsEvent());
    } catch (e) {
      if (mounted) {
        _showErrorToast(context, e);
      }
    }
  }

  Future<void> _cancelMeeting(MeetingItemModel item) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        title: const Text('Cancel Meeting', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
        content: Text('Are you sure you want to cancel "${item.title.isNotEmpty ? item.title : "this meeting"}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('No'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      final meetingId = item.rawId ?? item.id;
      await _dioClient.dio.patch('${ApiConstants.baseUrl}/meetings/$meetingId', data: {'status': 'cancelled'});
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Meeting cancelled successfully'),
          backgroundColor: Colors.orange,
        ),
      );
      context.read<MeetingsBloc>().add(FetchMyScheduledMeetingsEvent());
    } catch (e) {
      if (mounted) {
        _showErrorToast(context, e);
      }
    }
  }

  Future<void> _showRescheduleDialog(MeetingItemModel item) async {
    DateTime selectedDate = DateTime.now().add(const Duration(days: 1));
    TimeOfDay selectedTime = const TimeOfDay(hour: 14, minute: 0);
    final noteController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogCtx, setDialogState) {
          final isDark = Theme.of(dialogCtx).brightness == Brightness.dark;
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
            title: const Text(
              'Request Time Change',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Current: ${_formatMeetingDate(item.startsAt)}',
                    style: TextStyle(fontSize: 12, color: isDark ? Colors.white60 : Colors.black54),
                  ),
                  const SizedBox(height: 14),
                  const Text('New Date & Time *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  InkWell(
                    onTap: () async {
                      final pickedDate = await showDatePicker(
                        context: dialogCtx,
                        initialDate: selectedDate,
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 90)),
                      );
                      if (pickedDate != null) {
                        if (!dialogCtx.mounted) return;
                        final pickedTime = await showTimePicker(
                          context: dialogCtx,
                          initialTime: selectedTime,
                        );
                        if (pickedTime != null) {
                          setDialogState(() {
                            selectedDate = pickedDate;
                            selectedTime = pickedTime;
                          });
                        }
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        border: Border.all(color: isDark ? Colors.white24 : Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${selectedDate.day}/${selectedDate.month}/${selectedDate.year} ${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}',
                            style: const TextStyle(fontSize: 13),
                          ),
                          const Icon(Icons.calendar_today_outlined, size: 16),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text('Reason / Note', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: noteController,
                    maxLines: 2,
                    decoration: InputDecoration(
                      hintText: 'e.g. Schedule conflict with urgent class',
                      hintStyle: TextStyle(fontSize: 12, color: isDark ? Colors.white38 : Colors.black38),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      contentPadding: const EdgeInsets.all(10),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogCtx, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () => Navigator.pop(dialogCtx, true),
                child: const Text('Submit Request'),
              ),
            ],
          );
        },
      ),
    );

    if (result == true) {
      try {
        final meetingId = item.rawId ?? item.id;
        final newDateTime = DateTime(
          selectedDate.year,
          selectedDate.month,
          selectedDate.day,
          selectedTime.hour,
          selectedTime.minute,
        ).toUtc().toIso8601String();

        await _dioClient.dio.post(
          '${ApiConstants.baseUrl}/meetings/$meetingId/reschedule',
          data: {
            'reschedule_start': newDateTime,
            'note': noteController.text.trim(),
          },
        );
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Time change request submitted successfully'),
            backgroundColor: Colors.green,
          ),
        );
        context.read<MeetingsBloc>().add(FetchMyScheduledMeetingsEvent());
      } catch (e) {
        if (mounted) {
          _showErrorToast(context, e);
        }
      }
    }
  }

  Future<void> _handleRescheduleDecision(MeetingItemModel item, bool accept) async {
    try {
      final meetingId = item.rawId ?? item.id;
      final endpoint = accept ? 'accept' : 'decline';
      try {
        await _dioClient.dio.post('${ApiConstants.baseUrl}/meetings/$meetingId/reschedule/$endpoint');
      } catch (err) {
        if (item.rescheduleId != null) {
          await _dioClient.dio.post('${ApiConstants.baseUrl}/meetings/$meetingId/reschedule/${item.rescheduleId}/$endpoint');
        } else {
          rethrow;
        }
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(accept ? 'Reschedule request accepted!' : 'Reschedule request declined.'),
          backgroundColor: accept ? Colors.green : Colors.orange,
        ),
      );
      context.read<MeetingsBloc>().add(FetchMyScheduledMeetingsEvent());
    } catch (e) {
      if (mounted) {
        _showErrorToast(context, e);
      }
    }
  }

  String _formatMeetingDate(String isoString) {
    try {
      final dt = DateTime.parse(isoString);
      const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return '${weekdays[dt.weekday - 1]} ${dt.day} ${months[dt.month - 1]}, ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return isoString;
    }
  }

  Widget _buildGoogleMeetBadge(BuildContext context, MeetingItemModel item) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0C4A6E).withValues(alpha: 0.4) : const Color(0xFFE0F2FE),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? const Color(0xFF0284C7).withValues(alpha: 0.4) : const Color(0xFFBAE6FD),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('📹 ', style: TextStyle(fontSize: 10)),
          Text(
            'Google Meet',
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.bold,
              color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMeetingCard(
    BuildContext context,
    AppStrings s,
    MeetingItemModel item, {
    bool isCalendarConnected = false,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final authState = context.watch<AuthBloc>().state;
    String currentUserName = '';
    String role = '';
    bool isTeamLead = false;
    if (authState is AuthenticatedState) {
      currentUserName = authState.userProfile.name;
      role = authState.userProfile.role.toLowerCase();
      final roleLabel = authState.userProfile.roleLabel.toLowerCase();
      if (role.contains('team lead') ||
          role.contains('team_lead') ||
          role.contains('team leader') ||
          role.contains('team_leader') ||
          role.contains('tl') ||
          roleLabel.contains('team lead') ||
          roleLabel.contains('team_lead') ||
          roleLabel.contains('team leader') ||
          roleLabel.contains('team_leader') ||
          roleLabel.contains('tl')) {
        isTeamLead = true;
      }
    }

    final isCancelled = item.isCancelled;
    final isPendingCompletion = item.isPendingCompletion;
    final isCompleted = item.isCompleted;

    DateTime? meetingStart;
    try {
      meetingStart = DateTime.parse(item.startsAt);
    } catch (_) {}
    final isPastMeeting = meetingStart != null && meetingStart.isBefore(DateTime.now());

    final isInvitee = !item.isOrganizer && (
      item.myResponse != null ||
      item.myRequired != null ||
      (currentUserName.isNotEmpty && item.invitees.any((i) => i.name.toLowerCase().trim() == currentUserName.toLowerCase().trim())) ||
      (role.contains('director') && item.invitees.any((i) => i.name.toLowerCase().trim() == 'test_dir')) ||
      (isTeamLead && item.invitees.any((i) => i.name.toLowerCase().trim() == 'test_tl'))
    );
    final isParticipant = item.isOrganizer || isInvitee;

    final showMeetingHappened = isPastMeeting && !isCancelled && !isCompleted && !isPendingCompletion;
    final isAttended = item.myAttended == true || _attendedMeetingIds.contains(item.id) || (item.rawId != null && _attendedMeetingIds.contains(item.rawId));
    final showRsvp = !isCancelled && !isCompleted && isInvitee && item.myResponse != null && item.myResponse!.toLowerCase() == 'pending';
    final canCancel = !isCancelled && !isCompleted && (item.isOrganizer || !isTeamLead);

    Color accentColor;
    if (isCancelled) {
      accentColor = const Color(0xFFDC2626);
    } else if (isCompleted) {
      accentColor = const Color(0xFF10B981);
    } else {
      accentColor = const Color(0xFF1E3A8A);
    }

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Left Accent Strip (Red for Cancelled, Green for Completed, Navy for Scheduled)
              Container(
                width: 4.5,
                color: accentColor,
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Meeting Title & Badges
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          Text(
                            item.title.isNotEmpty ? item.title : 'Untitled Meeting',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                            ),
                          ),
                          if (item.hasActiveGoogleMeet)
                            _buildGoogleMeetBadge(context, item),
                          if (item.isOneOnOne == true)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFEDD5),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFFFDBA74)),
                              ),
                              child: const Text(
                                '1:1 with Director',
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFFC2410C),
                                ),
                              ),
                            ),
                          if (isCancelled)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFEE2E2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                'Cancelled',
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFFDC2626),
                                ),
                              ),
                            )
                          else if (isPendingCompletion)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFEDD5),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                s.completionAwaitingApproval,
                                style: const TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF9A3412),
                                ),
                              ),
                            )
                          else if (isCompleted)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFFDCFCE7),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                'Completed',
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF166534),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),

                      // Time & Location
                      Row(
                        children: [
                          const Icon(Icons.access_time_rounded, size: 12, color: Colors.grey),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              '${_formatMeetingDate(item.startsAt)} · ${item.location ?? "Online"}',
                              style: TextStyle(
                                fontSize: 11,
                                color: isDark ? Colors.white60 : Colors.black54,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),

                      // Organizer
                      Text(
                        'Organizer: ${item.organizer?.isNotEmpty == true ? item.organizer! : (item.branchName ?? "Organizer")}',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.white.withValues(alpha: 0.6) : Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Invitee Chips
                      if (item.invitees.isNotEmpty)
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: item.invitees.map((inv) {
                            final resp = (inv.response ?? '').toLowerCase();
                            final isAccepted = resp == 'accepted';
                            final isDeclined = resp == 'declined';
                            final isOptional = inv.required == false;
                            final suffix = isAccepted ? ' ✓' : (isDeclined ? ' ✕' : '');
                            final label = '${inv.name}${isOptional ? " (opt)" : ""}$suffix';

                            Color chipBg;
                            Color chipText;

                            if (isAccepted) {
                              chipBg = isDark ? const Color(0xFF064E3B) : const Color(0xFFDCFCE7);
                              chipText = isDark ? const Color(0xFF86EFAC) : const Color(0xFF15803D);
                            } else if (isDeclined) {
                              chipBg = isDark ? const Color(0xFF7F1D1D).withValues(alpha: 0.4) : const Color(0xFFFEE2E2);
                              chipText = isDark ? const Color(0xFFFCA5A5) : const Color(0xFFDC2626);
                            } else {
                              chipBg = isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9);
                              chipText = isDark ? Colors.white70 : const Color(0xFF475569);
                            }

                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: chipBg,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                label,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: chipText,
                                ),
                              ),
                            );
                          }).toList(),
                        ),

                      // Reschedule Banner
                      if (item.hasReschedule) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF451A03).withValues(alpha: 0.4)
                                : const Color(0xFFFEF3C7).withValues(alpha: 0.7),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: const Color(0xFFF59E0B).withValues(alpha: 0.5),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.access_time_rounded, size: 13, color: Color(0xFFD97706)),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: RichText(
                                      text: TextSpan(
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: isDark ? const Color(0xFFFDE68A) : const Color(0xFF92400E),
                                        ),
                                        children: [
                                          TextSpan(
                                            text: '${item.rescheduleBy ?? "Someone"} requested a new time: ',
                                            style: const TextStyle(fontWeight: FontWeight.w600),
                                          ),
                                          TextSpan(
                                            text: _formatMeetingDate(item.rescheduleStart ?? ''),
                                            style: const TextStyle(fontWeight: FontWeight.bold),
                                          ),
                                          if (item.rescheduleNote != null && item.rescheduleNote!.trim().isNotEmpty)
                                            TextSpan(text: ' — ${item.rescheduleNote}'),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              if (item.isOrganizer && item.rescheduleIsMine == false && !isCancelled && !isCompleted) ...[
                                const SizedBox(height: 5),
                                Row(
                                  children: [
                                    const SizedBox(width: 19),
                                    InkWell(
                                      onTap: () => _handleRescheduleDecision(item, true),
                                      child: const Text(
                                        'Accept & move',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF16A34A),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    InkWell(
                                      onTap: () => _handleRescheduleDecision(item, false),
                                      child: const Text(
                                        'Decline',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFFDC2626),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],

                      // RSVP Options (Yes / No / Maybe)
                      if (showRsvp) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Text(
                              'RSVP:  ',
                              style: TextStyle(
                                fontSize: 11,
                                color: isDark ? Colors.white60 : Colors.grey.shade600,
                              ),
                            ),
                            InkWell(
                              onTap: () => _submitRsvp(item, 'accepted'),
                              child: const Text(
                                'Yes',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF16A34A),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            InkWell(
                              onTap: () => _submitRsvp(item, 'declined'),
                              child: const Text(
                                'No',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFFDC2626),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            InkWell(
                              onTap: () => _submitRsvp(item, 'tentative'),
                              child: Text(
                                'Maybe',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white70 : const Color(0xFF0F172A),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 10),

                      // Action Links Row
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 12,
                        runSpacing: 8,
                        children: [
                          if (isParticipant && !isCancelled && item.googleMeetUrl != null && item.googleMeetUrl!.trim().isNotEmpty)
                            ElevatedButton.icon(
                              onPressed: () async {
                                final meetUrl = item.googleMeetUrl;
                                if (meetUrl != null && meetUrl.trim().isNotEmpty) {
                                  final uri = Uri.tryParse(meetUrl.trim());
                                  if (uri != null) {
                                    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
                                    if (!launched && context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('Could not open $meetUrl')),
                                      );
                                    }
                                  }
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text(s.noMeetingLinkAvailable)),
                                  );
                                }
                              },
                              icon: const Icon(Icons.videocam_rounded, size: 14, color: Colors.white),
                              label: Text(
                                s.joinGoogleMeet,
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF2563EB),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                visualDensity: VisualDensity.compact,
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                              ),
                            ),
                          if (isParticipant && !isCancelled && item.hasActiveGoogleMeet)
                            InkWell(
                              onTap: () {
                                final meetUrl = item.googleMeetUrl ?? '';
                                if (meetUrl.trim().isNotEmpty) {
                                  Clipboard.setData(ClipboardData(text: meetUrl.trim()));
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(s.meetingLinkCopied),
                                      backgroundColor: const Color(0xFF16A34A),
                                      duration: const Duration(seconds: 2),
                                    ),
                                  );
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text(s.noMeetingLinkAvailable)),
                                  );
                                }
                              },
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.link_rounded, size: 14, color: Color(0xFF2563EB)),
                                  const SizedBox(width: 4),
                                  Text(
                                    s.needLink,
                                    style: const TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF2563EB),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          if (isInvitee && !isAttended && !isCancelled && !isCompleted)
                            InkWell(
                              onTap: () => _markAttended(item),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: const [
                                  Icon(Icons.people_alt_outlined, size: 14, color: Color(0xFF2563EB)),
                                  SizedBox(width: 4),
                                  Text(
                                    'Mark attended',
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF2563EB),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          if (isInvitee && !isCancelled && !isCompleted)
                            InkWell(
                              onTap: () => _showRescheduleDialog(item),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.access_time_rounded, size: 14, color: isDark ? Colors.white70 : const Color(0xFF475569)),
                                  SizedBox(width: 4),
                                  Text(
                                    'Request time change',
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.bold,
                                      color: isDark ? Colors.white70 : const Color(0xFF475569),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          if (showMeetingHappened)
                            InkWell(
                              onTap: () => _showMeetingHappenedDialog(item),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '✓ ${s.meetingHappenedButton}',
                                    style: const TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF16A34A),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          if (canCancel)
                            InkWell(
                              onTap: () => _cancelMeeting(item),
                              child: const Text(
                                'Cancel',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFFDC2626),
                                ),
                              ),
                            ),
                          InkWell(
                            onTap: () => _showMeetingReminder(context, item),
                            child: Text(
                              s.reminderButton,
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white70 : Colors.black87,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
