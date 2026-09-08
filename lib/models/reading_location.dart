import 'dart:convert';

/// Encapsulates reading location, progress coordinates, and time estimates
/// corresponding to Foliate's reading location popover.
class ReadingLocation {
  final String cfi;
  final double fraction; // 0.0 to 1.0
  final double percentage; // 0.0 to 100.0
  final int? currentLocation;
  final int? totalLocations;
  final int? currentSection;
  final int? totalSections;
  final String? sectionTitle;
  final String? excerpt;
  final int? timeLeftSectionSeconds;
  final int? timeLeftBookSeconds;

  const ReadingLocation({
    required this.cfi,
    this.fraction = 0.0,
    this.percentage = 0.0,
    this.currentLocation,
    this.totalLocations,
    this.currentSection,
    this.totalSections,
    this.sectionTitle,
    this.excerpt,
    this.timeLeftSectionSeconds,
    this.timeLeftBookSeconds,
  });

  /// Formatted string for "Time Left in Section" (e.g., "21 mins")
  String get formattedTimeLeftSection {
    if (timeLeftSectionSeconds == null || timeLeftSectionSeconds! <= 0) {
      return '--';
    }
    final mins = (timeLeftSectionSeconds! / 60).round();
    if (mins < 60) return '$mins mins';
    final hrs = (mins / 60).toStringAsFixed(1);
    return '$hrs hrs';
  }

  /// Formatted string for "Time Left in Book" (e.g., "18.7 hrs")
  String get formattedTimeLeftBook {
    if (timeLeftBookSeconds == null || timeLeftBookSeconds! <= 0) {
      return '--';
    }
    final mins = (timeLeftBookSeconds! / 60).round();
    if (mins < 60) return '$mins mins';
    final hrs = (mins / 60).toStringAsFixed(1);
    return '$hrs hrs';
  }

  ReadingLocation copyWith({
    String? cfi,
    double? fraction,
    double? percentage,
    int? currentLocation,
    int? totalLocations,
    int? currentSection,
    int? totalSections,
    String? sectionTitle,
    String? excerpt,
    int? timeLeftSectionSeconds,
    int? timeLeftBookSeconds,
  }) {
    return ReadingLocation(
      cfi: cfi ?? this.cfi,
      fraction: fraction ?? this.fraction,
      percentage: percentage ?? this.percentage,
      currentLocation: currentLocation ?? this.currentLocation,
      totalLocations: totalLocations ?? this.totalLocations,
      currentSection: currentSection ?? this.currentSection,
      totalSections: totalSections ?? this.totalSections,
      sectionTitle: sectionTitle ?? this.sectionTitle,
      excerpt: excerpt ?? this.excerpt,
      timeLeftSectionSeconds: timeLeftSectionSeconds ?? this.timeLeftSectionSeconds,
      timeLeftBookSeconds: timeLeftBookSeconds ?? this.timeLeftBookSeconds,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'cfi': cfi,
      'fraction': fraction,
      'percentage': percentage,
      'currentLocation': currentLocation,
      'totalLocations': totalLocations,
      'currentSection': currentSection,
      'totalSections': totalSections,
      'sectionTitle': sectionTitle,
      'excerpt': excerpt,
      'timeLeftSectionSeconds': timeLeftSectionSeconds,
      'timeLeftBookSeconds': timeLeftBookSeconds,
    };
  }

  factory ReadingLocation.fromMap(Map<String, dynamic> map) {
    return ReadingLocation(
      cfi: map['cfi'] as String? ?? '',
      fraction: (map['fraction'] as num?)?.toDouble() ?? 0.0,
      percentage: (map['percentage'] as num?)?.toDouble() ?? 0.0,
      currentLocation: (map['currentLocation'] as num?)?.toInt(),
      totalLocations: (map['totalLocations'] as num?)?.toInt(),
      currentSection: (map['currentSection'] as num?)?.toInt(),
      totalSections: (map['totalSections'] as num?)?.toInt(),
      sectionTitle: map['sectionTitle'] as String?,
      excerpt: map['excerpt'] as String?,
      timeLeftSectionSeconds: (map['timeLeftSectionSeconds'] as num?)?.toInt(),
      timeLeftBookSeconds: (map['timeLeftBookSeconds'] as num?)?.toInt(),
    );
  }

  String toJson() => json.encode(toMap());

  factory ReadingLocation.fromJson(String source) =>
      ReadingLocation.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() =>
      'ReadingLocation(cfi: $cfi, percentage: $percentage%, loc: $currentLocation/$totalLocations)';
}
