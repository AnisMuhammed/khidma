import 'package:flutter/material.dart';
import '../../core/localization/app_strings.dart';
import '../../core/routes/app_routes.dart';
import '../../data/categories_data.dart';
import '../../repositories/service_repository.dart';

class ServicesView extends StatelessWidget {
  const ServicesView({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.t('الخدمات المنزلية', 'Home Services')),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () {
              Navigator.pushNamed(
                context,
                AppRoutes.search,
              );
            },
            icon: const Icon(Icons.search_rounded),
          ),
        ],
      ),
      body: ValueListenableBuilder<List<ServiceCategory>>(
        valueListenable: ServiceRepository.categoriesNotifier,
        builder: (context, categories, _) {
          return GridView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: categories.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.95,
            ),
            itemBuilder: (context, index) {
              final category = categories[index];

              return Card(
                elevation: 0,
                child: InkWell(
                  borderRadius: BorderRadius.circular(18),
                  onTap: () {
                    Navigator.pushNamed(
                      context,
                      AppRoutes.serviceDetails,
                      arguments: category.name,
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 65,
                          height: 65,
                          decoration: BoxDecoration(
                            color: colors.primary.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            category.icon,
                            size: 32,
                            color: colors.primary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          category.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
