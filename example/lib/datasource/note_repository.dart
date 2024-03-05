import 'package:flutter_stream_paging_example/datasource/models/note.dart';

class NoteRepository {
  Future<List<Note>> getNotes(int pageIndex) async {
    print("Fetching page index - $pageIndex");
    if (pageIndex == 2) {
      throw 'test err';
    } else if(pageIndex == 4){
      return [];
    } else {
      List<Note> datas = [];
      for (var i = 0; i < 20; i++) {
        datas.add(Note.fakeId(i + 20 * pageIndex));
      }
      return Future.delayed(const Duration(milliseconds: 500), () => datas);
    }
  }
}
