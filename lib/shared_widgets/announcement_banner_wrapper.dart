import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../modules/announcements/bloc/announcements_bloc.dart';
import '../modules/announcements/bloc/announcements_event.dart';
import '../modules/announcements/bloc/announcements_state.dart';
import '../modules/announcements/widgets/announcement_ticker_bar.dart';

/// Wraps any screen's body to automatically fetch active announcements
/// and maintain the horizontal scrolling announcement banner at the start of the body.
class AnnouncementBannerWrapper extends StatefulWidget {
  final Widget child;

  const AnnouncementBannerWrapper({
    super.key,
    required this.child,
  });

  @override
  State<AnnouncementBannerWrapper> createState() => _AnnouncementBannerWrapperState();
}

class _AnnouncementBannerWrapperState extends State<AnnouncementBannerWrapper> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<AnnouncementsBloc>().add(const FetchActiveAnnouncementsEvent());
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        BlocBuilder<AnnouncementsBloc, AnnouncementsState>(
          builder: (context, aState) {
            if (aState is AnnouncementsLoadedState && aState.activeAnnouncements.isNotEmpty) {
              return AnnouncementTickerBar(announcements: aState.activeAnnouncements);
            }
            return const SizedBox.shrink();
          },
        ),
        Expanded(child: widget.child),
      ],
    );
  }
}
