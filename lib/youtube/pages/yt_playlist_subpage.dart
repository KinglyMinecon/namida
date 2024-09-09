import 'package:flutter/material.dart';

import 'package:flutter_sticky_header/flutter_sticky_header.dart';
import 'package:playlist_manager/module/playlist_id.dart';
import 'package:youtipie/class/execute_details.dart';
import 'package:youtipie/class/result_wrapper/list_wrapper_base.dart';
import 'package:youtipie/class/result_wrapper/playlist_mix_result.dart';
import 'package:youtipie/class/result_wrapper/playlist_result.dart';
import 'package:youtipie/class/result_wrapper/playlist_result_base.dart';
import 'package:youtipie/class/stream_info_item/stream_info_item.dart';
import 'package:youtipie/class/youtipie_feed/playlist_basic_info.dart';
import 'package:youtipie/class/youtipie_feed/playlist_info_item_user.dart';
import 'package:youtipie/youtipie.dart';

import 'package:namida/base/pull_to_refresh.dart';
import 'package:namida/base/youtube_streams_manager.dart';
import 'package:namida/class/route.dart';
import 'package:namida/controller/navigator_controller.dart';
import 'package:namida/controller/player_controller.dart';
import 'package:namida/controller/settings_controller.dart';
import 'package:namida/core/constants.dart';
import 'package:namida/core/dimensions.dart';
import 'package:namida/core/enums.dart';
import 'package:namida/core/extensions.dart';
import 'package:namida/core/icon_fonts/broken_icons.dart';
import 'package:namida/core/namida_converter_ext.dart';
import 'package:namida/core/themes.dart';
import 'package:namida/core/translations/language.dart';
import 'package:namida/core/utils.dart';
import 'package:namida/ui/pages/subpages/most_played_subpage.dart';
import 'package:namida/ui/pages/subpages/playlist_tracks_subpage.dart';
import 'package:namida/ui/widgets/custom_widgets.dart';
import 'package:namida/ui/widgets/settings/extra_settings.dart';
import 'package:namida/youtube/class/youtube_id.dart';
import 'package:namida/youtube/controller/youtube_history_controller.dart';
import 'package:namida/youtube/controller/youtube_info_controller.dart';
import 'package:namida/youtube/controller/youtube_playlist_controller.dart';
import 'package:namida/youtube/functions/yt_playlist_utils.dart';
import 'package:namida/youtube/pages/yt_playlist_download_subpage.dart';
import 'package:namida/youtube/widgets/yt_history_video_card.dart';
import 'package:namida/youtube/widgets/yt_thumbnail.dart';
import 'package:namida/youtube/widgets/yt_video_card.dart';

class YTMostPlayedVideosPage extends StatelessWidget with NamidaRouteWidget {
  @override
  RouteType get route => RouteType.YOUTUBE_MOST_PLAYED_SUBPAGE;

  const YTMostPlayedVideosPage({super.key});

