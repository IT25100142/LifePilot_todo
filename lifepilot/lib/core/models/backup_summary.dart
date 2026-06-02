class BackupSummary {
  const BackupSummary({
    required this.formatVersion,
    required this.exportedAt,
    required this.taskCount,
    required this.eventCount,
    required this.accountCount,
    required this.transactionCount,
    this.currency,
    this.dbSchemaVersion,
    this.isLegacy = false,
  });

  final int formatVersion;
  final DateTime exportedAt;
  final int taskCount;
  final int eventCount;
  final int accountCount;
  final int transactionCount;
  final String? currency;
  final int? dbSchemaVersion;
  final bool isLegacy;
}
