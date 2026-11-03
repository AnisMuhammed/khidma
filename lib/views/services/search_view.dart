import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/localization/app_language_manager.dart';
import '../../core/localization/app_strings.dart';
import '../../core/routes/app_routes.dart';
import '../../viewmodels/search_viewmodel.dart';

/// SearchView (MVVM)
/// View -> SearchViewModel -> ServiceRepository -> API / Remote DB -> ServiceModel -> نتائج البحث
/// الشاشة الموحّدة الوحيدة للبحث — تُفتح من مسار /search ومن الصفحة الرئيسية.
class SearchView extends StatefulWidget {
  const SearchView({super.key});

  @override
  State<SearchView> createState() => _SearchViewState();
}

class _SearchViewState extends State<SearchView> {
  final TextEditingController _controller = TextEditingController();
  late final SearchViewModel _viewModel;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _viewModel = SearchViewModel();
    _viewModel.search('');
  }

  void _onSearchChanged(String val) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      if (mounted) {
        _viewModel.search(val, saveToRecent: false);
      }
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isRtl = AppLanguageManager.currentDirection == TextDirection.rtl;

    return Scaffold(
        appBar: AppBar(
          title: Text(AppStrings.t('البحث عن خدمة', 'Search for a service')),
          centerTitle: true,
        ),
        body: ListenableBuilder(
          listenable: _viewModel,
          builder: (context, _) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: TextField(
                    controller: _controller,
                    textAlign: isRtl ? TextAlign.right : TextAlign.left,
                    onChanged: _onSearchChanged,
                    onSubmitted: (val) {
                      _debounce?.cancel();
                      _viewModel.search(val, saveToRecent: true);
                    },
                    decoration: InputDecoration(
                      hintText: AppStrings.tr('search_hint'),
                      prefixIcon: const Icon(Icons.search_rounded),
                      suffixIcon: _controller.text.isNotEmpty
                          ? IconButton(
                              onPressed: () {
                                _debounce?.cancel();
                                _controller.clear();
                                _viewModel.search('', saveToRecent: false);
                              },
                              icon: const Icon(Icons.clear_rounded),
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                  ),
                ),

                // الكلمات المفتاحية الأخيرة من Local DB
                if (_viewModel.currentQuery.isEmpty &&
                    _viewModel.recentSearches.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          AppStrings.t(
                            'عمليات البحث الأخيرة',
                            'Recent searches',
                          ),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        TextButton(
                          onPressed: () => _viewModel.clearRecentSearches(),
                          child: Text(AppStrings.t('مسح', 'Clear')),
                        ),
                      ],
                    ),
                  ),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: _viewModel.recentSearches.map((term) {
                        return Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: ActionChip(
                            label: Text(term),
                            onPressed: () {
                              _debounce?.cancel();
                              _controller.text = term;
                              _viewModel.search(term);
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],

                Expanded(
                  child: _viewModel.isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _viewModel.results.isEmpty
                      ? Center(
                          child: Text(
                            AppStrings.t(
                              'لا توجد خدمات مطابقة',
                              'No matching services',
                            ),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _viewModel.results.length,
                          itemBuilder: (context, index) {
                            final service = _viewModel.results[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 10),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: Theme.of(
                                    context,
                                  ).colorScheme.primary.withValues(alpha: 0.1),
                                  child: Icon(
                                    Icons.build_rounded,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                  ),
                                ),
                                title: Text(
                                  service.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Text(
                                  '${service.category} • ⭐ ${service.rating}',
                                ),
                                trailing: Icon(
                                  isRtl
                                      ? Icons.arrow_back_ios_new_rounded
                                      : Icons.arrow_forward_ios_rounded,
                                  size: 16,
                                ),
                                onTap: () {
                                  Navigator.pushNamed(
                                    context,
                                    AppRoutes.serviceDetails,
                                    arguments: service.name,
                                  );
                                },
                              ),
                            );
                          },
                        ),
                ),
              ],
            );
          },
        ),
      );
  }
}
