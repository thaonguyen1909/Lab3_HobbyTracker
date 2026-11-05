import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../l10n/app_strings.dart';
import '../../../models/spotify_music.dart';
import '../../../viewmodels/spotify_controller.dart';
import '../../../widgets/hobby_card.dart';

class SpotifyPanel extends ConsumerStatefulWidget {
  const SpotifyPanel({super.key});
  @override
  ConsumerState<SpotifyPanel> createState() => _SpotifyPanelState();
}

class _SpotifyPanelState extends ConsumerState<SpotifyPanel>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      ref.read(spotifyControllerProvider.notifier).resumeConnection();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(spotifyControllerProvider);
    final vm = ref.read(spotifyControllerProvider.notifier);
    return HobbyCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Spotify', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          const AppText(
            'Choose your music while you focus. Playback uses the Spotify app.',
          ),
          const SizedBox(height: 12),
          if (!state.supported)
            const AppText('Spotify playback is available on Android.')
          else if (!state.linked)
            FilledButton.icon(
              key: const ValueKey('spotify-connect'),
              onPressed: state.busy ? null : vm.connect,
              icon: const Icon(Icons.headphones),
              label: AppText(
                state.busy ? 'Connecting Spotify…' : 'Connect Spotify',
              ),
            )
          else ...[
            if (state.profile != null)
              Text(
                state.profile!.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            const SizedBox(height: 8),
            if (state.playback.track.isNotEmpty) ...[
              Text(
                state.playback.track,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              Text(
                state.playback.artist,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ] else
              const AppText('Select a playlist to start playing.'),
            if (!state.playback.connected)
              const AppText(
                'Playback controls will reconnect when you use them.',
              ),
            Wrap(
              spacing: 8,
              children: [
                IconButton(
                  tooltip: context.tr('Previous track'),
                  onPressed: state.busy ? null : () => vm.command('previous'),
                  icon: const Icon(Icons.skip_previous),
                ),
                IconButton(
                  key: const ValueKey('spotify-toggle'),
                  tooltip: context.tr(
                    state.playback.paused ? 'Resume music' : 'Pause music',
                  ),
                  onPressed: state.busy
                      ? null
                      : () => vm.command(
                          state.playback.paused ? 'resume' : 'pause',
                        ),
                  icon: Icon(
                    state.playback.paused ? Icons.play_arrow : Icons.pause,
                  ),
                ),
                IconButton(
                  tooltip: context.tr('Next track'),
                  onPressed: state.busy ? null : () => vm.command('next'),
                  icon: const Icon(Icons.skip_next),
                ),
              ],
            ),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  key: const ValueKey('spotify-playlists'),
                  onPressed: state.busy
                      ? null
                      : () => showModalBottomSheet<void>(
                          context: context,
                          isScrollControlled: true,
                          useSafeArea: true,
                          builder: (_) => const _PlaylistPicker(),
                        ),
                  icon: const Icon(Icons.queue_music),
                  label: const AppText('My Spotify playlists'),
                ),
                OutlinedButton.icon(
                  key: const ValueKey('spotify-paste'),
                  onPressed: state.busy
                      ? null
                      : () async {
                          final link = await showDialog<String>(
                            context: context,
                            builder: (_) => const _PlaylistLinkDialog(),
                          );
                          if (mounted && link != null) await vm.playLink(link);
                        },
                  icon: const Icon(Icons.link),
                  label: const AppText('Paste playlist link'),
                ),
              ],
            ),
            if (state.selected != null)
              TextButton.icon(
                onPressed: state.busy ? null : () => vm.play(state.selected!),
                icon: const Icon(Icons.replay),
                label: Text(
                  '${context.tr('Play again')}: ${state.selected!.name == 'Playlist from link' ? context.tr('Playlist from link') : state.selected!.name}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            TextButton(
              onPressed: state.busy ? null : vm.disconnect,
              child: const AppText('Disconnect Spotify'),
            ),
          ],
          if (state.busy || state.loading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: LinearProgressIndicator(),
            ),
          if (state.error != null)
            Semantics(
              liveRegion: true,
              child: AppText(
                state.error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          const SizedBox(height: 8),
          const AppText('Music and the practice timer have separate controls.'),
        ],
      ),
    );
  }
}

class _PlaylistPicker extends ConsumerWidget {
  const _PlaylistPicker();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(spotifyControllerProvider);
    final vm = ref.read(spotifyControllerProvider.notifier);
    return SizedBox(
      height: MediaQuery.sizeOf(context).height * .8,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Expanded(child: AppText('My Spotify playlists')),
                IconButton(
                  tooltip: context.tr('Close'),
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const AppText(
              'Choose an owned or followed playlist, or paste a full playlist link from Spotify.',
            ),
            if (state.loading || state.busy) const LinearProgressIndicator(),
            if (state.error != null)
              AppText(
                state.error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            Expanded(
              child: state.items.isEmpty
                  ? Center(
                      child: AppText(
                        state.loading
                            ? 'Loading playlists…'
                            : 'No playlists yet. Create or follow one in Spotify, or paste a link.',
                      ),
                    )
                  : ListView.builder(
                      itemCount: state.items.length,
                      itemBuilder: (context, index) {
                        final playlist = state.items[index];
                        return ListTile(
                          leading: const Icon(Icons.queue_music),
                          title: Text(playlist.name),
                          trailing: Icon(
                            state.selected?.id == playlist.id
                                ? Icons.check_circle
                                : Icons.play_arrow,
                          ),
                          onTap: state.busy
                              ? null
                              : () async {
                                  await vm.play(playlist);
                                  if (context.mounted &&
                                      ref
                                              .read(spotifyControllerProvider)
                                              .error ==
                                          null) {
                                    Navigator.pop(context);
                                  }
                                },
                        );
                      },
                    ),
            ),
            Wrap(
              spacing: 8,
              children: [
                TextButton(
                  onPressed: state.loading || state.busy
                      ? null
                      : () => vm.loadPlaylists(),
                  child: const AppText('Refresh playlists'),
                ),
                if (state.nextOffset != null)
                  TextButton(
                    onPressed: state.loading || state.busy
                        ? null
                        : () => vm.loadPlaylists(more: true),
                    child: const AppText('Load more'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PlaylistLinkDialog extends StatefulWidget {
  const _PlaylistLinkDialog();
  @override
  State<_PlaylistLinkDialog> createState() => _PlaylistLinkDialogState();
}

class _PlaylistLinkDialogState extends State<_PlaylistLinkDialog> {
  final _link = TextEditingController();
  String? _error;
  @override
  void dispose() {
    _link.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const AppText('Paste playlist link'),
    content: SingleChildScrollView(
      child: TextField(
        controller: _link,
        autofocus: true,
        keyboardType: TextInputType.url,
        autocorrect: false,
        maxLength: 2048,
        decoration: InputDecoration(
          labelText: context.tr('Spotify playlist link'),
          hintText: 'https://open.spotify.com/playlist/…',
          errorText: _error == null ? null : context.tr(_error!),
        ),
        onSubmitted: (_) => _submit(),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const AppText('Cancel'),
      ),
      FilledButton(onPressed: _submit, child: const AppText('Play playlist')),
    ],
  );
  void _submit() {
    try {
      spotifyPlaylistId(_link.text);
      Navigator.pop(context, _link.text.trim());
    } on SpotifyFailure catch (error) {
      setState(() => _error = error.message);
    }
  }
}
