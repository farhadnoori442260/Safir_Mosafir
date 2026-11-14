import 'dart:ui' as ui;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:safir_passengers/theme/app_colors.dart';
import 'chat_banner_service.dart';

class ChatPage extends StatefulWidget {
  final String tripId;
  final String driverName;
  final String? driverPhoto;

  const ChatPage({
    super.key,
    required this.tripId,
    required this.driverName,
    this.driverPhoto,
  });

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  /// پاسخ‌های سریع مسافر؛ اگر نمی‌خواهید، false کنید.
  static const bool _showQuickReplies = true;

  /// ترجمه با متن جایگزین (اگر کلید پیدا نشد، easy_localization خود کلید را برمی‌گرداند)
  String _trOr(String key, String fallback) {
    final String v = key.tr();
    return (v.isEmpty || v == key) ? fallback : v;
  }

  final TextEditingController _messageController =
      TextEditingController();

  final ScrollController _scrollController =
      ScrollController();

  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  final FirebaseAuth _auth =
      FirebaseAuth.instance;

  bool _isSending = false;

  CollectionReference<Map<String, dynamic>>
      get _chatCollection {
    return _firestore
        .collection('rides')
        .doc(widget.tripId)
        .collection('chats');
  }

  String get _currentPassengerId {
    return _auth.currentUser?.uid ?? '';
  }

  @override
  void initState() {
    super.initState();
    // وقتی چت باز است بنر نمایش داده نشود و پیام‌ها خوانده شوند
    ChatBannerService.instance.isChatOpen = true;
    ChatBannerService.instance.markAllRead();
  }