  MostPlayedItemsPage getMainWidget(List<String> videos) {
    final ytIds = videos
        .map(
          (e) => YoutubeID(
            id: e,
            playlistID: const PlaylistID(id: k_PLAYLIST_NAME_MOST_PLAYED),
          ),
        )
        .toList();
    return MostPlayedItemsPage(
      itemExtent: Dimensions.youtubeCardItemExtent,
      historyController: YoutubeHistoryController.inst,
      customDateRange: settings.ytMostPlayedCustomDateRange,
      activeTimeRangeChip: settings.ytMostPlayedTimeRange,
      onSavingTimeRange: ({dateCustom, isStartOfDay, mptr}) {
        settings.save(
          ytMostPlayedTimeRange: mptr,
          ytMostPlayedCustomDateRange: dateCustom,
          ytMostPlayedCustomisStartOfDay: isStartOfDay,
        );
      },
      header: (timeRangeChips, bottomPadding) {
        return Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: timeRangeChips,
        );
      },
      itemBuilder: (context, i, listensMap) {
        final videoID = videos[i];
        final listens = listensMap[videoID] ?? [];

        return YTHistoryVideoCard(
          key: Key("${videoID}_$i"),
          videos: ytIds,
          index: i,
          day: null,
          overrideListens: listens,
          playlistID: const PlaylistID(id: k_PLAYLIST_NAME_MOST_PLAYED),
          playlistName: '',
          canHaveDuplicates: false,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Obx(
      (context) {
        final videos = YoutubeHistoryController.inst.currentMostPlayedTracks.toList();
        return getMainWidget(videos);
      },
    );
  }
}

class YTLikedVideosPage extends StatelessWidget with NamidaRouteWidget {
  @override
  RouteType get route => RouteType.YOUTUBE_LIKED_SUBPAGE;

  const YTLikedVideosPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const YTNormalPlaylistSubpage(
      playlistName: k_PLAYLIST_NAME_FAV,
      isEditable: false,
      reversedList: true,
    );
  }
}

class YTNormalPlaylistSubpage extends StatefulWidget with NamidaRouteWidget {
  @override
  String? get name => playlistName;

  @override
  RouteType get route => RouteType.YOUTUBE_PLAYLIST_SUBPAGE;

  final String playlistName;
  final bool isEditable;
  final bool reversedList;

  const YTNormalPlaylistSubpage({
    super.key,
    required this.playlistName,
    this.isEditable = true,
    this.reversedList = false,
  });

  @override
  State<YTNormalPlaylistSubpage> createState() => _YTNormalPlaylistSubpageState();
}

class _YTNormalPlaylistSubpageState extends State<YTNormalPlaylistSubpage> {
  Color? bgColor;
  String playlistCurrentName = ''; // to refresh after renaming

