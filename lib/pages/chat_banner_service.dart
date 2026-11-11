import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:easy_localization/easy_localization.dart';

import 'package:safir_passengers/theme/app_colors.dart';

// مسیر را مطابق پروژه‌ی خودتان تنظیم کنید
import 'package:safir_passengers/pages/chat_page.dart';

/// سرویس بنر پیام راننده (در کل اپ کار می‌کند)
class ChatBannerService {
  ChatBannerService._();
  static final ChatBannerService instance = ChatBannerService._();

  /// این کلید را به MaterialApp بدهید: navigatorKey: ChatBannerService.instance.navigatorKey
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  /// تعداد پیام‌های خوانده‌نشده (برای نقطه/عدد قرمز روی آیکن چت)
  final ValueNotifier<int> unread = ValueNotifier<int>(0);

  /// وقتی صفحه چت باز است true می‌شود تا بنر نمایش داده نشود
  bool isChatOpen = false;

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _sub;
  OverlayEntry? _entry;
  Timer? _timer;

  String _tripId = '';
  String _driverName = '';
  String? _driverPhoto;
  DateTime _startedAt = DateTime.now();

  /// وقتی سفر شروع شد (راننده قبول کرد) صدا بزنید
  void start({
    required String tripId,
    required String driverName,
    String? driverPhoto,
  }) {
    stop();
    _tripId = tripId;
    _driverName = driverName;
    _driverPhoto = driverPhoto;
    _startedAt = DateTime.now();
    unread.value = 0;

    _sub = FirebaseFirestore.instance
        .collection('rides')
        .doc(tripId)
        .collection('chats')
        .snapshots()
        .listen(_onSnapshot, onError: (e) {
      debugPrint('ChatBanner stream error: $e');
    });
  }

  /// وقتی سفر تمام یا لغو شد صدا بزنید
  void stop() {
    _sub?.cancel();
    _sub = null;
    _hide();
    unread.value = 0;
  }

  void markAllRead() {
    unread.value = 0;
    _hide();
  }

  void _onSnapshot(QuerySnapshot<Map<String, dynamic>> snap) {
    final String myId = FirebaseAuth.instance.currentUser?.uid ?? '';

    for (final change in snap.docChanges) {
      if (change.type != DocumentChangeType.added) continue;

      final doc = change.doc;
      if (doc.metadata.hasPendingWrites) continue;

      final data = doc.data();
      if (data == null) continue;

      final String senderId = data['senderId']?.toString().trim() ?? '';
      final String senderType =
          data['senderType']?.toString().trim().toLowerCase() ?? '';
      if (senderId == myId || senderType == 'passenger') continue;

      // پیام‌های قدیمی (قبل از شروع گوش دادن) را نشان نده
      final Object? ts = data['timestamp'];
      if (ts is! Timestamp) continue;
      if (ts.toDate().isBefore(_startedAt.subtract(const Duration(seconds: 5)))) {
        continue;
      }

      final String message = data['message']?.toString().trim() ?? '';
      if (message.isEmpty || isChatOpen) continue;

      unread.value++;
      _show(message);
    }
  }

  void _show(String message) {
    final OverlayState? overlay = navigatorKey.currentState?.overlay;
    if (overlay == null) return;

    _hide();
    HapticFeedback.mediumImpact();

    _entry = OverlayEntry(
      builder: (_) => _ChatBanner(
        driverName: _driverName,
        message: message,
        photo: _driverPhoto,
        onTap: _openChat,
        onDismiss: _hide,
      ),
    );
    overlay.insert(_entry!);

    _timer = Timer(const Duration(seconds: 6), _hide);
  }

  void _hide() {
    _timer?.cancel();
    _timer = null;
    _entry?.remove();
    _entry = null;
  }

  void _openChat() {
    _hide();
    final NavigatorState? nav = navigatorKey.currentState;
    if (nav == null || isChatOpen) return;

    nav.push(
      MaterialPageRoute(
        builder: (_) => ChatPage(
          tripId: _tripId,
          driverName: _driverName,
          driverPhoto: _driverPhoto,
        ),
      ),
    );
  }
}

/// این ویجت را دور شیت «سفر فعال» بگذارید؛
/// تا وقتی شیت روی صفحه است گوش دادن به پیام‌های راننده فعال است.
class ChatBannerScope extends StatefulWidget {
  final String tripId;
  final String driverName;
  final String? driverPhoto;
  final Widget child;

  const ChatBannerScope({
    super.key,
    required this.tripId,
    required this.driverName,
    this.driverPhoto,
    required this.child,
  });

  @override
  State<ChatBannerScope> createState() => _ChatBannerScopeState();
}

class _ChatBannerScopeState extends State<ChatBannerScope> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _start());
  }

  @override
  void didUpdateWidget(covariant ChatBannerScope oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.tripId != widget.tripId) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _start());
    }
  }

  void _start() {
    if (!mounted || widget.tripId.trim().isEmpty) return;
    ChatBannerService.instance.start(
      tripId: widget.tripId,
      driverName: widget.driverName,
      driverPhoto: widget.driverPhoto,
    );
  }

  @override
  void dispose() {
    Future.microtask(() => ChatBannerService.instance.stop());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

class _ChatBanner extends StatefulWidget {
  final String driverName;
  final String message;
  final String? photo;
  final VoidCallback onTap;
  final VoidCallback onDismiss;

  const _ChatBanner({
    required this.driverName,
    required this.message,
    required this.photo,
    required this.onTap,
    required this.onDismiss,
  });

  @override
  State<_ChatBanner> createState() => _ChatBannerState();
}

class _ChatBannerState extends State<_ChatBanner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 280),
  )..forward();

  // ✅ کلید ثابت: قبلاً UniqueKey داخل build ساخته می‌شد و با هر rebuild
  // (مثلاً عوض شدن تم) ویجت از نو ساخته می‌شد.
  final Key _dismissKey = UniqueKey();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String get _title {
    if (widget.driverName.isNotEmpty) return widget.driverName;
    final String v = 'driver_default_name'.tr();
    return (v.isEmpty || v == 'driver_default_name') ? 'راننده' : v;
  }

  @override
  Widget build(BuildContext context) {
    final String? photo = widget.photo?.trim();
    final bool hasPhoto = photo != null && photo.isNotEmpty;

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, -1.5),
            end: Offset.zero,
          ).animate(
            CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
          ),
          child: Dismissible(
            key: _dismissKey,
            direction: DismissDirection.up,
            onDismissed: (_) => widget.onDismiss(),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
              child: Material(
                color: AppColors.cardBgLight,
                elevation: 10,
                shadowColor:
                    Colors.black.withOpacity(AppColors.isDark ? 0.6 : 0.25),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(color: AppColors.fieldBorder),
                ),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: widget.onTap,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        // آواتار با حلقهٔ برند
                        Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color:
                                  AppColors.primaryBrand.withOpacity(0.45),
                              width: 2,
                            ),
                          ),
                          child: CircleAvatar(
                            radius: 21,
                            backgroundColor: AppColors.cardBackground,
                            backgroundImage:
                                hasPhoto ? NetworkImage(photo) : null,
                            child: hasPhoto
                                ? null
                                : Icon(
                                    Icons.person_rounded,
                                    color: AppColors.primaryBrand,
                                  ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                widget.message,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 13,
                                  height: 1.35,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        // آیکن چت در کادر آبی (آبی = ارتباط/پیام در کل اپ)
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: AppColors.originBlue.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.chat_bubble_rounded,
                            color: AppColors.originBlue,
                            size: 20,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
