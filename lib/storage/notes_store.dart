
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/note.dart';

/// An interface so the UI can also be tested without a phone or database.
abstract class NotesStore {
  Future<List<Note>> loadNotes();
  Future<void> saveNotes(List<Note> notes);
}

/// Saves all notes on the Android device as a JSON string.
/// Data is reloaded every time the app starts.
class PreferencesNotesStore implements NotesStore {
  PreferencesNotesStore({SharedPreferencesAsync? preferences})
      : _preferences = preferences ?? SharedPreferencesAsync();

  static const _key = 'cecs453_lab7_notes';
  final SharedPreferencesAsync _preferences;

  @override
  Future<List<Note>> loadNotes() async {
    final saved = await _preferences.getString(_key);
    if (saved == null || saved.isEmpty) return [];

    final List<dynamic> rows = jsonDecode(saved) as List<dynamic>;
    return rows
        .map((row) => Note.fromJson(Map<String, dynamic>.from(row as Map)))
        .toList();
  }

  @override
  Future<void> saveNotes(List<Note> notes) async {
    final data = notes.map((note) => note.toJson()).toList();
    await _preferences.setString(_key, jsonEncode(data));
  }
}
