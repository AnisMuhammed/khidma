import 'package:flutter/material.dart';
import '../../core/localization/app_strings.dart';

class ProviderScheduleView extends StatefulWidget {
  const ProviderScheduleView({super.key});

  @override
  State<ProviderScheduleView> createState() =>
      _ProviderScheduleViewState();
}

class _ProviderScheduleViewState
    extends State<ProviderScheduleView> {
// مفاتيح الأيام تبقى عربية لأنها ثابتة الحالة، ويُترجم النص المعروض فقط.
static const Map<String, String> _dayNamesEn = {
'السبت': 'Saturday',
'الأحد': 'Sunday',
'الاثنين': 'Monday',
'الثلاثاء': 'Tuesday',
'الأربعاء': 'Wednesday',
'الخميس': 'Thursday',
'الجمعة': 'Friday',
};

final Map<String, bool> availableDays = {
'السبت': true,
'الأحد': true,
'الاثنين': true,
'الثلاثاء': true,
'الأربعاء': true,
'الخميس': true,
'الجمعة': false,
};

TimeOfDay startTime = const TimeOfDay(hour: 8, minute: 0);
TimeOfDay endTime = const TimeOfDay(hour: 18, minute: 0);

Future<void> _selectTime(bool isStart) async {
final result = await showTimePicker(
context: context,
initialTime: isStart ? startTime : endTime,
);

if (result == null) return;

setState(() {
if (isStart) {
startTime = result;
} else {
endTime = result;
}
});
}

String _formatTime(TimeOfDay time) {
return time.format(context);
}

@override
Widget build(BuildContext context) {
final colors = Theme.of(context).colorScheme;

return Scaffold(
appBar: AppBar(
title: Text(AppStrings.t('مواعيد العمل', 'Working Hours')),
centerTitle: true,
),
body: ListView(
padding: const EdgeInsets.all(20),
children: [
Container(
padding: const EdgeInsets.all(18),
decoration: BoxDecoration(
color: colors.primary.withValues(alpha: .08),
borderRadius: BorderRadius.circular(20),
),
child: Row(
children: [
const Icon(Icons.info_outline_rounded),
const SizedBox(width: 12),
Expanded(
child: Text(
AppStrings.t(
'حدد الأيام والأوقات التي تستطيع استقبال العملاء فيها.',
'Set the days and times when you can receive clients.',
),
),
),
],
),
),
  const SizedBox(height: 25),

  Text(
    AppStrings.t('أيام العمل', 'Working days'),
    style: const TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.w900,
    ),
  ),

  const SizedBox(height: 10),

  Card(
    child: Column(
      children: availableDays.keys.map((day) {
        return SwitchListTile(
          title: Text(
            AppStrings.t(day, _dayNamesEn[day] ?? day),
            style: const TextStyle(
              fontWeight: FontWeight.w600,
            ),
          ),
          value: availableDays[day]!,
          onChanged: (value) {
            setState(() {
              availableDays[day] = value;
            });
          },
        );
      }).toList(),
    ),
  ),

  const SizedBox(height: 25),

  Text(
    AppStrings.t('ساعات العمل', 'Working hours'),
    style: const TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.w900,
    ),
  ),

  const SizedBox(height: 12),

  Row(
    children: [
      Expanded(
        child: _TimeCard(
          title: AppStrings.t('من', 'From'),
          time: _formatTime(startTime),
          icon: Icons.login_rounded,
          onTap: () => _selectTime(true),
        ),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: _TimeCard(
          title: AppStrings.t('إلى', 'To'),
          time: _formatTime(endTime),
          icon: Icons.logout_rounded,
          onTap: () => _selectTime(false),
        ),
      ),
    ],
  ),

  const SizedBox(height: 30),

  SizedBox(
    height: 55,
    child: FilledButton(
      onPressed: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppStrings.t(
                'تم حفظ جدول المواعيد بنجاح',
                'The schedule was saved successfully',
              ),
            ),
          ),
        );
      },
      child: Text(
        AppStrings.t('حفظ المواعيد', 'Save Schedule'),
        style: const TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.bold,
        ),
      ),
    ),
  ),
],
),
);
}
}
class _TimeCard extends StatelessWidget {
  final String title;
  final String time;
  final IconData icon;
  final VoidCallback onTap;

  const _TimeCard({
    required this.title,
    required this.time,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          border: Border.all(
            color: Theme.of(context).dividerColor,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(icon),
            const SizedBox(height: 8),
            Text(title),
            const SizedBox(height: 5),
            Text(
              time,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}