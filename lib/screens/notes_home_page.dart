
import 'package:flutter/material.dart';

import '../models/note.dart';
import '../storage/notes_store.dart';

class NotesHomePage extends StatefulWidget {
  NotesHomePage({super.key, NotesStore? store})
      : store = store ?? PreferencesNotesStore();

  final NotesStore store;

  @override
  State<NotesHomePage> createState() => _NotesHomePageState();
}

class _NotesHomePageState extends State<NotesHomePage> {
  List<Note> _notes = [];
  bool _loading = true;
  bool _writing = false;

  @override
  void initState() {
    super.initState();
    _loadNotes();
  }

  // Requirement 2: load the notes again after the application is reopened.
  Future<void> _loadNotes() async {
    try {
      final notes = await widget.store.loadNotes();
      if (!mounted) return;
      setState(() {
        _notes = notes;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _loading = false);
      _showMessage('Could not load notes: $error');
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  // Saves first and then updates the list on the screen.
  Future<void> _saveList(List<Note> next) async {
    if (_writing) return;
    _writing = true;
    try {
      await widget.store.saveNotes(next);
      if (!mounted) return;
      setState(() => _notes = next);
    } finally {
      _writing = false;
    }
  }

  // The pen icon opens the title/description inputs with existing values.
  Future<void> _openNoteEditor({int? editIndex}) async {
    final existing = editIndex == null ? null : _notes[editIndex];
    final saved = await showDialog<bool>(
      context: context,
      builder: (_) => _NoteEditorDialog(
        note: existing,
        onSave: (title, description) async {
          final next = List<Note>.from(_notes);
          if (editIndex == null) {
            next.insert(
              0,
              Note(
                id: DateTime.now().microsecondsSinceEpoch.toString(),
                title: title,
                description: description,
              ),
            );
          } else {
            // Keep the same ID while updating both editable fields.
            next[editIndex] = Note(
              id: existing!.id,
              title: title,
              description: description,
            );
          }
          await _saveList(next);
        },
      ),
    );
    if (saved == true) {
      _showMessage(editIndex == null ? 'Note added' : 'Note updated');
    }
  }

  Future<void> _deleteNote(int index) async {
    final next = List<Note>.from(_notes)..removeAt(index);
    try {
      await _saveList(next);
      _showMessage('Note deleted');
    } catch (error) {
      _showMessage('Could not delete note: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Notes'),
        centerTitle: false,
        backgroundColor: Theme.of(context).colorScheme.surface,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _notes.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text(
                      'No notes yet. Tap + to create your first note.',
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _notes.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final note = _notes[index];
                    return Card(
                      elevation: 0,
                      color: Theme.of(context).colorScheme.surface,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 5),
                        child: ListTile(
                          title: Text(
                            note.title,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(note.description),
                          ),
                          isThreeLine: note.description.length > 45,
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Requirement 1: pen icon immediately by delete.
                              IconButton(
                                key: Key('edit_${note.id}'),
                                tooltip: 'Edit note: ${note.title}',
                                icon: const Icon(Icons.edit_outlined),
                                onPressed: () => _openNoteEditor(editIndex: index),
                              ),
                              IconButton(
                                key: Key('delete_${note.id}'),
                                tooltip: 'Delete note: ${note.title}',
                                icon: const Icon(Icons.delete_outline),
                                onPressed: () => _deleteNote(index),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton.extended(
        tooltip: 'Add note',
        onPressed: _loading ? null : () => _openNoteEditor(),
        icon: const Icon(Icons.add),
        label: const Text('New note'),
      ),
    );
  }
}

// This dialog owns its controllers, so editing/closing is safe.
class _NoteEditorDialog extends StatefulWidget {
  const _NoteEditorDialog({required this.onSave, this.note});

  final Note? note;
  final Future<void> Function(String title, String description) onSave;

  @override
  State<_NoteEditorDialog> createState() => _NoteEditorDialogState();
}

class _NoteEditorDialogState extends State<_NoteEditorDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.note?.title ?? '');
    _descriptionController =
        TextEditingController(text: widget.note?.description ?? '');
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_saving || !_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await widget.onSave(
        _titleController.text.trim(),
        _descriptionController.text.trim(),
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not save note: $error')),
      );
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.note != null;
    return AlertDialog(
      title: Text(editing ? 'Edit note' : 'New note'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                key: const Key('title_field'),
                controller: _titleController,
                autofocus: true,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Please enter a title'
                    : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                key: const Key('description_field'),
                controller: _descriptionController,
                minLines: 3,
                maxLines: 5,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Please enter a description'
                    : null,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _saving ? null : _submit,
          child: Text(editing ? 'Save changes' : 'Add note'),
        ),
      ],
    );
  }
}
