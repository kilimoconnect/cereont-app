// Shared helpers for (de)serializing models to/from Supabase rows.

List<String> strList(dynamic v) =>
    (v as List?)?.map((e) => e.toString()).toList() ?? <String>[];

double toDouble(dynamic v) {
  if (v == null) return 0;
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString()) ?? 0;
}

int toInt(dynamic v, [int fallback = 0]) {
  if (v == null) return fallback;
  if (v is num) return v.toInt();
  return int.tryParse(v.toString()) ?? fallback;
}

/// Parse a timestamptz string into local time.
DateTime? parseTs(dynamic v) {
  if (v == null) return null;
  return DateTime.tryParse(v.toString())?.toLocal();
}

/// Parse a `date` column (no timezone shift).
DateTime? parseDate(dynamic v) {
  if (v == null) return null;
  return DateTime.tryParse(v.toString());
}

/// Format a DateTime as a `date` string (yyyy-MM-dd).
String? dateStr(DateTime? d) {
  if (d == null) return null;
  final y = d.year.toString().padLeft(4, '0');
  final m = d.month.toString().padLeft(2, '0');
  final day = d.day.toString().padLeft(2, '0');
  return '$y-$m-$day';
}

/// Format a DateTime as an ISO-8601 timestamptz (UTC).
String? tsStr(DateTime? d) => d?.toUtc().toIso8601String();
