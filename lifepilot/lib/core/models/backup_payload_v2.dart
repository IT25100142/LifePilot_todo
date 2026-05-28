class BackupPayloadV2 {
  const BackupPayloadV2({
    required this.formatVersion,
    required this.app,
    required this.exportedAt,
    required this.dbSchemaVersion,
    required this.settings,
    required this.tasks,
    required this.events,
    required this.categories,
    required this.accounts,
    required this.transactions,
  });

  final int formatVersion;
  final String app;
  final String exportedAt;
  final int dbSchemaVersion;
  final BackupSettingsV2 settings;
  final List<BackupTaskV2> tasks;
  final List<BackupEventV2> events;
  final List<BackupCategoryV2> categories;
  final List<BackupAccountV2> accounts;
  final List<BackupTransactionV2> transactions;

  Map<String, dynamic> toJson() => {
        'formatVersion': formatVersion,
        'app': app,
        'exportedAt': exportedAt,
        'dbSchemaVersion': dbSchemaVersion,
        'settings': settings.toJson(),
        'tasks': tasks.map((item) => item.toJson()).toList(),
        'events': events.map((item) => item.toJson()).toList(),
        'categories': categories.map((item) => item.toJson()).toList(),
        'accounts': accounts.map((item) => item.toJson()).toList(),
        'transactions': transactions.map((item) => item.toJson()).toList(),
      };

  static BackupPayloadV2 fromJson(Map<String, dynamic> json) {
    return BackupPayloadV2(
      formatVersion: (json['formatVersion'] as num?)?.toInt() ?? 0,
      app: json['app'] as String? ?? 'LifePilot',
      exportedAt: json['exportedAt'] as String? ?? DateTime.now().toIso8601String(),
      dbSchemaVersion: (json['dbSchemaVersion'] as num?)?.toInt() ?? 0,
      settings: BackupSettingsV2.fromJson(
        (json['settings'] as Map?)?.cast<String, dynamic>() ?? const {},
      ),
      tasks: _readList(json['tasks'])
          .map((item) => BackupTaskV2.fromJson(item))
          .toList(),
      events: _readList(json['events'])
          .map((item) => BackupEventV2.fromJson(item))
          .toList(),
      categories: _readList(json['categories'])
          .map((item) => BackupCategoryV2.fromJson(item))
          .toList(),
      accounts: _readList(json['accounts'])
          .map((item) => BackupAccountV2.fromJson(item))
          .toList(),
      transactions: _readList(json['transactions'])
          .map((item) => BackupTransactionV2.fromJson(item))
          .toList(),
    );
  }

  static List<Map<String, dynamic>> _readList(Object? value) {
    final raw = value as List<dynamic>? ?? const [];
    return raw.map((item) => (item as Map).cast<String, dynamic>()).toList();
  }
}

class BackupSettingsV2 {
  const BackupSettingsV2({
    required this.currency,
    this.themeMode,
  });

  final String currency;
  final String? themeMode;

  Map<String, dynamic> toJson() => {
        'currency': currency,
        'themeMode': themeMode,
      };

  static BackupSettingsV2 fromJson(Map<String, dynamic> json) {
    return BackupSettingsV2(
      currency: json['currency'] as String? ?? 'LKR',
      themeMode: json['themeMode'] as String?,
    );
  }
}

class BackupTaskV2 {
  const BackupTaskV2({
    required this.sourceId,
    required this.title,
    required this.description,
    required this.dueDate,
    required this.reminderAt,
    required this.priority,
    required this.tags,
    required this.isCompleted,
    required this.createdAt,
    required this.updatedAt,
    required this.recurrencePattern,
    required this.recurrenceParentId,
  });

  final int sourceId;
  final String title;
  final String description;
  final String? dueDate;
  final String? reminderAt;
  final String priority;
  final String tags;
  final bool isCompleted;
  final String createdAt;
  final String updatedAt;
  final String? recurrencePattern;
  final int? recurrenceParentId;

  Map<String, dynamic> toJson() => {
        'sourceId': sourceId,
        'title': title,
        'description': description,
        'dueDate': dueDate,
        'reminderAt': reminderAt,
        'priority': priority,
        'tags': tags,
        'isCompleted': isCompleted,
        'createdAt': createdAt,
        'updatedAt': updatedAt,
        'recurrencePattern': recurrencePattern,
        'recurrenceParentId': recurrenceParentId,
      };

  static BackupTaskV2 fromJson(Map<String, dynamic> json) {
    return BackupTaskV2(
      sourceId: (json['sourceId'] as num?)?.toInt() ?? (json['id'] as num?)?.toInt() ?? 0,
      title: json['title'] as String? ?? 'Imported task',
      description: json['description'] as String? ?? '',
      dueDate: json['dueDate'] as String?,
      reminderAt: json['reminderAt'] as String?,
      priority: json['priority'] as String? ?? 'medium',
      tags: json['tags'] as String? ?? '',
      isCompleted: json['isCompleted'] as bool? ?? false,
      createdAt: json['createdAt'] as String? ?? DateTime.now().toIso8601String(),
      updatedAt: json['updatedAt'] as String? ?? DateTime.now().toIso8601String(),
      recurrencePattern: json['recurrencePattern'] as String?,
      recurrenceParentId: (json['recurrenceParentId'] as num?)?.toInt(),
    );
  }
}

class BackupEventV2 {
  const BackupEventV2({
    required this.sourceId,
    required this.title,
    required this.description,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.reminderAt,
    required this.createdAt,
    required this.updatedAt,
  });

