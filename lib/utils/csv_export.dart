String toCsv(List<List<String>> rows) {
  String escape(String s) {
    final needsQuotes = s.contains(',') || s.contains('\n') || s.contains('"') || s.contains('\r');
    final escaped = s.replaceAll('"', '""');
    return needsQuotes ? '"$escaped"' : escaped;
  }

  return rows.map((row) => row.map(escape).join(',')).join('\n');
}


