
import 'package:flutter_test/flutter_test.dart';
import 'package:cecs453_lab7_notes/models/note.dart';

void main() {
  test('A note keeps its title and description when encoded and decoded', () {
    const note = Note(
      id: '123',
      title: 'Homework',
      description: 'Finish CECS 453 Lab 7',
    );
    final restored = Note.fromJson(note.toJson());
    expect(restored.id, note.id);
    expect(restored.title, note.title);
    expect(restored.description, note.description);
  });
}