  final int sourceId;
  final String title;
  final String description;
  final String date;
  final String startTime;
  final String endTime;
  final String? reminderAt;
  final String createdAt;
  final String updatedAt;

  Map<String, dynamic> toJson() => {
        'sourceId': sourceId,
        'title': title,
        'description': description,
        'date': date,
        'startTime': startTime,
        'endTime': endTime,
        'reminderAt': reminderAt,
        'createdAt': createdAt,
        'updatedAt': updatedAt,
      };

  static BackupEventV2 fromJson(Map<String, dynamic> json) {
    final now = DateTime.now().toIso8601String();
    return BackupEventV2(
      sourceId: (json['sourceId'] as num?)?.toInt() ?? (json['id'] as num?)?.toInt() ?? 0,
      title: json['title'] as String? ?? 'Imported event',
      description: json['description'] as String? ?? '',
      date: json['date'] as String? ?? now,
      startTime: json['startTime'] as String? ?? now,
      endTime: json['endTime'] as String? ?? now,
      reminderAt: json['reminderAt'] as String?,
      createdAt: json['createdAt'] as String? ?? now,
      updatedAt: json['updatedAt'] as String? ?? now,
    );
  }
}

class BackupCategoryV2 {
  const BackupCategoryV2({
    required this.sourceId,
    required this.name,
    required this.type,
    required this.colorValue,
    required this.iconName,
    required this.monthlyBudget,
  });

  final int sourceId;
  final String name;
  final String type;
  final int colorValue;
  final String iconName;
  final double? monthlyBudget;

  Map<String, dynamic> toJson() => {
        'sourceId': sourceId,
        'name': name,
        'type': type,
        'colorValue': colorValue,
        'iconName': iconName,
        'monthlyBudget': monthlyBudget,
      };

  static BackupCategoryV2 fromJson(Map<String, dynamic> json) {
    return BackupCategoryV2(
      sourceId: (json['sourceId'] as num?)?.toInt() ?? (json['id'] as num?)?.toInt() ?? 0,
      name: json['name'] as String? ?? 'Category',
      type: json['type'] as String? ?? 'both',
      colorValue: (json['colorValue'] as num?)?.toInt() ?? 0xFF286C63,
      iconName: json['iconName'] as String? ?? 'label',
      monthlyBudget: (json['monthlyBudget'] as num?)?.toDouble(),
    );
  }
}

class BackupAccountV2 {
  const BackupAccountV2({
    required this.sourceId,
    required this.name,
    required this.initialBalance,
    required this.currentBalance,
    required this.colorValue,
    required this.createdAt,
  });

  final int sourceId;
  final String name;
  final double initialBalance;
  final double currentBalance;
  final int colorValue;
  final String createdAt;

  Map<String, dynamic> toJson() => {
        'sourceId': sourceId,
        'name': name,
        'initialBalance': initialBalance,
        'currentBalance': currentBalance,
        'colorValue': colorValue,
        'createdAt': createdAt,
      };

  static BackupAccountV2 fromJson(Map<String, dynamic> json) {
    return BackupAccountV2(
      sourceId: (json['sourceId'] as num?)?.toInt() ?? (json['id'] as num?)?.toInt() ?? 0,
      name: json['name'] as String? ?? 'Account',
      initialBalance: (json['initialBalance'] as num?)?.toDouble() ?? 0,
      currentBalance: (json['currentBalance'] as num?)?.toDouble() ?? 0,
      colorValue: (json['colorValue'] as num?)?.toInt() ?? 0xFF286C63,
      createdAt: json['createdAt'] as String? ?? DateTime.now().toIso8601String(),
    );
  }
}

class BackupTransactionV2 {
  const BackupTransactionV2({
    required this.sourceId,
    required this.title,
    required this.amount,
    required this.category,
    required this.date,
    required this.note,
    required this.type,
    required this.createdAt,
    required this.updatedAt,
    required this.accountId,
    required this.transferTargetAccountId,
  });

  final int sourceId;
  final String title;
  final double amount;
  final String category;
  final String date;
  final String note;
  final String type;
  final String createdAt;
  final String updatedAt;
  final int? accountId;
  final int? transferTargetAccountId;

  Map<String, dynamic> toJson() => {
        'sourceId': sourceId,
        'title': title,
        'amount': amount,
        'category': category,
        'date': date,
        'note': note,
        'type': type,
        'createdAt': createdAt,
        'updatedAt': updatedAt,
        'accountId': accountId,
        'transferTargetAccountId': transferTargetAccountId,
      };

  static BackupTransactionV2 fromJson(Map<String, dynamic> json) {
    return BackupTransactionV2(
      sourceId: (json['sourceId'] as num?)?.toInt() ?? (json['id'] as num?)?.toInt() ?? 0,
      title: json['title'] as String? ?? 'Imported transaction',
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      category: json['category'] as String? ?? 'Other',
      date: json['date'] as String? ?? DateTime.now().toIso8601String(),
      note: json['note'] as String? ?? '',
      type: json['type'] as String? ?? 'expense',
      createdAt: json['createdAt'] as String? ?? DateTime.now().toIso8601String(),
      updatedAt: json['updatedAt'] as String? ?? DateTime.now().toIso8601String(),
      accountId: (json['accountId'] as num?)?.toInt(),
      transferTargetAccountId: (json['transferTargetAccountId'] as num?)?.toInt(),
    );
  }
}
