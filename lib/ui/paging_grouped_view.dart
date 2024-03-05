import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter_stream_paging/fl_stream_paging.dart';
import 'package:grouped_list/grouped_list.dart';

class PagingGroupedView<PageKeyType, ItemType>
    extends BaseWidget<PageKeyType, ItemType> {
  static const path = '/paging_groped_view';
  const PagingGroupedView({
    super.key,
    this.showNewPageProgressIndicatorAsGridChild = true,
    this.showNewPageErrorIndicatorAsGridChild = true,
    this.showNoMoreItemsIndicatorAsGridChild = true,
    this.isEnablePullToRefresh = true,
    this.invisibleItemsThreshold = 3,
    this.newPageErrorIndicatorBuilder,
    this.newPageCompletedIndicatorBuilder,
    this.newPageProgressIndicatorBuilder,
    this.addItemBuilder,
    this.order,
    this.useStickyGroupSeparators = true,
    this.groupSeparatorBuilder,
    this.floatingHeader = true,
    required super.builderDelegate,
    required super.pageDataSource,
    required this.itemComparator,
    required this.groupBy,
    super.emptyBuilder,
    super.loadingBuilder,
    super.errorBuilder,
    super.refreshBuilder,
  });

  /// Corresponds to [PagedSliverGrid.showNewPageProgressIndicatorAsGridChild].
  final bool showNewPageProgressIndicatorAsGridChild;

  /// Corresponds to [PagedSliverGrid.showNewPageErrorIndicatorAsGridChild].
  final bool showNewPageErrorIndicatorAsGridChild;

  /// Corresponds to [PagedSliverGrid.showNoMoreItemsIndicatorAsGridChild].
  final bool showNoMoreItemsIndicatorAsGridChild;

  final bool isEnablePullToRefresh;

  final int invisibleItemsThreshold;

  final WidgetBuilder? newPageErrorIndicatorBuilder;
  final WidgetBuilder? newPageCompletedIndicatorBuilder;
  final WidgetBuilder? newPageProgressIndicatorBuilder;
  final int Function(ItemType next,ItemType previous) itemComparator;
  final Widget Function(String header) ? groupSeparatorBuilder;
  final String Function(ItemType item) groupBy;
  final AddItemWidgetBuilder<ItemType>? addItemBuilder;
  final bool useStickyGroupSeparators;
  final bool floatingHeader;
  final GroupedListOrder ? order;

  @override
  State<PagingGroupedView<PageKeyType, ItemType>> createState() =>
      _PagingGroupedViewState<PageKeyType, ItemType>();
}