  @override
  void initState() {
    playlistCurrentName = widget.playlistName;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    const horizontalBigThumbPadding = 12.0;
    final maxWidth = context.width;
    final bigThumbWidth = maxWidth - horizontalBigThumbPadding * 2;
    Color? threeCColor;
    late final threeC = ObxO(
      rx: YoutubePlaylistController.inst.canReorderVideos,
      builder: (context, canReorderVideos) => ThreeLineSmallContainers(enabled: canReorderVideos, color: threeCColor),
    );
    return AnimatedTheme(
      duration: const Duration(milliseconds: 300),
      data: AppThemes.inst.getAppTheme(bgColor, !context.isDarkMode),
      child: BackgroundWrapper(
        child: NamidaScrollbarWithController(
          child: (sc) => Obx(
            (context) {
              YoutubePlaylistController.inst.playlistsMap.valueR;
              final playlist = YoutubePlaylistController.inst.getPlaylist(playlistCurrentName);
              if (playlist == null) return const SizedBox();
              final firstID = playlist.tracks.firstOrNull?.id;
              return CustomScrollView(
                controller: sc,
                slivers: [
                  SliverToBoxAdapter(
                    child: Stack(
                      children: [
                        YoutubeThumbnail(
                          type: ThumbnailType.playlist,
                          key: Key("$firstID"),
                          width: maxWidth,
                          height: maxWidth * 9 / 16,
                          compressed: true,
                          isImportantInCache: false,
                          videoId: firstID,
                          blur: 0.0,
                          borderRadius: 0.0,
                          extractColor: true,
                          onColorReady: (color) async {
                            if (color != null) {
                              await Future.delayed(const Duration(milliseconds: 200)); // navigation delay
                              refreshState(() {
                                bgColor = color.color;
                              });
                            }
                          },
                        ),
                        const Positioned.fill(
                          child: ClipRect(
                            child: NamidaBgBlur(
                              blur: 30.0,
                              child: ColoredBox(color: Colors.transparent),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: horizontalBigThumbPadding, vertical: 12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              YoutubeThumbnail(
                                type: ThumbnailType.playlist,
                                key: Key("$firstID"),
                                width: bigThumbWidth,
                                height: (bigThumbWidth * 9 / 16),
                                compressed: false,
                                isImportantInCache: true,
                                videoId: firstID,
                                blur: 4.0,
                              ),
                              const SizedBox(height: 24.0),
                              Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          playlistCurrentName.translatePlaylistName(),
                                          style: context.textTheme.displayLarge,
                                        ),
                                        const SizedBox(height: 6.0),
                                        Text(
                                          playlist.tracks.length.displayVideoKeyword,
                                          style: context.textTheme.displaySmall,
                                        ),
                                        if (playlist.comment != '') ...[
                                          const SizedBox(height: 2.0),
                                          Text(
                                            playlist.comment,
                                            style: context.textTheme.displaySmall,
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  NamidaIconButton(
                                    iconColor: context.defaultIconColor(bgColor),
                                    icon: Broken.shuffle,
                                    tooltip: () => lang.SHUFFLE,
                                    onPressed: () => Player.inst.playOrPause(0, playlist.tracks, QueueSource.others, shuffle: true),
                                  ),
                                  NamidaIconButton(
                                    iconColor: context.defaultIconColor(bgColor),
                                    icon: Broken.play_cricle,
                                    tooltip: () => lang.PLAY_LAST,
                                    onPressed: () => Player.inst.addToQueue(playlist.tracks, insertNext: false),
                                  ),
                                  NamidaIconButton(
                                    iconColor: context.defaultIconColor(bgColor),
                                    icon: Broken.import,
                                    onPressed: () async {
                                      YTPlaylistDownloadPage(
                                        ids: playlist.tracks,
                                        playlistName: playlistCurrentName,
                                        infoLookup: const {},
                                        playlistInfo: PlaylistBasicInfo(
                                          id: playlist.playlistID.id,
                                          title: playlist.name,
                                          videosCountText: playlist.tracks.length.toString(),
                                          videosCount: playlist.tracks.length,
                                          thumbnails: [],
                                        ),
                                      ).navigate();
                                    },
                                  ),
                                  NamidaPopupWrapper(
                                    openOnLongPress: false,
                                    childrenDefault: () => [
                                      NamidaPopupItem(
                                        icon: Broken.share,
                                        title: lang.SHARE,
                                        onTap: playlist.shareVideos,
                                      ),
                                      if (widget.isEditable) ...[
                                        NamidaPopupItem(
                                          icon: Broken.edit_2,
                                          title: lang.RENAME_PLAYLIST,
                                          onTap: () async {
                                            final newName = await playlist.showRenamePlaylistSheet(context: context, playlistName: playlistCurrentName);
                                            if (newName == null) return;
                                            refreshState(() => playlistCurrentName = newName);
                                          },
                                        ),
                                        NamidaPopupItem(
                                          icon: Broken.trash,
                                          title: lang.DELETE_PLAYLIST,
                                          onTap: () async {
                                            final didDelete = await playlist.promptDelete(name: playlistCurrentName, colorScheme: bgColor);
                                            if (didDelete) NamidaNavigator.inst.popPage();
                                          },
                                        ),
                                      ],
                                    ],
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                                      child: Icon(
                                        Broken.more_2,
                                        color: context.defaultIconColor(bgColor),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        )
                      ],
                    ),
                  ),
                  const SliverPadding(padding: EdgeInsets.only(bottom: 24.0)),
                  ObxO(
                    rx: YoutubePlaylistController.inst.canReorderVideos,
                    builder: (context, canReorderVideos) => NamidaSliverReorderableList(
                      onReorder: (oldIndex, newIndex) => YoutubePlaylistController.inst.reorderTrack(playlist, oldIndex, newIndex),
                      itemExtent: Dimensions.youtubeCardItemExtent,
                      itemCount: playlist.tracks.length,
                      itemBuilder: (context, index) {
                        return YTHistoryVideoCard(
                          key: ValueKey(index),
                          videos: playlist.tracks,
                          index: index,
                          reversedList: widget.reversedList,
                          day: null,
                          playlistID: playlist.playlistID,
                          playlistName: playlistCurrentName,
                          draggingEnabled: YoutubePlaylistController.inst.canReorderVideos.value,
                          openMenuOnLongPress: !canReorderVideos,
                          draggableThumbnail: true,
                          showMoreIcon: true,
                          draggingBarsBuilder: (color) {
                            threeCColor ??= color;
                            return threeC;
                          },
                          draggingThumbnailBuilder: (draggingTrigger) {
                            return ObxO(
                              rx: YoutubePlaylistController.inst.canReorderVideos,
                              builder: (context, canReorderVideos) => canReorderVideos ? draggingTrigger : const SizedBox(),
                            );
                          },
                          canHaveDuplicates: true,
                        );
                      },
                    ),
                  ),
                  kBottomPaddingWidgetSliver,
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class YTHostedPlaylistSubpage extends StatefulWidget with NamidaRouteWidget {
  @override
  String? get name => playlist.basicInfo.title;
  @override
  RouteType get route => RouteType.YOUTUBE_PLAYLIST_SUBPAGE_HOSTED;

  final YoutiPiePlaylistResultBase playlist;
  final PlaylistInfoItemUser? userPlaylist;
  final bool isMixPlaylist;

  const YTHostedPlaylistSubpage({
    super.key,
    required this.playlist,
    required this.userPlaylist,
  }) : isMixPlaylist = playlist is YoutiPieMixPlaylistResult;

  YTHostedPlaylistSubpage.fromId({
    super.key,
    required String playlistId,
    required this.userPlaylist,
  })  : playlist = _EmptyPlaylistResult(playlistId: playlistId),
        isMixPlaylist = playlistId.startsWith('RD') && playlistId.length == 13;

  @override
  State<YTHostedPlaylistSubpage> createState() => _YTHostedPlaylistSubpageState();
}

class _YTHostedPlaylistSubpageState extends State<YTHostedPlaylistSubpage> with YoutubeStreamsManager, TickerProviderStateMixin, PullToRefreshMixin {
  @override
  double get maxDistance => 64.0;

  @override
  List<StreamInfoItem> get streamsList => _playlist.items;

  @override
  YoutiPieListWrapper<StreamInfoItem>? get listWrapper => _playlist;

  @override
  ScrollController get scrollController => _controller;

  @override
  Color? get sortChipBGColor => bgColor?.withOpacity(0.6);

  @override
  void onSortChanged(void Function() fn) => refreshState(fn);

  @override
  void onListChange(void Function() fn) => refreshState(fn);

  @override
  bool canRefreshList(_) => true;

  late final ScrollController _controller;
  final _isLoadingMoreItems = false.obs;

  YoutiPieFetchAllRes? _currentFetchAllRes;

  late YoutiPiePlaylistResultBase _playlist;

  late final YoutiPiePlaylistEditCallbacks _playlistInfoEditUpdater = YoutiPiePlaylistEditCallbacks(
    oldPlaylist: () => _playlist,
    newPlaylistCallback: (newPlaylist) {
      refreshState(() => _playlist = newPlaylist);
    },
  );

  @override
  void initState() {
    // we eventually need to implement playlist sort if account is signed in.
    _playlist = widget.playlist;
    _controller = ScrollController();
    super.initState();

    final cached = YoutiPie.cacheBuilder.forPlaylistVideos(playlistId: _playlist.basicInfo.id).read();
    if (cached != null) {
      _playlist = cached;
      refreshState(trySortStreams);
    }

    onRefresh(() => _fetch100Video(forceRequest: _playlist is YoutiPiePlaylistResult), forceProceed: true);

    YtUtilsPlaylist.activePlaylists.add(_playlistInfoEditUpdater);
  }

  @override
  void dispose() {
    _isLoadingMoreItems.close();
    disposeResources();
    YtUtilsPlaylist.activePlaylists.remove(_playlistInfoEditUpdater);
    super.dispose();
  }

  Color? bgColor;

  Future<List<YoutubeID>> _getAllPlaylistVideos() async {
    return await _playlist.basicInfo.fetchAllPlaylistAsYTIDs(showProgressSheet: true, playlistToFetch: _playlist);
  }

  Future<bool> _fetch100Video({bool forceRequest = false}) async {
    if (_isLoadingMoreItems.value) return false;
    _isLoadingMoreItems.value = true;

    bool fetched = false;

    try {
      final currentPlaylist = _playlist;
      if (forceRequest || currentPlaylist.items.isEmpty) {
        YoutiPiePlaylistResultBase? newPlaylist;
        if (widget.isMixPlaylist) {
          final mixId = currentPlaylist.basicInfo.id;
          final mixVideoId = mixId.substring(2);
          newPlaylist = await YoutubeInfoController.playlist.getMixPlaylist(
            videoId: mixVideoId,
            mixId: mixId,
            details: ExecuteDetails.forceRequest(),
          );
        } else {
          String? plId;
          if (currentPlaylist is YoutiPiePlaylistResult) plId = currentPlaylist.playlistId;
          plId ??= currentPlaylist.basicInfo.id;
          newPlaylist = await YoutubeInfoController.playlist.fetchPlaylist(
            playlistId: plId,
            details: ExecuteDetails.forceRequest(),
          );
        }
        if (newPlaylist != null) {
          _playlist = newPlaylist;
          fetched = true;
        }
      } else {
        if (currentPlaylist.canFetchNext) {
          fetched = await currentPlaylist.fetchNext();
        }
      }
    } catch (_) {}

    _isLoadingMoreItems.value = false;
    if (fetched) refreshState(trySortStreams);
    return fetched;
  }

  @override
  Widget build(BuildContext context) {
    const horizontalBigThumbPadding = 12.0;
    final maxWidth = context.width;
    final bigThumbWidth = maxWidth - horizontalBigThumbPadding * 2;
    final playlist = _playlist;

    const itemsThumbnailHeight = Dimensions.youtubeThumbnailHeight;
    const itemsThumbnailWidth = Dimensions.youtubeThumbnailWidth;
    const itemsThumbnailItemExtent = itemsThumbnailHeight + 8.0 * 2;

    String? description;
    String uploaderTitleAndViews = '';
    String? thumbnailUrl;
    String? plId;

    if (playlist is YoutiPiePlaylistResult) {
      description = playlist.info.description;
      final uploaderTitle = playlist.info.uploader?.title;
      final viewsCount = playlist.info.viewsCount;
      final viewsCountText = viewsCount == null ? playlist.info.viewsCountText : viewsCount.displayViewsKeywordShort;
      uploaderTitleAndViews = [
        if (uploaderTitle != null) uploaderTitle,
        if (viewsCountText != null) viewsCountText,
      ].join(' - ');
      thumbnailUrl = playlist.info.thumbnails.pick()?.url;
      plId = playlist.playlistId;
    }

    String? videosCountTextFinal;
    final videosCount = playlist.basicInfo.videosCount;
    if (playlist is YoutiPieMixPlaylistResult) {
      videosCountTextFinal = videosCount?.displayVideoKeyword;
    } else if (playlist is YoutiPiePlaylistResult) {
      videosCountTextFinal = videosCount?.displayVideoKeyword;
    }
    videosCountTextFinal ??= playlist.basicInfo.videosCountText ?? '?';

    plId ??= playlist.basicInfo.id;
    final plIdWrapper = PlaylistID(id: plId);
    final firstID = playlist.items.firstOrNull?.id;
    final hasMoreStreamsLeft = playlist.canFetchNext;
    return AnimatedTheme(
      duration: const Duration(milliseconds: 300),
      data: AppThemes.inst.getAppTheme(bgColor, !context.isDarkMode),
      child: BackgroundWrapper(
        child: PullToRefreshWidget(
          state: this,
          controller: _controller,
          onRefresh: () => _fetch100Video(forceRequest: true),
          child: LazyLoadListView(
            scrollController: _controller,
            onReachingEnd: _fetch100Video,
            listview: (controller) => NamidaScrollbar(
              controller: controller,
              child: CustomScrollView(
                controller: controller,
                slivers: [
                  SliverToBoxAdapter(
                    child: Stack(
                      children: [
                        YoutubeThumbnail(
                          type: ThumbnailType.playlist,
                          key: Key("$firstID"),
                          width: maxWidth,
                          height: maxWidth * 9 / 16,
                          compressed: true,
                          isImportantInCache: false,
                          preferLowerRes: true,
                          // customUrl: thumbnailUrl,
                          videoId: firstID,
                          blur: 0.0,
                          borderRadius: 0.0,
                          extractColor: true,
                          onColorReady: (color) async {
                            if (color != null) {
                              await Future.delayed(const Duration(milliseconds: 200)); // navigation delay
                              refreshState(() {
                                bgColor = color.color;
                              });
                            }
                          },
                        ),
                        const Positioned.fill(
                          child: ClipRect(
                            child: NamidaBgBlur(
                              blur: 30.0,
                              child: ColoredBox(color: Colors.transparent),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: horizontalBigThumbPadding, vertical: 12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              YoutubeThumbnail(
                                type: ThumbnailType.playlist,
                                key: Key("$firstID"),
                                width: bigThumbWidth,
                                height: (bigThumbWidth * 9 / 16),
                                compressed: false,
                                isImportantInCache: true,
                                preferLowerRes: false,
                                customUrl: thumbnailUrl,
                                videoId: firstID,
                                blur: 4.0,
                              ),
                              const SizedBox(height: 24.0),
                              Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          playlist.basicInfo.title,
                                          style: context.textTheme.displayLarge,
                                        ),
                                        const SizedBox(height: 6.0),
                                        Text(
                                          videosCountTextFinal ?? '',
                                          style: context.textTheme.displaySmall,
                                        ),
                                        if (uploaderTitleAndViews.isNotEmpty == true) ...[
                                          const SizedBox(height: 2.0),
                                          Text(
                                            uploaderTitleAndViews,
                                            style: context.textTheme.displaySmall,
                                          ),
                                        ],
                                        if (description != null && description.isNotEmpty) ...[
                                          const SizedBox(height: 2.0),
                                          Text(
                                            description,
                                            style: context.textTheme.displaySmall,
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  NamidaIconButton(
                                    iconColor: context.defaultIconColor(bgColor),
                                    icon: Broken.shuffle,
                                    tooltip: () => lang.SHUFFLE,
                                    onPressed: () async {
                                      final videos = await _getAllPlaylistVideos();
                                      Player.inst.playOrPause(0, videos, QueueSource.others, shuffle: true);
                                    },
                                  ),
                                  NamidaIconButton(
                                    iconColor: context.defaultIconColor(bgColor),
                                    icon: Broken.play_cricle,
                                    tooltip: () => lang.PLAY_LAST,
                                    onPressed: () async {
                                      final videos = await _getAllPlaylistVideos();
                                      Player.inst.addToQueue(videos, insertNext: false);
                                    },
                                  ),
                                  NamidaIconButton(
                                    iconColor: context.defaultIconColor(bgColor),
                                    icon: Broken.import,
                                    onPressed: () async {
                                      final infoLookup = <String, StreamInfoItem>{};
                                      playlist.items.loop((e) => infoLookup[e.id] = e);

                                      final videos = await _getAllPlaylistVideos();
                                      YTPlaylistDownloadPage(
                                        ids: videos,
                                        playlistName: playlist.basicInfo.title,
                                        infoLookup: infoLookup,
                                        playlistInfo: playlist.basicInfo,
                                      ).navigate();
                                    },
                                  ),
                                  NamidaPopupWrapper(
                                    openOnLongPress: false,
                                    childrenDefault: () => playlist.basicInfo.getPopupMenuItems(
                                      context: context,
                                      playlistToFetch: _playlist,
                                      userPlaylist: widget.userPlaylist,
                                      showProgressSheet: true,
                                      displayDownloadItem: false,
                                      displayShuffle: false,
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                                      child: Icon(
                                        Broken.more_2,
                                        color: context.defaultIconColor(bgColor),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        )
                      ],
                    ),
                  ),
                  const SliverPadding(padding: EdgeInsets.only(bottom: 4.0)),
                  SliverStickyHeader(
                    header: ColoredBox(
                      color: context.theme.scaffoldBackgroundColor,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
                        child: Row(
                          children: [
                            Expanded(
                              child: sortWidget,
                            ),
                            ObxO(
                              rx: _isLoadingMoreItems,
                              builder: (context, isLoadingMoreItems) => NamidaInkWellButton(
                                animationDurationMS: 100,
                                sizeMultiplier: 0.95,
                                borderRadius: 8.0,
                                icon: Broken.task_square,
                                text: lang.LOAD_ALL,
                                enabled: !isLoadingMoreItems && hasMoreStreamsLeft, // this for lazylist
                                disableWhenLoading: false,
                                showLoadingWhenDisabled: hasMoreStreamsLeft,
                                onTap: () async {
                                  if (_currentFetchAllRes != null) {
                                    _currentFetchAllRes?.cancel();
                                    _currentFetchAllRes = null;
                                  } else {
                                    _playlist.basicInfo.fetchAllPlaylistStreams(
                                      playlist: _playlist,
                                      showProgressSheet: false,
                                      onStart: () => _isLoadingMoreItems.value = true,
                                      onEnd: () => _isLoadingMoreItems.value = false,
                                      controller: (fetchAllRes) => _currentFetchAllRes = fetchAllRes,
                                    );
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    sliver: SliverFixedExtentList.builder(
                      itemExtent: itemsThumbnailItemExtent,
                      itemCount: playlist.items.length,
                      itemBuilder: (context, index) {
                        final item = playlist.items[index];
                        return YoutubeVideoCard(
                          thumbnailHeight: itemsThumbnailHeight,
                          thumbnailWidth: itemsThumbnailWidth,
                          isImageImportantInCache: false,
                          video: item,
                          playlistID: plIdWrapper,
                          playlist: playlist,
                          playlistIndexAndCount: (index: index, totalLength: playlist.basicInfo.videosCount ?? playlist.items.length, playlistId: playlist.basicInfo.id),
                        );
                      },
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: ObxO(
                      rx: _isLoadingMoreItems,
                      builder: (context, isLoadingMoreItems) => isLoadingMoreItems
                          ? const Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  LoadingIndicator(),
                                ],
                              ),
                            )
                          : const SizedBox(),
                    ),
                  ),
                  kBottomPaddingWidgetSliver,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// not meant for usage, just a placeholder instead of nullifying everything
class _EmptyPlaylistResult extends YoutiPiePlaylistResultBase {
  _EmptyPlaylistResult({
    required String playlistId,
  }) : super(
          basicInfo: PlaylistBasicInfo(id: playlistId, title: '', videosCountText: null, videosCount: null, thumbnails: []),
          items: [],
          cacheKey: null,
          continuation: null,
        );

  @override
  Future<bool> fetchNextFunction(ExecuteDetails? details) async {
    return false;
  }

  @override
  Map<String, dynamic> toMap() {
    return {};
  }
}
