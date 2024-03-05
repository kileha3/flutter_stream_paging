import 'package:flutter/material.dart';
import 'package:flutter_stream_paging/fl_stream_paging.dart';
import 'package:flutter_stream_paging/ui/paging_grouped_view.dart';
import 'package:flutter_stream_paging_example/datasource/list_view_page.dart';
import 'package:flutter_stream_paging_example/datasource/models/note.dart';
import 'package:flutter_stream_paging_example/datasource/note_repository.dart';
import 'package:flutter_stream_paging_example/widgets/note_widget.dart';

class GroupedViewDemoPage extends StatefulWidget {
  const GroupedViewDemoPage({super.key});

  @override
  GroupedViewDemoPageState createState() => GroupedViewDemoPageState();
}

class GroupedViewDemoPageState extends State<GroupedViewDemoPage> {
  final GlobalKey key = GlobalKey();
  late ListViewDataSource dataSource;
  @override
  void initState() {
    super.initState();
    dataSource = ListViewDataSource(NoteRepository());
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        PagingGroupedView<int, Note>(
          builderDelegate: PagedChildBuilderDelegate(
            itemBuilder: (context, data, child, onUpdate, onDelete, dataList) {
              return NoteWidget(data);
            },
          ),
          pageDataSource: dataSource,
          groupSeparatorBuilder: (String groupByValue) => Text(groupByValue),
          itemComparator: (Note next, Note previous) => next.label.compareTo(previous.label),
          groupBy: (Note item) => item.label,
        ),
        Align(
          alignment: Alignment.topRight,
          child: IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () => dataSource.reLoadFirstPage!(),
          ),
        )
      ],
    );
  }
}
