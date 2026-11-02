import 'package:flutter/material.dart';
import '../../core/localization/app_strings.dart';
import '../../core/services/permission_service.dart';
import '../../core/utils/app_image_helper.dart';
import '../../data/user_session.dart';
import '../../models/provider_model.dart';

class ProviderPreviousWorkView extends StatefulWidget {
  const ProviderPreviousWorkView({super.key});

  @override
  State<ProviderPreviousWorkView> createState() =>
      _ProviderPreviousWorkViewState();
}

class _ProviderPreviousWorkViewState extends State<ProviderPreviousWorkView> {
  List<PreviousWork> get _works => UserSession.currentProvider.previousWorks;

  void _showAddWorkSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => const _AddWorkSheet(),
    ).then((newWork) async {
      if (newWork != null && newWork is PreviousWork) {
        setState(() {
          UserSession.currentProvider.previousWorks.insert(0, newWork);
        });
        await UserSession.saveProviderFullProfile(UserSession.currentProvider);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppStrings.t(
                  'تمت إضافة العمل بنجاح وحفظه',
                  'The work was added and saved successfully',
                ),
              ),
            ),
          );
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(AppStrings.t('أعمالي السابقة', 'My Previous Work')),
          centerTitle: true,
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _showAddWorkSheet,
          icon: const Icon(Icons.add_photo_alternate_rounded),
          label: Text(AppStrings.t('إضافة عمل', 'Add work')),
        ),
        body: _works.isEmpty
            ? Center(
                child: Text(
                  AppStrings.t(
                    'لا توجد أعمال سابقة مضافة',
                    'No previous work added yet',
                  ),
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                itemCount: _works.length,
                itemBuilder: (context, index) {
                  final work = _works[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            work.title,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            work.description,
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  children: [
                                    Text(
                                      AppStrings.t('قبل العمل', 'Before'),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    _buildImage(work.beforeImagePath),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  children: [
                                    Text(
                                      AppStrings.t('بعد العمل', 'After'),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                        color: Colors.green,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    _buildImage(work.afterImagePath),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      );
  }

  Widget _buildImage(String? path) {
    return AppImageHelper.buildImage(
      path: path,
      height: 125,
      width: double.infinity,
      fit: BoxFit.cover,
      borderRadius: BorderRadius.circular(12),
      placeholder: _placeholderImage(),
      // الارتفاع ثابت 125، فنفكّ الترميز بنفس الدقة الفيزيائية بدل مقاس الصورة
      // الكامل — صور الأعمال السابقة تُلتقط بالكاميرا فتكون كبيرة جداً.
      cacheHeight: (125 * MediaQuery.devicePixelRatioOf(context)).round(),
    );
  }

  Widget _placeholderImage() {
    return Container(
      height: 125,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Icon(Icons.image_outlined, color: Colors.grey, size: 40),
    );
  }
}

class _AddWorkSheet extends StatefulWidget {
  const _AddWorkSheet();

  @override
  State<_AddWorkSheet> createState() => _AddWorkSheetState();
}

class _AddWorkSheetState extends State<_AddWorkSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  String? _beforeImagePath;
  String? _afterImagePath;

  Future<void> _pickImage(bool isBefore) async {
    final pickedImage = await PermissionService.pickImage(context);
    if (pickedImage != null && mounted) {
      setState(() {
        if (isBefore) {
          _beforeImagePath = pickedImage.path;
        } else {
          _afterImagePath = pickedImage.path;
        }
      });
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final keyboardSpace = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
        padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + keyboardSpace),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  AppStrings.t('إضافة عمل سابق', 'Add Previous Work'),
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 18),
                TextFormField(
                  controller: _titleController,
                  decoration: InputDecoration(
                    labelText: AppStrings.t('اسم/نوع العمل', 'Work name/type'),
                    hintText: AppStrings.t(
                      'مثال: صيانة سباكة الحمام',
                      'Example: Bathroom plumbing maintenance',
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? AppStrings.t('يرجى كتابة اسم العمل', 'Please enter the work name')
                      : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _descController,
                  maxLines: 2,
                  decoration: InputDecoration(
                    labelText: AppStrings.t('وصف مختصر', 'Short description'),
                    hintText: AppStrings.t(
                      'وصف للعمل الذي قمت بإنجازه...',
                      'A description of the work you completed...',
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? AppStrings.t('يرجى كتابة الوصف', 'Please enter a description')
                      : null,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          Text(
                            AppStrings.t('صورة قبل العمل', 'Before work photo'),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          InkWell(
                            onTap: () => _pickImage(true),
                            borderRadius: BorderRadius.circular(14),
                            child: Container(
                              height: 110,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: Colors.grey.shade300),
                                image:
                                    AppImageHelper.getImageProvider(
                                          _beforeImagePath,
                                        ) !=
                                        null
                                    ? DecorationImage(
                                        image: AppImageHelper.getImageProvider(
                                          _beforeImagePath,
                                        )!,
                                        fit: BoxFit.cover,
                                      )
                                    : null,
                              ),
                              child: _beforeImagePath == null
                                  ? Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        const Icon(
                                          Icons.add_a_photo_outlined,
                                          size: 28,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          AppStrings.t(
                                            'اختر صورة',
                                            'Choose a photo',
                                          ),
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                      ],
                                    )
                                  : null,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        children: [
                          Text(
                            AppStrings.t('صورة بعد العمل', 'After work photo'),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                          const SizedBox(height: 8),
                          InkWell(
                            onTap: () => _pickImage(false),
                            borderRadius: BorderRadius.circular(14),
                            child: Container(
                              height: 110,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: Colors.grey.shade300),
                                image:
                                    AppImageHelper.getImageProvider(
                                          _afterImagePath,
                                        ) !=
                                        null
                                    ? DecorationImage(
                                        image: AppImageHelper.getImageProvider(
                                          _afterImagePath,
                                        )!,
                                        fit: BoxFit.cover,
                                      )
                                    : null,
                              ),
                              child: _afterImagePath == null
                                  ? Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        const Icon(
                                          Icons.add_a_photo_outlined,
                                          size: 28,
                                          color: Colors.green,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          AppStrings.t(
                                            'اختر صورة',
                                            'Choose a photo',
                                          ),
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                      ],
                                    )
                                  : null,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: () {
                    if (_formKey.currentState?.validate() == true) {
                      Navigator.pop(
                        context,
                        PreviousWork(
                          title: _titleController.text.trim(),
                          description: _descController.text.trim(),
                          beforeImagePath: _beforeImagePath,
                          afterImagePath: _afterImagePath,
                        ),
                      );
                    }
                  },
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    AppStrings.t('حفظ العمل', 'Save Work'),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
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