  @override
  void dispose() {
    ChatBannerService.instance.isChatOpen = false;
    ChatBannerService.instance.markAllRead();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> sendMessage() async {
    final String text =
        _messageController.text.trim();

    final String passengerId =
        _currentPassengerId;

    if (text.isEmpty ||
        passengerId.isEmpty ||
        widget.tripId.trim().isEmpty ||
        _isSending) {
      return;
    }


    setState(() {
      _isSending = true;
    });

    _messageController.clear();

    try {
      await _chatCollection.add({
        'senderId': passengerId,
        'senderType': 'passenger',
        'message': text,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (error) {
      debugPrint(
        'Passenger chat Firebase error: '
        '${error.code} - ${error.message}',
      );

      if (!mounted) return;

      _messageController.text = text;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error.message ??
                'error_occurred'.tr(),
          ),
          backgroundColor: AppColors.danger,
        ),
      );
    } catch (error) {
      debugPrint(
        'Passenger chat sending error: $error',
      );

      if (!mounted) return;

      _messageController.text = text;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'error_occurred'.tr(),
          ),
          backgroundColor: AppColors.danger,
        ),
      );
    } finally {
      if (!mounted) return;

      setState(() {
        _isSending = false;
      });
    }
  }

  DateTime _getMessageDate(
    QueryDocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final Map<String, dynamic> data = document.data();
    final Object? value = data['timestamp'];

    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) {
      return DateTime.tryParse(value) ??
          DateTime.fromMillisecondsSinceEpoch(0);
    }

    // پیامی که هنوز به سرور نرسیده، جدیدترین است
    if (document.metadata.hasPendingWrites) {
      return DateTime.now();
    }

    return DateTime.fromMillisecondsSinceEpoch(0);
  }

  List<QueryDocumentSnapshot<Map<String, dynamic>>>
      _sortMessages(
    List<QueryDocumentSnapshot<Map<String, dynamic>>>
        documents,
  ) {
    final List<QueryDocumentSnapshot<Map<String, dynamic>>>
        sortedDocuments =
        List<QueryDocumentSnapshot<Map<String, dynamic>>>.from(
      documents,
    );

    sortedDocuments.sort((a, b) {
      return _getMessageDate(a).compareTo(
        _getMessageDate(b),
      );
    });

    return sortedDocuments;
  }

  String _formatTimestamp(Object? value) {
    DateTime? date;

    if (value is Timestamp) {
      date = value.toDate();
    } else if (value is DateTime) {
      date = value;
    } else if (value is String) {
      date = DateTime.tryParse(value);
    }

    if (date == null) {
      return 'chat_time_now'.tr();
    }

    return DateFormat('HH:mm').format(date);
  }

  bool _isMyMessage(
    Map<String, dynamic> data,
  ) {
    final String senderId =
        data['senderId']?.toString().trim() ?? '';

    final String senderType =
        data['senderType']?.toString().trim().toLowerCase() ??
            '';

    return senderId == _currentPassengerId ||
        senderType == 'passenger';
  }

  @override
  Widget build(BuildContext context) {
    final String displayName =
        widget.driverName.trim().isNotEmpty
            ? widget.driverName.trim()
            : 'chat_driver_default_name'.tr();

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: _buildAppBar(displayName),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: _buildMessages(),
            ),
            if (_showQuickReplies && widget.tripId.trim().isNotEmpty)
              _buildQuickReplies(),
            _buildMessageComposer(),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(
    String displayName,
  ) {
    return AppBar(
      backgroundColor: AppColors.cardBgLight,
      surfaceTintColor: AppColors.cardBgLight,
      foregroundColor: AppColors.textPrimary,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleSpacing: 0,
      leading: IconButton(
        onPressed: () => Navigator.pop(context),
        icon: const Icon(
          Icons.arrow_back_ios_new_rounded,
          size: 20,
        ),
      ),
      title: Row(
        children: [
          _buildDriverAvatar(
            size: 42,
            borderWidth: 1.5,
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Text(
              displayName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          tooltip: 'close_tooltip'.tr(),
          onPressed: () => Navigator.pop(context),
          icon: Icon(
            Icons.close_rounded,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(width: 4),
      ],
    );
  }

  Widget _buildDriverAvatar({
    required double size,
    required double borderWidth,
  }) {
    final String? photo =
        widget.driverPhoto?.trim();

    final bool hasPhoto =
        photo != null && photo.isNotEmpty;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.cardBackground,
        border: Border.all(
          color: AppColors.primaryBrand.withOpacity(0.2),
          width: borderWidth,
        ),
      ),
      child: ClipOval(
        child: hasPhoto
            ? Image.network(
                photo,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) {
                  return Icon(
                    Icons.person_rounded,
                    color: AppColors.primaryBrand,
                    size: 24,
                  );
                },
                loadingBuilder: (
                  context,
                  child,
                  loadingProgress,
                ) {
                  if (loadingProgress == null) {
                    return child;
                  }

                  return Center(
                    child: SizedBox(
                      width: 17,
                      height: 17,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.primaryBrand,
                      ),
                    ),
                  );
                },
              )
            : Icon(
                Icons.person_rounded,
                color: AppColors.primaryBrand,
                size: size * 0.55,
              ),
      ),
    );
  }

  Widget _buildMessages() {
    if (widget.tripId.trim().isEmpty) {
      return _buildErrorState(
        'chat_error_no_trip_id'.tr(),
      );
    }

    return StreamBuilder<
        QuerySnapshot<Map<String, dynamic>>>(
      // عمداً orderBy حذف شده است.
      // پیام‌ها در Dart مرتب می‌شوند تا پیام‌های قدیمی
      // یا timestamp های null باعث خطا نشوند.
      stream: _chatCollection.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState ==
            ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(
              color: AppColors.primaryBrand,
            ),
          );
        }

        if (snapshot.hasError) {
          debugPrint(
            'Passenger chat stream error: '
            '${snapshot.error}',
          );

          return _buildErrorState(
            'chat_error_loading_messages'.tr(),
          );
        }

        final List<
            QueryDocumentSnapshot<Map<String, dynamic>>>
            messages = _sortMessages(
          snapshot.data?.docs ?? <
              QueryDocumentSnapshot<Map<String, dynamic>>>[],
        );

        if (messages.isEmpty) {
          return _buildEmptyState();
        }

        return ListView.builder(
          controller: _scrollController,
          reverse: true,
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(
            14,
            18,
            14,
            18,
          ),
          itemCount: messages.length,
          itemBuilder: (context, index) {
            final QueryDocumentSnapshot<Map<String, dynamic>> doc =
                messages[messages.length - 1 - index];

            return _buildMessageBubble(
              doc.data(),
              pending: doc.metadata.hasPendingWrites,
            );
          },
        );
      },
    );
  }

  Widget _buildMessageBubble(
    Map<String, dynamic> data, {
    bool pending = false,
  }) {
    final String message =
        data['message']?.toString().trim() ?? '';

    if (message.isEmpty) {
      return const SizedBox.shrink();
    }

    final bool isMe = _isMyMessage(data);

    return Align(
      alignment: isMe
          ? Alignment.centerRight
          : Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          mainAxisAlignment: isMe
              ? MainAxisAlignment.end
              : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (!isMe) ...[
              _buildDriverAvatar(
                size: 30,
                borderWidth: 1,
              ),
              const SizedBox(width: 7),
            ],
            Flexible(
              child: Container(
                constraints: BoxConstraints(
                  maxWidth:
                      MediaQuery.of(context).size.width *
                          0.76,
                ),
                padding: const EdgeInsets.fromLTRB(
                  14,
                  10,
                  12,
                  8,
                ),
                decoration: BoxDecoration(
                  color: isMe
                      ? AppColors.primaryButton
                      : AppColors.cardBgLight,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(18),
                    topRight: const Radius.circular(18),
                    bottomLeft: Radius.circular(
                      isMe ? 18 : 5,
                    ),
                    bottomRight: Radius.circular(
                      isMe ? 5 : 18,
                    ),
                  ),
                  border: isMe
                      ? null
                      : Border.all(
                          color: AppColors.fieldBorder,
                        ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.035),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: isMe
                      ? CrossAxisAlignment.end
                      : CrossAxisAlignment.start,
                  children: [
                    Text(
                      message,
                      textDirection: ui.TextDirection.rtl,
                      style: TextStyle(
                        color: isMe
                            ? AppColors.buttonText
                            : AppColors.textPrimary,
                        fontSize: 14,
                        height: 1.45,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _formatTimestamp(
                            data['timestamp'],
                          ),
                          textDirection: ui.TextDirection.ltr,
                          style: TextStyle(
                            color: isMe
                                ? AppColors.buttonText.withOpacity(0.75)
                                : AppColors.textSecondary,
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (isMe) ...[
                          const SizedBox(width: 4),
                          // ساعت = هنوز به سرور نرسیده، دو تیک = ارسال شد
                          Icon(
                            pending
                                ? Icons.schedule_rounded
                                : Icons.done_all_rounded,
                            size: 14,
                            color: AppColors.buttonText.withOpacity(0.75),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            Container(
              width: 82,
              height: 82,
              decoration: BoxDecoration(
                color: AppColors.primaryBrand.withOpacity(0.09),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.forum_outlined,
                size: 42,
                color: AppColors.primaryBrand,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'chat_no_messages_yet'.tr(),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 7),
            Text(
              'chat_empty_subtitle'.tr(),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            Icon(
              Icons.cloud_off_rounded,
              size: 54,
              color: AppColors.iconSecondary,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// پاسخ‌های آمادهٔ مسافر (یک لمس = ارسال)
  Widget _buildQuickReplies() {
    final List<String> replies = <String>[
      _trOr('chat_quick_here', 'من اینجا هستم'),
      _trOr('chat_quick_coming', 'دارم می‌آیم'),
      _trOr('chat_quick_wait', 'لطفاً چند دقیقه صبر کنید'),
      _trOr('chat_quick_thanks', 'ممنون'),
    ];

    return Container(
      height: 46,
      color: AppColors.cardBgLight,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
        itemCount: replies.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (BuildContext context, int index) {
          return InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: _isSending
                ? null
                : () {
                    _messageController.text = replies[index];
                    sendMessage();
                  },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppColors.primaryBrand.withOpacity(0.25),
                ),
              ),
              child: Text(
                replies[index],
                style: TextStyle(
                  color: AppColors.primaryBrand,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMessageComposer() {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        12,
        10,
        12,
        10,
      ),
      decoration: BoxDecoration(
        color: AppColors.cardBgLight,
        border: Border(
          top: BorderSide(
            color: AppColors.fieldBorder,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 14,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.backgroundLight,
                borderRadius: BorderRadius.circular(23),
                border: Border.all(
                  color: AppColors.fieldBorder,
                ),
              ),
              child: TextField(
                controller: _messageController,
                minLines: 1,
                maxLines: 4,
                textDirection: ui.TextDirection.rtl,
                textInputAction:
                    TextInputAction.newline,
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                  height: 1.35,
                ),
                decoration: InputDecoration(
                  hintText:
                      'chat_type_message_hint'.tr(),
                  hintStyle: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                  border: InputBorder.none,
                  contentPadding:
                      const EdgeInsets.symmetric(
                    horizontal: 17,
                    vertical: 11,
                  ),
                ),
                onSubmitted: (_) {
                  if (!_isSending) {
                    sendMessage();
                  }
                },
              ),
            ),
          ),
          const SizedBox(width: 8),
          AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: _isSending
                  ? AppColors.handle
                  : AppColors.primaryButton,
              shape: BoxShape.circle,
            ),
            child: Material(
              color: Colors.transparent,
              shape: const CircleBorder(),
              child: InkWell(
                onTap: _isSending ? null : sendMessage,
                customBorder: const CircleBorder(),
                child: Center(
                  child: _isSending
                      ? SizedBox(
                          width: 19,
                          height: 19,
                          child:
                              CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.buttonText,
                          ),
                        )
                      : Icon(
                          Icons.send_rounded,
                          color: AppColors.buttonText,
                          size: 21,
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
