class PreviousWork {
  final String title;
  final String description;
  final String? beforeImagePath;
  final String? afterImagePath;

  const PreviousWork({
    required this.title,
    required this.description,
    this.beforeImagePath,
    this.afterImagePath,
  });
}

class ProviderModel {
  String id;
  String name;
  String profession;
  String serviceCategory;
  int experienceYears;
  double rating;
  int completedJobs;
  int reviewsCount;
  String bio;
  bool isVerified;
  bool isAvailable;
  List<String> certificates;
  List<PreviousWork> previousWorks;
  Map<String, bool> availableDays;
  String startTime;
  String endTime;
  String phone;
  String email;
  String? profileImagePath;

  ProviderModel({
    required this.id,
    required this.name,
    required this.profession,
    required this.serviceCategory,
    required this.experienceYears,
    required this.rating,
    required this.completedJobs,
    this.reviewsCount = 0,
    required this.bio,
    this.isVerified = false,
    this.isAvailable = true,
    this.certificates = const [],
    this.previousWorks = const [],
    this.availableDays = const {},
    this.startTime = '08:00 صباحاً',
    this.endTime = '06:00 مساءً',
    this.phone = '',
    this.email = 'provider@khidma.com',
    this.profileImagePath,
  });
}
