import 'package:PiliPlus/http/fav.dart';
import 'package:PiliPlus/http/loading_state.dart';
import 'package:PiliPlus/models_new/fav/fav_folder/data.dart';
import 'package:PiliPlus/models_new/fav/fav_folder/list.dart';
import 'package:PiliPlus/pages/common/common_list_controller.dart';
import 'package:PiliPlus/utils/accounts.dart';
import 'package:PiliPlus/utils/storage.dart';

class FavController extends CommonListController<FavFolderData, FavFolderInfo> {
  late final account = Accounts.main;

  @override
  void onInit() {
    super.onInit();
    queryData();
  }

  @override
  List<FavFolderInfo>? getDataList(FavFolderData response) {
    if (response.hasMore == false) {
      isEnd = true;
    }
    return response.list;
  }

  @override
  Future<LoadingState<FavFolderData>> customGetData() {
    if (!account.isLogin) {
      String firstCover = '';
      if (GStorage.localFavorites.isNotEmpty) {
        final firstVal = GStorage.localFavorites.values.firstOrNull;
        if (firstVal is Map) {
          firstCover = (firstVal['pic'] ?? firstVal['cover'] ?? '').toString();
        }
      }
      final list = <FavFolderInfo>[
        FavFolderInfo(
          id: -1,
          fid: -1,
          mid: 0,
          title: '本地收藏',
          cover: firstCover,
          mediaCount: GStorage.localFavorites.length,
        ),
      ];
      isEnd = true;
      return Future.value(Success(FavFolderData(count: 1, list: list, hasMore: false)));
    }
    return FavHttp.userfavFolder(
      pn: page,
      ps: 20,
      mid: account.mid,
    );
  }
}

