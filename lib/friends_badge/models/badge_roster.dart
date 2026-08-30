import 'package:equatable/equatable.dart';

/// One person to prepare a badge for, read from the speed writer's CSV.
class BadgeRosterEntry extends Equatable {
  const BadgeRosterEntry({
    required this.name,
    required this.role,
    this.email = '',
  });

  final String name;
  final String role;

  /// The person's e-mail address, or empty. Written to the badge as a
  /// `mailto:` link.
  final String email;

  @override
  List<Object> get props => [name, role, email];
}

/// Parses the speed writer's CSV into roster entries.
///
/// Accepts the shape the organizers export from their spreadsheet:
///
/// ```text
/// name,role,email
/// Ada Lovelace,Speaker,ada@example.com
/// "Babbage, Charles",Attendee,
/// ```
///
/// - The delimiter is detected from the first line: a comma, else a
///   semicolon (Excel in many locales), else a tab.
/// - A header row is optional. When the first row has a `name` cell, the
///   `name`, `role` and `email` (or `e-mail`, `mail`) columns are looked up
///   by header; otherwise the columns are taken in that order.
/// - Quoted fields may contain the delimiter, newlines and doubled quotes.
/// - Rows without a name are skipped; a leading byte order mark is ignored.
///
/// Throws a [FormatException] when the file yields no people.
List<BadgeRosterEntry> parseBadgeRoster(String csv) {
  final text = csv.startsWith('﻿') ? csv.substring(1) : csv;
  final rows = _parseRows(text, _detectDelimiter(text));
  if (rows.isEmpty) throw const FormatException('The file is empty.');

  var nameColumn = 0;
  var roleColumn = 1;
  var emailColumn = 2;
  var firstDataRow = 0;
  final header = rows.first.map((cell) => cell.trim().toLowerCase()).toList();
  final headerNameColumn = header.indexOf('name');
  if (headerNameColumn != -1) {
    nameColumn = headerNameColumn;
    roleColumn = header.indexOf('role');
    emailColumn = [
      'email',
      'e-mail',
      'mail',
    ].map(header.indexOf).firstWhere((index) => index != -1, orElse: () => -1);
    firstDataRow = 1;
  }

  String cell(List<String> row, int column) =>
      column >= 0 && column < row.length ? row[column].trim() : '';

  final entries = [
    for (final row in rows.skip(firstDataRow))
      if (cell(row, nameColumn).isNotEmpty)
        BadgeRosterEntry(
          name: cell(row, nameColumn),
          role: cell(row, roleColumn),
          email: cell(row, emailColumn),
        ),
  ];
  if (entries.isEmpty) {
    throw const FormatException(
      'No people found. Expected columns: name, role, email.',
    );
  }
  return entries;
}

String _detectDelimiter(String text) {
  final firstLine = text.split('\n').first;
  if (firstLine.contains(',')) return ',';
  if (firstLine.contains(';')) return ';';
  if (firstLine.contains('\t')) return '\t';
  return ',';
}

/// Splits [text] into rows of cells per RFC 4180, using [delimiter] between
/// cells. Blank lines are dropped.
List<List<String>> _parseRows(String text, String delimiter) {
  final rows = <List<String>>[];
  var row = <String>[];
  final cell = StringBuffer();
  var quoted = false;
  var index = 0;

  void endCell() {
    row.add(cell.toString());
    cell.clear();
  }

  void endRow() {
    endCell();
    if (row.any((value) => value.trim().isNotEmpty)) rows.add(row);
    row = <String>[];
  }

  while (index < text.length) {
    final char = text[index];
    if (quoted) {
      if (char == '"') {
        if (index + 1 < text.length && text[index + 1] == '"') {
          cell.write('"');
          index++;
        } else {
          quoted = false;
        }
      } else {
        cell.write(char);
      }
    } else if (char == '"') {
      quoted = true;
    } else if (char == delimiter) {
      endCell();
    } else if (char == '\r') {
      if (index + 1 < text.length && text[index + 1] == '\n') index++;
      endRow();
    } else if (char == '\n') {
      endRow();
    } else {
      cell.write(char);
    }
    index++;
  }
  endRow();
  return rows;
}
