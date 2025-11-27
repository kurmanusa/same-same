/// Represents a group within a section with its display title
class GroupInfo {
  final String groupCode; // technical code for filtering/queries
  final String groupTitle; // human-readable title for display

  GroupInfo({
    required this.groupCode,
    required this.groupTitle,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GroupInfo &&
          runtimeType == other.runtimeType &&
          groupCode == other.groupCode;

  @override
  int get hashCode => groupCode.hashCode;
}

