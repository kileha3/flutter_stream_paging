import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_stream_paging/fl_stream_paging.dart';
import 'package:flutter_stream_paging_example/datasource/list_view_page.dart';
import 'package:flutter_stream_paging_example/datasource/models/note.dart';
import 'package:flutter_stream_paging_example/datasource/note_repository.dart';
import 'package:flutter_stream_paging_example/widgets/note_widget.dart';

class ListViewDemoPage extends StatefulWidget {
  const ListViewDemoPage(
      {super.key,
      this.shrinkWrap = false,
      this.physics,
      this.buildFirstPage = true});
  final bool shrinkWrap;
  final ScrollPhysics? physics;
  final bool buildFirstPage;

  @override
  ListViewDemoPageState createState() => ListViewDemoPageState();
}

class ListViewDemoPageState extends State<ListViewDemoPage> {
  final GlobalKey key = GlobalKey();
  late ListViewDataSource dataSource;
  bool isExtend = false;
  @override
  void initState() {
    super.initState();
    dataSource = ListViewDataSource(NoteRepository());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          PagingListView<int, Note>.separated(
            key: key,
            reverse: true,
            builderDelegate: PagedChildBuilderDelegate<Note>(
              itemBuilder: (context, data, child, onUpdate, onDelete, dataList) {
                return Column(
                  children: [
                    NoteWidget(
                      data,
                      onChanged: () {
                        var newData =
                        Note(data.id, data.title, 'new content ${data.id}', "hey");
                        onUpdate(newData);
                      },
                      onDeleted: () {
                        onDelete();
                      },
                    ),
                    ElevatedButton(
                        onPressed: () {
                          setState(() {
                            isExtend = !isExtend;
                          });
                        },
                        child: const Text('extend')),
                    if (isExtend)
                      const Padding(
                        padding: EdgeInsets.only(left: 16),
                        child: ListViewDemoPage(
                          shrinkWrap: true,
                          physics: NeverScrollableScrollPhysics(),
                          buildFirstPage: false,
                        ),
                      )
                  ],
                );
              },
            ),
            pageDataSource: dataSource,
            shrinkWrap: widget.shrinkWrap,
            physics: widget.physics,
            separatorBuilder: (_, index, item, items) {
              return const SizedBox(
                height: 20,
              );
            },
            errorBuilder: (_, err) => const SizedBox(),
            // newPageProgressIndicatorBuilder: (_, onPressed) {
            //   return ElevatedButton(
            //       onPressed: onPressed, child: const Text('loadmore'));
            // },
            invisibleItemsThreshold: 3,
            addItemBuilder: widget.buildFirstPage ? (context, onAddItem) {
              return Row(
                children: [
                  Expanded(child: TextFormField()),
                  ElevatedButton(
                      onPressed: () {
                        var newData = Note(DateTime.now().hashCode, 'This add title',
                            'This add content', "Done");
                        onAddItem(newData);
                      },
                      child: const Text('add')),
                ],
              );
            } : null,
            // padding: EdgeInsets.only(top: 30),
          ),
          Align(
            alignment: Alignment.topRight,
            child: IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () => dataSource.reLoadFirstPage!(),
            ),
          )
        ],
      ),
      floatingActionButton: FloatingActionButton(child: Icon(Icons.add),onPressed: () {
        dataSource.addItemOnList!(Note(DateTime.now().hashCode, 'This add title',
            'This add content ${DateTime.now().toIso8601String()}', "Done"));
      },),
    );
  }
}
