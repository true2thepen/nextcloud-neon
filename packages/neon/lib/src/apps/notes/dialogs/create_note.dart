part of '../app.dart';

class NotesCreateNoteDialog extends StatefulWidget {
  const NotesCreateNoteDialog({
    required this.bloc,
    this.category,
    super.key,
  });

  final NotesBloc bloc;
  final String? category;

  @override
  State<NotesCreateNoteDialog> createState() => _NotesCreateNoteDialogState();
}

class _NotesCreateNoteDialogState extends State<NotesCreateNoteDialog> {
  final formKey = GlobalKey<FormState>();
  final controller = TextEditingController();
  String? selectedCategory;

  void submit() {
    if (formKey.currentState!.validate()) {
      Navigator.of(context).pop([controller.text, widget.category ?? selectedCategory]);
    }
  }

  @override
  Widget build(final BuildContext context) => StandardRxResultBuilder<NotesBloc, List<NotesNote>>(
        bloc: widget.bloc,
        state: (final bloc) => bloc.notes,
        builder: (
          final context,
          final notesData,
          final notesError,
          final notesLoading,
          final _,
        ) =>
            CustomDialog(
          title: Text(AppLocalizations.of(context).notesCreateNote),
          children: [
            Form(
              key: formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  TextFormField(
                    autofocus: true,
                    controller: controller,
                    decoration: InputDecoration(
                      hintText: AppLocalizations.of(context).notesNoteTitle,
                    ),
                    validator: (final input) => validateNotEmpty(context, input),
                    onFieldSubmitted: (final _) {
                      submit();
                    },
                  ),
                  if (widget.category == null) ...[
                    Center(
                      child: ExceptionWidget(
                        notesError,
                        onRetry: () {
                          widget.bloc.refresh();
                        },
                      ),
                    ),
                    Center(
                      child: CustomLinearProgressIndicator(
                        visible: notesLoading,
                      ),
                    ),
                    if (notesData != null) ...[
                      NotesCategorySelect(
                        categories: notesData.map((final note) => note.category).toSet().toList(),
                        onChanged: (final category) {
                          selectedCategory = category;
                        },
                        onSubmitted: submit,
                      ),
                    ],
                  ],
                  ElevatedButton(
                    onPressed: submit,
                    child: Text(AppLocalizations.of(context).notesCreateNote),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
}
