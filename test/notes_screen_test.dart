
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cecs453_lab7_notes/models/note.dart';
import 'package:cecs453_lab7_notes/screens/notes_home_page.dart';
import 'package:cecs453_lab7_notes/storage/notes_store.dart';

class FakeNotesStore implements NotesStore {
  List<Note> saved = [];

  @override
  Future<List<Note>> loadNotes() async => List<Note>.from(saved);

  @override
  Future<void> saveNotes(List<Note> notes) async {
    saved = List<Note>.from(notes);
  }
}

void main() {
  testWidgets('Create three notes, update one, and reload it', (tester) async {
    final store = FakeNotesStore();

    Future<void> openAndAdd(String title, String description) async {
      await tester.tap(find.byTooltip('Add note'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('title_field')), title);
      await tester.enterText(
        find.byKey(const Key('description_field')),
        description,
      );
      await tester.tap(find.text('Add note'));
      await tester.pumpAndSettle();
    }

    await tester.pumpWidget(
      MaterialApp(home: NotesHomePage(store: store)),
    );
    await tester.pumpAndSettle();

    await openAndAdd('School', 'Finish homework');
    await openAndAdd('Groceries', 'Buy milk');
    await openAndAdd('Work', 'Shift at 5 PM');
    expect(store.saved.length, 3);

    await tester.tap(find.byTooltip('Edit note: Groceries'));
    await tester.pumpAndSettle();
    expect(
      tester.widget<TextFormField>(find.byKey(const Key('title_field')))
          .controller?.text,
      'Groceries',
    );
    await tester.enterText(find.byKey(const Key('title_field')), 'Shopping');
    await tester.enterText(
      find.byKey(const Key('description_field')),
      'Buy eggs and milk',
    );
    await tester.tap(find.text('Save changes'));
    await tester.pumpAndSettle();
    expect(store.saved.any((note) => note.title == 'Shopping'), isTrue);

    // Simulate closing and opening the screen using the same saved data.
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpWidget(
      MaterialApp(home: NotesHomePage(store: store)),
    );
    await tester.pumpAndSettle();
    expect(find.text('Shopping'), findsOneWidget);
    expect(find.text('Buy eggs and milk'), findsOneWidget);
    expect(find.text('School'), findsOneWidget);
    expect(find.text('Work'), findsOneWidget);
  });
}
