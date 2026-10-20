import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart'
    hide TextDirection;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:safir_passengers/models/address_models.dart';
import 'package:safir_passengers/pages/search_destination_place.dart';

const Color savedPrimaryAccent = Color(0xFF1B7A57);
const Color savedDarkTextColor = Color(0xFF0F172A);
const Color savedSecondaryTextColor = Color(0xFF64748B);
const Color savedPageBackground = Color(0xFFF7F9F8);
const Color savedIconBackground = Color(0xFFEFF5F1);

class SavedAddressesScreen extends StatefulWidget {
  const SavedAddressesScreen({super.key});

  @override
  State<SavedAddressesScreen> createState() =>
      _SavedAddressesScreenState();
}

class _SavedAddressesScreenState
    extends State<SavedAddressesScreen> {
  final TextEditingController _titleController =
      TextEditingController();

  bool _isSaving = false;

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  CollectionReference<Map<String, dynamic>>?
  get _savedAddressesCollection {
    final String? uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid == null || uid.isEmpty) {
      return null;
    }

    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('saved_addresses');
  }

  Future<void> _openAddAddressSheet({
    DocumentSnapshot<Map<String, dynamic>>? addressDocument,
  }) async {
    final Map<String, dynamic>? oldData = addressDocument?.data();

    String selectedType =
        oldData?['type']?.toString() ?? 'other';

    AddressModel? selectedAddress;

    _titleController.text =
        oldData?['title']?.toString() ?? '';

    if (oldData != null) {
      final double? latitude =
          _toDouble(oldData['latitude']);

      final double? longitude =
          _toDouble(oldData['longitude']);

      if (latitude != null && longitude != null) {
        selectedAddress = AddressModel(
          placeName: oldData['address']?.toString() ?? '',
          humanReadableAddress:
              oldData['address']?.toString() ?? '',
          latitudePosition: latitude,
          longitudePosition: longitude,
        );
      }
    }

    if (!mounted) return;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext sheetContext) {
        return StatefulBuilder(
          builder: (
            BuildContext context,
            StateSetter setSheetState,
          ) {
            final String addressText =
                selectedAddress?.humanReadableAddress ??
                    selectedAddress?.placeName ??
                    'آدرس را انتخاب کنید';

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(sheetContext)
                    .viewInsets
                    .bottom,
              ),
              child: Container(
                padding: const EdgeInsets.fromLTRB(
                  20,
                  12,
                  20,
                  22,
                ),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(28),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Center(
                      child: Container(
                        width: 42,
                        height: 4,
                        decoration: BoxDecoration(
                          color: const Color(0xFFD1D5DB),
                          borderRadius:
                              BorderRadius.circular(20),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: savedIconBackground,
                            borderRadius:
                                BorderRadius.circular(14),
                          ),
                          child: const Icon(
                            Icons.bookmark_add_outlined,
                            color: savedPrimaryAccent,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            addressDocument == null
                                ? 'افزودن آدرس'
                                : 'ویرایش آدرس',
                            style: const TextStyle(
                              color: savedDarkTextColor,
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            Navigator.pop(sheetContext);
                          },
                          icon: const Icon(
                            Icons.close_rounded,
                            color: savedSecondaryTextColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Expanded(
                          child: _buildTypeButton(
                            icon: Icons.home_outlined,
                            label: 'خانه',
                            isSelected: selectedType == 'home',
                            onTap: () {
                              setSheetState(() {
                                selectedType = 'home';

                                if (_titleController.text
                                    .trim()
                                    .isEmpty) {
                                  _titleController.text =
                                      'خانه';
                                }
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildTypeButton(
                            icon: Icons.business_outlined,
                            label: 'محل کار',
                            isSelected: selectedType == 'work',
                            onTap: () {
                              setSheetState(() {
                                selectedType = 'work';

                                if (_titleController.text
                                    .trim()
                                    .isEmpty) {
                                  _titleController.text =
                                      'محل کار';
                                }
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildTypeButton(
                            icon: Icons.star_outline_rounded,
                            label: 'دلخواه',
                            isSelected: selectedType == 'other',
                            onTap: () {
                              setSheetState(() {
                                selectedType = 'other';
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _titleController,
                      maxLength: 35,
                      style: const TextStyle(
                        color: savedDarkTextColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                      decoration: InputDecoration(
                        labelText: 'نام آدرس',
                        hintText: 'مثلاً خانه، محل کار یا دانشگاه',
                        counterText: '',
                        prefixIcon: const Icon(
                          Icons.edit_location_alt_outlined,
                          color: savedSecondaryTextColor,
                        ),
                        filled: true,
                        fillColor: savedPageBackground,
                        contentPadding:
                            const EdgeInsets.symmetric(
                          horizontal: 15,
                          vertical: 13,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(15),
                          borderSide: const BorderSide(
                            color: Color(0xFFE2E8F0),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(15),
                          borderSide: const BorderSide(
                            color: savedPrimaryAccent,
                            width: 1.4,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius:
                            BorderRadius.circular(15),
                        onTap: () async {
                          final dynamic result =
                              await Navigator.push(
                            sheetContext,
                            MaterialPageRoute(
                              builder: (_) =>
                                  const SearchDestinationPlace(),
                            ),
                          );

                          if (result is Map &&
                              result['address']
                                  is AddressModel) {
                            setSheetState(() {
                              selectedAddress =
                                  result['address']
                                      as AddressModel;
                            });
                          }
                        },
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: savedPageBackground,
                            borderRadius:
                                BorderRadius.circular(15),
                            border: Border.all(
                              color: selectedAddress == null
                                  ? const Color(0xFFE2E8F0)
                                  : savedPrimaryAccent,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 38,
                                height: 38,
                                decoration: BoxDecoration(
                                  color: selectedAddress == null
                                      ? const Color(
                                          0xFFE2E8F0,
                                        )
                                      : savedIconBackground,
                                  borderRadius:
                                      BorderRadius.circular(
                                    12,
                                  ),
                                ),
                                child: Icon(
                                  Icons.location_on_outlined,
                                  color: selectedAddress == null
                                      ? savedSecondaryTextColor
                                      : savedPrimaryAccent,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 11),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'موقعیت آدرس',
                                      style: TextStyle(
                                        color: savedDarkTextColor,
                                        fontSize: 13,
                                        fontWeight:
                                            FontWeight.w800,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      addressText,
                                      maxLines: 2,
                                      overflow:
                                          TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color:
                                            savedSecondaryTextColor,
                                        fontSize: 11,
                                        height: 1.35,
                                        fontWeight:
                                            FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Icon(
                                Icons.chevron_left_rounded,
                                color: Color(0xFF94A3B8),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isSaving
                            ? null
                            : () async {
                                final String title =
                                    _titleController.text
                                        .trim();

                                if (title.isEmpty) {
                                  _showMessage(
                                    'لطفاً نام آدرس را وارد کنید.',
                                    isError: true,
                                  );
                                  return;
                                }

                                if (selectedAddress == null ||
                                    selectedAddress!
                                            .latitudePosition ==
                                        null ||
                                    selectedAddress!
                                            .longitudePosition ==
                                        null) {
                                  _showMessage(
                                    'لطفاً موقعیت آدرس را انتخاب کنید.',
                                    isError: true,
                                  );
                                  return;
                                }

                                final collection =
                                    _savedAddressesCollection;

                                if (collection == null) {
                                  _showMessage(
                                    'ابتدا وارد حساب کاربری شوید.',
                                    isError: true,
                                  );
                                  return;
                                }

                                setSheetState(() {
                                  _isSaving = true;
                                });

                                try {
                                  final Map<String, dynamic>
                                      addressData = {
                                    'title': title,
                                    'type': selectedType,
                                    'address': selectedAddress!
                                            .humanReadableAddress ??
                                        selectedAddress!
                                            .placeName ??
                                        '',
                                    'placeName': selectedAddress!
                                            .placeName ??
                                        '',
                                    'latitude': selectedAddress!
                                        .latitudePosition,
                                    'longitude': selectedAddress!
                                        .longitudePosition,
                                    'updatedAt':
                                        FieldValue.serverTimestamp(),
                                  };

                                  if (addressDocument == null) {
                                    addressData['createdAt'] =
                                        FieldValue.serverTimestamp();

                                    await collection.add(
                                      addressData,
                                    );
                                  } else {
                                    await addressDocument.reference
                                        .update(addressData);
                                  }

                                  if (!mounted) return;

                                  Navigator.pop(sheetContext);

                                  _showMessage(
                                    addressDocument == null
                                        ? 'آدرس ذخیره شد.'
                                        : 'آدرس ویرایش شد.',
                                  );
                                } catch (e) {
                                  _showMessage(
                                    'ذخیره‌کردن آدرس انجام نشد.',
                                    isError: true,
                                  );
                                } finally {
                                  if (mounted) {
                                    setSheetState(() {
                                      _isSaving = false;
                                    });
                                  }
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: savedPrimaryAccent,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(15),
                          ),
                        ),
                        child: _isSaving
                            ? const SizedBox(
                                width: 21,
                                height: 21,
                                child:
                                    CircularProgressIndicator(
                                  strokeWidth: 2.3,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                'ذخیرهٔ آدرس',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    _titleController.clear();
  }

  Future<void> _deleteAddress(
    DocumentSnapshot<Map<String, dynamic>> addressDocument,
  ) async {
    final bool? shouldDelete = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          title: const Text(
            'حذف آدرس',
            style: TextStyle(
              color: savedDarkTextColor,
              fontWeight: FontWeight.w800,
            ),
          ),
          content: const Text(
            'آیا مطمئن هستید که می‌خواهید این آدرس را حذف کنید؟',
            style: TextStyle(
              color: savedSecondaryTextColor,
              fontSize: 14,
              height: 1.45,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text(
                'انصراف',
                style: TextStyle(
                  color: savedSecondaryTextColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade600,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('حذف'),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true) return;

    try {
      await addressDocument.reference.delete();

      if (!mounted) return;

      _showMessage('آدرس حذف شد.');
    } catch (e) {
      if (!mounted) return;

      _showMessage(
        'حذف‌کردن آدرس انجام نشد.',
        isError: true,
      );
    }
  }

  void _showMessage(
    String message, {
    bool isError = false,
  }) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError
            ? Colors.red.shade700
            : const Color(0xFF16A34A),
      ),
    );
  }

  double? _toDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(value?.toString() ?? '');
  }

  IconData _addressIcon(String type) {
    switch (type) {
      case 'home':
        return Icons.home_outlined;
      case 'work':
        return Icons.business_outlined;
      default:
        return Icons.star_outline_rounded;
    }
  }

  Color _addressColor(String type) {
    switch (type) {
      case 'home':
        return const Color(0xFF2563EB);
      case 'work':
        return const Color(0xFFF59E0B);
      default:
        return savedPrimaryAccent;
    }
  }

  String _addressTypeText(String type) {
    switch (type) {
      case 'home':
        return 'خانه';
      case 'work':
        return 'محل کار';
      default:
        return 'آدرس ذخیره‌شده';
    }
  }

  @override
  Widget build(BuildContext context) {
    final collection = _savedAddressesCollection;

    return Scaffold(
      backgroundColor: savedPageBackground,
      appBar: AppBar(
        backgroundColor: savedPageBackground,
        surfaceTintColor: savedPageBackground,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text(
          'آدرس‌های ذخیره‌شده',
          style: TextStyle(
            color: savedDarkTextColor,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: savedDarkTextColor,
            size: 19,
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          _openAddAddressSheet();
        },
        backgroundColor: savedPrimaryAccent,
        foregroundColor: Colors.white,
        elevation: 2,
        icon: const Icon(Icons.add_location_alt_outlined),
        label: const Text(
          'افزودن آدرس',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: collection == null
          ? const Center(
              child: Text(
                'ابتدا وارد حساب کاربری شوید.',
                style: TextStyle(
                  color: savedSecondaryTextColor,
                  fontSize: 14,
                ),
              ),
            )
          : StreamBuilder<
              QuerySnapshot<Map<String, dynamic>>
            >(
              stream: collection
                  .orderBy('updatedAt', descending: true)
                  .snapshots(),
              builder: (
                BuildContext context,
                AsyncSnapshot<
                        QuerySnapshot<Map<String, dynamic>>>
                    snapshot,
              ) {
                if (snapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: savedPrimaryAccent,
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        'دریافت آدرس‌ها انجام نشد.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: savedSecondaryTextColor,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  );
                }

                final List<
                    DocumentSnapshot<Map<String, dynamic>>
                > addresses = snapshot.data?.docs ?? [];

                if (addresses.isEmpty) {
                  return _buildEmptyState();
                }

                return ListView.separated(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(
                    16,
                    10,
                    16,
                    98,
                  ),
                  itemCount: addresses.length,
                  itemBuilder: (
                    BuildContext context,
                    int index,
                  ) {
                    final document = addresses[index];
                    final Map<String, dynamic> data =
                          document.data() ?? <String, dynamic>{};
                    final String type =
                        data['type']?.toString() ?? 'other';
                    final String title =
                        data['title']?.toString() ??
                            _addressTypeText(type);
                    final String address =
                        data['address']?.toString() ?? '';

                    return _buildAddressCard(
                      title: title,
                      subtitle: address,
                      type: type,
                      onEdit: () {
                        _openAddAddressSheet(
                          addressDocument: document,
                        );
                      },
                      onDelete: () {
                        _deleteAddress(document);
                      },
                    );
                  },
                  separatorBuilder: (
                    BuildContext context,
                    int index,
                  ) {
                    return const SizedBox(height: 11);
                  },
                );
              },
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 34),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 78,
              height: 78,
              decoration: BoxDecoration(
                color: savedIconBackground,
                borderRadius: BorderRadius.circular(25),
              ),
              child: const Icon(
                Icons.bookmark_border_rounded,
                color: savedPrimaryAccent,
                size: 39,
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'هنوز آدرسی ذخیره نکرده‌اید',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: savedDarkTextColor,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 7),
            const Text(
              'خانه، محل کار یا مکان‌های پرکاربرد خود را ذخیره کنید تا بعداً سریع‌تر مقصد انتخاب کنید.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: savedSecondaryTextColor,
                fontSize: 13,
                height: 1.5,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddressCard({
    required String title,
    required String subtitle,
    required String type,
    required VoidCallback onEdit,
    required VoidCallback onDelete,
  }) {
    final Color iconColor = _addressColor(type);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(19),
        border: Border.all(
          color: const Color(0xFFE5EBE7),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(19),
        child: InkWell(
          borderRadius: BorderRadius.circular(19),
          onTap: onEdit,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 13,
              vertical: 13,
            ),
            child: Row(
              children: [
                Container(
                  width: 45,
                  height: 45,
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    _addressIcon(type),
                    color: iconColor,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: savedDarkTextColor,
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle.isEmpty
                            ? 'بدون جزئیات آدرس'
                            : subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: savedSecondaryTextColor,
                          fontSize: 11,
                          height: 1.35,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(
                    Icons.more_vert_rounded,
                    color: savedSecondaryTextColor,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  onSelected: (String value) {
                    if (value == 'edit') {
                      onEdit();
                    } else if (value == 'delete') {
                      onDelete();
                    }
                  },
                  itemBuilder: (BuildContext context) {
                    return const [
                      PopupMenuItem<String>(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(
                              Icons.edit_outlined,
                              size: 19,
                            ),
                            SizedBox(width: 10),
                            Text('ویرایش'),
                          ],
                        ),
                      ),
                      PopupMenuItem<String>(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(
                              Icons.delete_outline_rounded,
                              color: Colors.red,
                              size: 19,
                            ),
                            SizedBox(width: 10),
                            Text(
                              'حذف',
                              style: TextStyle(
                                color: Colors.red,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ];
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTypeButton({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(
            vertical: 11,
          ),
          decoration: BoxDecoration(
            color: isSelected
                ? savedPrimaryAccent.withOpacity(0.10)
                : savedPageBackground,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected
                  ? savedPrimaryAccent
                  : const Color(0xFFE2E8F0),
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: isSelected
                    ? savedPrimaryAccent
                    : savedSecondaryTextColor,
                size: 21,
              ),
              const SizedBox(height: 5),
              Text(
                label,
                style: TextStyle(
                  color: isSelected
                      ? savedPrimaryAccent
                      : savedSecondaryTextColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
