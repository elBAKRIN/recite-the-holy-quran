enum KhatmaStatus { active, completed, paused, overdue }

extension KhatmaStatusLabel on KhatmaStatus {
  String get label {
    switch (this) {
      case KhatmaStatus.active:
        return 'نشطة';
      case KhatmaStatus.completed:
        return 'مكتملة';
      case KhatmaStatus.paused:
        return 'متوقفة';
      case KhatmaStatus.overdue:
        return 'منتهية غير مكتملة';
    }
  }
}

class KhatmaModel {
  KhatmaModel({
    required this.id,
    required this.name,
    required this.startDate,
    required this.endDate,
    this.startPage = 1,
    this.totalPages = 604,
    this.readPages = 0,
    this.remainingPages = 604,
    this.currentPage = 1,
    this.totalDays = 1,
    this.remainingDays = 1,
    this.todayRequiredPages = 0,
    this.todayRemainingPages = 0,
    this.progressPercentage = 0,
    this.missedDays = 0,
    this.commitmentStreakDays = 0,
    this.status = KhatmaStatus.active,
    this.notificationsEnabled = true,
    this.priorityPoints = 0,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, int>? dailyReadPages,
    List<int>? notificationTimes,
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now(),
       dailyReadPages = dailyReadPages ?? <String, int>{},
       notificationTimes = _sanitizeTimes(notificationTimes);

  /// أوقات التذكير اليومية بالدقائق منذ منتصف الليل (0..1439).
  /// مثال: 8:00 ص = 480، 14:30 = 870. عند فراغ القائمة لا تُجدول إشعارات
  /// رغم تفعيل [notificationsEnabled].
  static const List<int> defaultNotificationTimes = [8 * 60];
  static const int maxNotificationTimes = 8;

  static List<int> _sanitizeTimes(List<int>? times) {
    if (times == null || times.isEmpty) {
      return List<int>.from(defaultNotificationTimes);
    }
    final filtered =
        times
            .where((minutes) => minutes >= 0 && minutes < 24 * 60)
            .toSet()
            .toList()
          ..sort();
    if (filtered.length > maxNotificationTimes) {
      return filtered.take(maxNotificationTimes).toList();
    }
    return filtered.isEmpty
        ? List<int>.from(defaultNotificationTimes)
        : filtered;
  }

  final String id;
  String name;
  DateTime startDate;
  DateTime endDate;

  /// الصفحة التي يبدأ منها هذا الورد (1..604). الختمة تغطّي كامل المصحف
  /// (totalPages = 604)، وصفحة البداية مجرّد موضع انطلاق: الصفحات قبلها
  /// تُحتسب «بداية مسبقة» مقروءة لتُحسب النسبة على كامل المصحف. تُحدَّد مرة عند
  /// الإنشاء؛ الـcurrentPage هو ما يتغيّر مع التقدّم، ويمكن أن يسبق startPage
  /// عند الرجوع للخلف.
  int startPage;
  int totalPages;
  int readPages;
  int remainingPages;
  int currentPage;
  int totalDays;
  int remainingDays;
  int todayRequiredPages;
  int todayRemainingPages;
  double progressPercentage;
  int missedDays;
  int commitmentStreakDays;
  KhatmaStatus status;
  bool notificationsEnabled;
  DateTime createdAt;
  DateTime updatedAt;
  Map<String, int> dailyReadPages;
  int priorityPoints;
  List<int> notificationTimes;

  bool get isCompleted => status == KhatmaStatus.completed;

  int get completedDays {
    return dailyReadPages.values.where((pages) => pages > 0).length;
  }

  int get averageReadPagesPerDay {
    if (completedDays == 0) return 0;
    // نستبعد «البداية المسبقة» (الصفحات قبل startPage) لأنها لم تُقرأ ضمن أيام
    // الختمة، فيعكس المتوسط القراءة الفعلية فقط.
    final earned = (readPages - (startPage - 1)).clamp(0, totalPages);
    return (earned / completedDays).ceil();
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'startPage': startPage,
      'totalPages': totalPages,
      'readPages': readPages,
      'remainingPages': remainingPages,
      'currentPage': currentPage,
      'totalDays': totalDays,
      'remainingDays': remainingDays,
      'todayRequiredPages': todayRequiredPages,
      'todayRemainingPages': todayRemainingPages,
      'progressPercentage': progressPercentage,
      'missedDays': missedDays,
      'commitmentStreakDays': commitmentStreakDays,
      'status': status.name,
      'notificationsEnabled': notificationsEnabled,
      'notificationTimes': notificationTimes,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'dailyReadPages': dailyReadPages,
      'priorityPoints': priorityPoints,
    };
  }

  factory KhatmaModel.fromJson(Map<String, dynamic> json) {
    return KhatmaModel(
      id: json['id'] as String,
      name: json['name'] as String,
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: DateTime.parse(json['endDate'] as String),
      startPage: json['startPage'] as int? ?? 1,
      totalPages: json['totalPages'] as int? ?? 604,
      readPages: json['readPages'] as int? ?? 0,
      remainingPages: json['remainingPages'] as int? ?? 604,
      currentPage: json['currentPage'] as int? ?? 1,
      totalDays: json['totalDays'] as int? ?? 1,
      remainingDays: json['remainingDays'] as int? ?? 1,
      todayRequiredPages: json['todayRequiredPages'] as int? ?? 0,
      todayRemainingPages: json['todayRemainingPages'] as int? ?? 0,
      progressPercentage: (json['progressPercentage'] as num?)?.toDouble() ?? 0,
      missedDays: json['missedDays'] as int? ?? 0,
      commitmentStreakDays: json['commitmentStreakDays'] as int? ?? 0,
      status: KhatmaStatus.values.firstWhere(
        (status) => status.name == json['status'],
        orElse: () => KhatmaStatus.active,
      ),
      notificationsEnabled: json['notificationsEnabled'] as bool? ?? true,
      notificationTimes: (json['notificationTimes'] as List?)
          ?.map((value) => (value as num).toInt())
          .toList(),
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? ''),
      updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? ''),
      dailyReadPages: Map<String, int>.from(
        (json['dailyReadPages'] as Map? ?? <String, int>{}).map(
          (key, value) => MapEntry(key.toString(), value as int),
        ),
      ),
      priorityPoints: json['priorityPoints'] as int? ?? 0,
    );
  }

  KhatmaModel copyWith({
    String? name,
    DateTime? startDate,
    DateTime? endDate,
    bool? notificationsEnabled,
    List<int>? notificationTimes,
    KhatmaStatus? status,
    int? priorityPoints,
    int? currentPage,
  }) {
    return KhatmaModel(
      id: id,
      name: name ?? this.name,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      startPage: startPage,
      totalPages: totalPages,
      readPages: readPages,
      remainingPages: remainingPages,
      currentPage: currentPage ?? this.currentPage,
      totalDays: totalDays,
      remainingDays: remainingDays,
      todayRequiredPages: todayRequiredPages,
      todayRemainingPages: todayRemainingPages,
      progressPercentage: progressPercentage,
      missedDays: missedDays,
      commitmentStreakDays: commitmentStreakDays,
      status: status ?? this.status,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      notificationTimes:
          notificationTimes ?? List<int>.from(this.notificationTimes),
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      dailyReadPages: Map<String, int>.from(dailyReadPages),
      priorityPoints: priorityPoints ?? this.priorityPoints,
    );
  }
}