class _PagingGroupedViewState<PageKeyType, ItemType>
    extends State<PagingGroupedView<PageKeyType, ItemType>> {
  PagingState<PageKeyType, ItemType> _pagingState = const PagingState.loading();

  void emit(PagingState<PageKeyType, ItemType> state) {
    if (mounted) {
      setState(() {
        _pagingState = state;
      });
    }
  }

  late DataSource<PageKeyType, ItemType> dataSource;

  Future loadPage({PageKeyType? nextPageKey, bool isRefresh = false}) async {
    var items =
        _pagingState.maybeMap((value) => value.items, orElse: () => null);
    await dataSource.loadPage(isRefresh: isRefresh).then((value) {
      int? itemCount = isRefresh
          ? [...value].length
          : items != null
              ? [...items, ...value].length
              : [...value].length;

      bool hasNextPage = dataSource.currentKey != null && !dataSource.isEndList;

      bool hasItems = itemCount > 0;

      bool isListingUnfinished = hasItems && hasNextPage;

      bool isOngoing = isListingUnfinished;

      bool isCompleted = hasItems && !hasNextPage;

      /// The current pagination status.
      PagingStatus status =
          (isOngoing) ? PagingStatus.ongoing : PagingStatus.completed;

      emit(PagingState<PageKeyType, ItemType>(
          isRefresh
              ? [...value]
              : items != null
                  ? [...items, ...value]
                  : [...value],
          status,
          false));
    }, onError: (e) {
      if (dataSource.currentKey == null) {
        emit(PagingState<PageKeyType, ItemType>.error(e));
      } else {
        _pagingState.maybeMap(
            (value) => emit(PagingState<PageKeyType, ItemType>(
                value.items, PagingStatus.noItemsFound, true)),
            orElse: () => null);
      }
    });
  }

  void copyWith(ItemType newItem, int index) {
    _pagingState.maybeMap((value) {
      var items = [...value.items];
      items[index] = newItem;
      emit(PagingStateData(items, value.status, value.hasRequestNextPage));
    }, orElse: () => null);
  }

  void addItem(ItemType newItem) {
    _pagingState.maybeMap((value) {
      var items = [...value.items, newItem];
      emit(PagingStateData(items, value.status, value.hasRequestNextPage));
    }, orElse: () => null);
  }

  void deleteItem(int index) {
    _pagingState.maybeMap((value) {
      var items = [...value.items];
      items.removeWhere((element) => items.indexOf(element) == index);
      emit(PagingStateData(items, value.status, value.hasRequestNextPage));
    }, orElse: () => null);
  }

  void clearItems() {
    _pagingState.maybeMap((value) {
      var items = [...value.items];
      items.clear();
      dataSource.currentKey = null;
      emit(PagingStateData(items, value.status, false));
      loadPage();
    }, orElse: () => null);
  }

  void requestNextPage({bool hasRequestNextPage = true}) {
    _pagingState.maybeMap(
        (value) => emit(PagingState<PageKeyType, ItemType>(
            value.items, value.status, hasRequestNextPage)),
        orElse: () => null);
  }

  @override
  void initState() {
    super.initState();
    dataSource = widget.pageDataSource;
    dataSource.reLoadFirstPage = clearItems;
    loadPage();
  }

  @override
  Widget build(BuildContext context) {
    return _pagingState.when((items, status, hasRequestNextPage) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Expanded(
            child:GroupedListView<ItemType, String>(
              elements: items,
              groupBy: widget.groupBy,
              groupSeparatorBuilder: widget.groupSeparatorBuilder,
              itemBuilder: (context, dynamic element) => _buildListItemWidget(
                context: context,
                index: items.indexOf(element),
                itemList: items,
                itemCount: items.length,
              ),
              itemComparator: widget.itemComparator, // optional
              useStickyGroupSeparators: widget.useStickyGroupSeparators, // optional
              floatingHeader: widget.floatingHeader, // optional
              order: widget.order ?? GroupedListOrder.ASC, // optional
            ),
          )
        ],
      );
    },
        loading: () => (widget.loadingBuilder != null)
            ? widget.loadingBuilder!(context)
            : const PagingDefaultLoading(),
        error: (error) => widget.errorBuilder != null
            ? widget.errorBuilder!(context, error)
            : ErrorWidget(error));
  }

  Widget _buildListItemWidget(
      {required BuildContext context,
      required int index,
      required List<ItemType> itemList,
      required int itemCount}) {
    var hasRequestedNextPage = _pagingState
        .maybeMap((value) => value.hasRequestNextPage, orElse: () => false);
    if (!hasRequestedNextPage) {
      final newPageRequestTriggerIndex =
          max(0, itemCount - widget.invisibleItemsThreshold);

      final isBuildingTriggerIndexItem = index == newPageRequestTriggerIndex;

      if (!dataSource.isEndList && isBuildingTriggerIndexItem) {
        // Schedules the request for the end of this frame.
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          requestNextPage();
          await loadPage();
          // _pagingController.notifyPageRequestListeners(_nextKey!);
        });
      }
    }

    final item = itemList[index];
    return widget.builderDelegate.itemBuilder(context, item, index, (newItem) {
      copyWith(newItem, index);
    }, () => deleteItem(index), itemList);
  }

  WidgetBuilder _defaultRefreshBuilder(BuildContext context) {
    return (context) => CupertinoSliverRefreshControl(
          refreshTriggerPullDistance: 100.0,
          refreshIndicatorExtent: 60.0,
          onRefresh: () async {
            await loadPage(isRefresh: true);
          },
        );
  }

  Widget _pagingSilverBuilder(
      {required List<ItemType> items, required PagingStatus status}) {
    return PagingSilverBuilder<PageKeyType, ItemType>(
      builderDelegate: widget.builderDelegate,
      completedListingBuilder: (_) => CustomScrollView(
        slivers: [

        ],
      ),
      loadingListingBuilder: (_) => (widget.newPageProgressIndicatorBuilder != null)
          ? widget.newPageProgressIndicatorBuilder!(context)
          : const NewPageProgressIndicator(),
      errorListingBuilder: (_) => (widget.newPageErrorIndicatorBuilder != null)
          ? widget.newPageErrorIndicatorBuilder!(context)
          : const NewPageProgressIndicator(),
      status: status,
      refreshBuilder: (_) => widget.isEnablePullToRefresh
          ? ((widget.refreshBuilder ?? _defaultRefreshBuilder(_))(_))
          : const SliverToBoxAdapter(),
    );
  }
}
