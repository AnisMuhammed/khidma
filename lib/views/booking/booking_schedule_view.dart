import 'package:flutter/material.dart';
import '../../core/localization/app_strings.dart';
import '../../core/routes/app_routes.dart';

class BookingScheduleView extends StatefulWidget {
  const BookingScheduleView({super.key});

  @override
  State<BookingScheduleView> createState() => _BookingScheduleViewState();
}

class _BookingScheduleViewState extends State<BookingScheduleView> {
  int selectedDay = 0;
  int selectedTime = 0;

  // getter وليس حقلاً حتى تُترجم الأيام والأوقات عند كل بناء.
  List<String> get days => [
    AppStrings.t('السبت', 'Saturday'),
    AppStrings.t('الأحد', 'Sunday'),
    AppStrings.t('الاثنين', 'Monday'),
    AppStrings.t('الثلاثاء', 'Tuesday'),
    AppStrings.t('الأربعاء', 'Wednesday'),
  ];

  List<String> get times => [
    AppStrings.t('08:00 صباحاً', '08:00 AM'),
    AppStrings.t('10:00 صباحاً', '10:00 AM'),
    AppStrings.t('12:00 ظهراً', '12:00 PM'),
    AppStrings.t('02:00 مساءً', '02:00 PM'),
    AppStrings.t('04:00 مساءً', '04:00 PM'),
    AppStrings.t('06:00 مساءً', '06:00 PM'),
  ];

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
        appBar: AppBar(
          title: Text(AppStrings.t('حجز موعد', 'Book an Appointment')),
          centerTitle: true,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppStrings.t('اختر اليوم', 'Choose the day'),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 12),

              SizedBox(
                height: 90,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: days.length,
                  itemBuilder: (context, index) {
                    final selected = selectedDay == index;

                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          selectedDay = index;
                        });
                      },
                      child: Container(
                        width: 80,
                        margin: const EdgeInsets.only(left: 10),
                        decoration: BoxDecoration(
                          color: selected ? colors.primary : colors.surface,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: colors.primary.withValues(alpha: .25),
                          ),
                        ),
                        child: Center(
                          child: Text(
                            days[index],
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: selected ? Colors.white : null,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 28),

              Text(
                AppStrings.t('اختر الوقت', 'Choose the time'),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 12),

              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: times.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 2.7,
                ),
                itemBuilder: (context, index) {
                  final selected = selectedTime == index;

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        selectedTime = index;
                      });
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: selected ? colors.primary : colors.surface,
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(
                          color: colors.primary.withValues(alpha: .25),
                        ),
                      ),
                      child: Center(
                        child: Text(
                          times[index],
                          style: TextStyle(
                            color: selected ? Colors.white : null,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 25),

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colors.primary.withValues(alpha: .07),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline_rounded, color: colors.primary),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        AppStrings.t(
                          'بعد إرسال الطلب سيتواصل معك مزود الخدمة لتأكيد الموعد والسعر.',
                          'After you send the request, the service provider will contact you to confirm the time and price.',
                        ),
                        style: const TextStyle(height: 1.5),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 25),

              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: () {
                    final incoming = ModalRoute.of(context)?.settings.arguments;
                    final Map<String, dynamic> outgoing = {
                      'date': days[selectedDay],
                      'time': times[selectedTime],
                    };
                    if (incoming is Map<String, dynamic>) {
                      outgoing.addAll(incoming);
                      outgoing['date'] = days[selectedDay];
                      outgoing['time'] = times[selectedTime];
                    }
                    Navigator.pushNamed(
                      context,
                      AppRoutes.orderDetails,
                      arguments: outgoing,
                    );
                  },
                  child: Text(
                    AppStrings.t('متابعة الطلب', 'Continue'),
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
  }
}
