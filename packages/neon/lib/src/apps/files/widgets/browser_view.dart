part of '../app.dart';

class FilesBrowserView extends StatefulWidget {
  const FilesBrowserView({
    required this.bloc,
    required this.filesBloc,
    this.onPickFile,
    this.enableFileActions = true,
    this.enableCreateActions = true,
    this.onlyShowDirectories = false,
    super.key,
    // ignore: prefer_asserts_with_message
  }) : assert((onPickFile == null) == onlyShowDirectories);

  final FilesBrowserBloc bloc;
  final FilesBloc filesBloc;
  final Function(FileDetails)? onPickFile;
  final bool enableFileActions;
  final bool enableCreateActions;
  final bool onlyShowDirectories;

  @override
  State<FilesBrowserView> createState() => _FilesBrowserViewState();
}

class _FilesBrowserViewState extends State<FilesBrowserView> {
  @override
  void initState() {
    super.initState();

    widget.bloc.errors.listen((final error) {
      ExceptionWidget.showSnackbar(context, error);
    });
  }

  @override
  Widget build(final BuildContext context) => StandardRxResultBuilder<FilesBrowserBloc, List<WebDavFile>>(
        bloc: widget.bloc,
        state: (final bloc) => bloc.files,
        builder: (
          final context,
          final filesData,
          final filesError,
          final filesLoading,
          final _,
        ) =>
            StreamBuilder<List<String>>(
          stream: widget.bloc.path,
          builder: (
            final context,
            final pathSnapshot,
          ) =>
              StreamBuilder<List<UploadTask>>(
            stream: widget.filesBloc.uploadTasks,
            builder: (
              final context,
              final uploadTasksSnapshot,
            ) =>
                StreamBuilder<List<DownloadTask>>(
              stream: widget.filesBloc.downloadTasks,
              builder: (
                final context,
                final downloadTasksSnapshot,
              ) =>
                  !pathSnapshot.hasData || !uploadTasksSnapshot.hasData || !downloadTasksSnapshot.hasData
                      ? Container()
                      : Scaffold(
                          resizeToAvoidBottomInset: false,
                          floatingActionButton: widget.enableCreateActions
                              ? FloatingActionButton(
                                  onPressed: () async {
                                    await showDialog(
                                      context: context,
                                      builder: (final context) => FilesChooseCreateDialog(
                                        bloc: widget.filesBloc,
                                        basePath: widget.bloc.path.value,
                                      ),
                                    );
                                  },
                                  child: const Icon(Icons.add),
                                )
                              : null,
                          body: CustomListView<Widget>(
                            scrollKey: 'files-${pathSnapshot.data!.join('/')}',
                            withFloatingActionButton: true,
                            items: [
                              for (final uploadTask in filesData == null
                                  ? <UploadTask>[]
                                  : uploadTasksSnapshot.data!.where(
                                      (final task) => filesData
                                          .where((final file) => _pathMatchesFile(task.path, file.name))
                                          .isEmpty,
                                    )) ...[
                                StreamBuilder<int>(
                                  stream: uploadTask.progress,
                                  builder: (final context, final uploadTaskProgressSnapshot) =>
                                      !uploadTaskProgressSnapshot.hasData
                                          ? Container()
                                          : _buildFile(
                                              context: context,
                                              details: FileDetails(
                                                path: uploadTask.path,
                                                isDirectory: false,
                                                size: uploadTask.size,
                                                etag: null,
                                                mimeType: null,
                                                lastModified: uploadTask.lastModified,
                                                hasPreview: null,
                                                isFavorite: null,
                                              ),
                                              uploadProgress: uploadTaskProgressSnapshot.data!,
                                              downloadProgress: null,
                                            ),
                                ),
                              ],
                              if (filesData != null) ...[
                                for (final file in filesData) ...[
                                  if (!widget.onlyShowDirectories || file.isDirectory) ...[
                                    Builder(
                                      builder: (final context) {
                                        final matchingUploadTasks = uploadTasksSnapshot.data!
                                            .where((final task) => _pathMatchesFile(task.path, file.name));
                                        final matchingDownloadTasks = downloadTasksSnapshot.data!
                                            .where((final task) => _pathMatchesFile(task.path, file.name));

                                        return StreamBuilder<int?>(
                                          stream: matchingUploadTasks.isNotEmpty
                                              ? matchingUploadTasks.first.progress
                                              : Stream.value(null),
                                          builder: (final context, final uploadTaskProgressSnapshot) =>
                                              StreamBuilder<int?>(
                                            stream: matchingDownloadTasks.isNotEmpty
                                                ? matchingDownloadTasks.first.progress
                                                : Stream.value(null),
                                            builder: (final context, final downloadTaskProgressSnapshot) => _buildFile(
                                              context: context,
                                              details: FileDetails(
                                                path: [...widget.bloc.path.value, file.name],
                                                isDirectory: matchingUploadTasks.isEmpty && file.isDirectory,
                                                size: matchingUploadTasks.isNotEmpty
                                                    ? matchingUploadTasks.first.size
                                                    : file.size!,
                                                etag: matchingUploadTasks.isNotEmpty ? null : file.etag,
                                                mimeType: matchingUploadTasks.isNotEmpty ? null : file.mimeType,
                                                lastModified: matchingUploadTasks.isNotEmpty
                                                    ? matchingUploadTasks.first.lastModified
                                                    : file.lastModified!,
                                                hasPreview: matchingUploadTasks.isNotEmpty ? null : file.hasPreview,
                                                isFavorite: matchingUploadTasks.isNotEmpty ? null : file.favorite,
                                              ),
                                              uploadProgress: uploadTaskProgressSnapshot.data,
                                              downloadProgress: downloadTaskProgressSnapshot.data,
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ],
                                ],
                              ],
                            ],
                            isLoading: filesLoading,
                            error: filesError,
                            onRetry: () {
                              widget.bloc.refresh();
                            },
                            onRefresh: () async {
                              widget.bloc.refresh();
                            },
                            builder: (final context, final widget) => widget,
                            topScrollingChildren: [
                              Align(
                                alignment: Alignment.topLeft,
                                child: Container(
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                  ),
                                  child: Wrap(
                                    crossAxisAlignment: WrapCrossAlignment.center,
                                    children: <Widget>[
                                      SizedBox(
                                        height: 40,
                                        child: InkWell(
                                          onTap: () {
                                            widget.bloc.setPath([]);
                                          },
                                          child: const Icon(Icons.house),
                                        ),
                                      ),
                                      for (var i = 0; i < pathSnapshot.data!.length; i++) ...[
                                        InkWell(
                                          onTap: () {
                                            widget.bloc.setPath(pathSnapshot.data!.sublist(0, i + 1));
                                          },
                                          child: Text(pathSnapshot.data![i]),
                                        ),
                                      ],
                                    ]
                                        .intersperse(
                                          const Icon(
                                            Icons.keyboard_arrow_right,
                                            size: 40,
                                          ),
                                        )
                                        .toList(),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
            ),
          ),
        ),
      );

  bool _pathMatchesFile(final List<String> path, final String name) => const ListEquality().equals(
        [...widget.bloc.path.value, name],
        path,
      );

  Widget _buildFile({
    required final BuildContext context,
    required final FileDetails details,
    required final int? uploadProgress,
    required final int? downloadProgress,
  }) =>
      ListTile(
        // When the ETag is null it means we are uploading this file right now
        onTap: details.isDirectory || details.etag != null
            ? () async {
                if (details.isDirectory) {
                  widget.bloc.setPath(details.path);
                } else {
                  if (widget.onPickFile != null) {
                    widget.onPickFile!.call(details);
                  }
                }
              }
            : null,
        title: Text(
          details.name,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Row(
          children: [
            RelativeTime(
              date: details.lastModified,
            ),
            if (details.size > 0) ...[
              const SizedBox(
                width: 10,
              ),
              Text(
                filesize(details.size, 1),
                style: DefaultTextStyle.of(context).style.copyWith(
                      color: Colors.grey,
                    ),
              ),
            ],
          ],
        ),
        leading: SizedBox(
          height: 40,
          width: 40,
          child: Stack(
            children: [
              Center(
                child: uploadProgress != null || downloadProgress != null
                    ? Column(
                        children: [
                          Icon(
                            uploadProgress != null ? MdiIcons.upload : MdiIcons.download,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          LinearProgressIndicator(
                            value: (uploadProgress ?? downloadProgress)! / 100,
                          ),
                        ],
                      )
                    : FilePreview(
                        bloc: widget.filesBloc,
                        details: details,
                        withBackground: true,
                        borderRadius: const BorderRadius.all(Radius.circular(8)),
                      ),
              ),
              if (details.isFavorite ?? false) ...[
                const Align(
                  alignment: Alignment.bottomRight,
                  child: Icon(
                    Icons.star,
                    size: 14,
                    color: Colors.yellow,
                  ),
                ),
              ],
            ],
          ),
        ),
        trailing: uploadProgress == null && downloadProgress == null && widget.enableFileActions
            ? PopupMenuButton<FilesFileAction>(
                itemBuilder: (final context) => [
                  if (details.isFavorite != null) ...[
                    PopupMenuItem(
                      value: FilesFileAction.toggleFavorite,
                      child: Text(
                        details.isFavorite!
                            ? AppLocalizations.of(context).filesRemoveFromFavorites
                            : AppLocalizations.of(context).filesAddToFavorites,
                      ),
                    ),
                  ],
                  PopupMenuItem(
                    value: FilesFileAction.details,
                    child: Text(AppLocalizations.of(context).filesDetails),
                  ),
                  PopupMenuItem(
                    value: FilesFileAction.rename,
                    child: Text(AppLocalizations.of(context).rename),
                  ),
                  PopupMenuItem(
                    value: FilesFileAction.move,
                    child: Text(AppLocalizations.of(context).move),
                  ),
                  PopupMenuItem(
                    value: FilesFileAction.copy,
                    child: Text(AppLocalizations.of(context).copy),
                  ),
                  // TODO: https://github.com/provokateurin/nextcloud-neon/issues/4
                  if (!details.isDirectory) ...[
                    PopupMenuItem(
                      value: FilesFileAction.sync,
                      child: Text(AppLocalizations.of(context).filesSync),
                    ),
                  ],
                  PopupMenuItem(
                    value: FilesFileAction.delete,
                    child: Text(AppLocalizations.of(context).delete),
                  ),
                ],
                onSelected: (final action) async {
                  switch (action) {
                    case FilesFileAction.toggleFavorite:
                      if (details.isFavorite ?? false) {
                        widget.filesBloc.removeFavorite(details.path);
                      } else {
                        widget.filesBloc.addFavorite(details.path);
                      }
                      break;
                    case FilesFileAction.details:
                      await Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (final context) => FilesDetailsPage(
                            bloc: widget.filesBloc,
                            details: details,
                          ),
                        ),
                      );
                      break;
                    case FilesFileAction.rename:
                      final result = await showRenameDialog(
                        context: context,
                        title: details.isDirectory
                            ? AppLocalizations.of(context).filesRenameFolder
                            : AppLocalizations.of(context).filesRenameFile,
                        value: details.name,
                      );
                      if (result != null) {
                        widget.filesBloc.rename(details.path, result);
                      }
                      break;
                    case FilesFileAction.move:
                      final b = widget.filesBloc.getNewFilesBrowserBloc();
                      final originalPath = details.path.sublist(0, details.path.length - 1);
                      b.setPath(originalPath);
                      final result = await showDialog<List<String>?>(
                        context: context,
                        builder: (final context) => FilesChooseFolderDialog(
                          bloc: b,
                          filesBloc: widget.filesBloc,
                          originalPath: originalPath,
                        ),
                      );
                      b.dispose();
                      if (result != null) {
                        widget.filesBloc.move(details.path, result..add(details.name));
                      }
                      break;
                    case FilesFileAction.copy:
                      final b = widget.filesBloc.getNewFilesBrowserBloc();
                      final originalPath = details.path.sublist(0, details.path.length - 1);
                      b.setPath(originalPath);
                      final result = await showDialog<List<String>?>(
                        context: context,
                        builder: (final context) => FilesChooseFolderDialog(
                          bloc: b,
                          filesBloc: widget.filesBloc,
                          originalPath: originalPath,
                        ),
                      );
                      b.dispose();
                      if (result != null) {
                        widget.filesBloc.copy(details.path, result..add(details.name));
                      }
                      break;
                    case FilesFileAction.sync:
                      final sizeWarning = widget.bloc.options.downloadSizeWarning.value;
                      if (sizeWarning != null && details.size > sizeWarning) {
                        if (!(await showConfirmationDialog(
                          context,
                          AppLocalizations.of(context).filesConfirmDownloadSizeWarning(
                            filesize(sizeWarning),
                            filesize(details.size),
                          ),
                        ))) {
                          return;
                        }
                      }
                      widget.filesBloc.syncFile(details.path);
                      break;
                    case FilesFileAction.delete:
                      if (await showConfirmationDialog(
                        context,
                        details.isDirectory
                            ? AppLocalizations.of(context).filesDeleteFolderConfirm(details.name)
                            : AppLocalizations.of(context).filesDeleteFileConfirm(details.name),
                      )) {
                        widget.filesBloc.delete(details.path);
                      }
                      break;
                  }
                },
              )
            : const SizedBox(
                width: 48,
                height: 48,
              ),
      );
}

enum FilesFileAction {
  toggleFavorite,
  details,
  rename,
  move,
  copy,
  sync,
  delete,
}
