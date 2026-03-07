import 'data_service.dart';
import 'user_data_service.dart';

/// In-memory cache so JSON assets are only parsed once per session.
/// Call invalidate*() after user mutates data.
class DataCache {
  static final DataCache instance = DataCache._();
  DataCache._();

  List<Map<String, dynamic>>? _cbItems;
  List<Map<String, dynamic>>? _fimItems;
  List<Map<String, dynamic>>? _pnItems; // base + user

  Future<List<Map<String, dynamic>>> getCbItems() async {
    _cbItems ??= await DataService.loadJson('assets/cb_data.json');
    return _cbItems!;
  }

  Future<List<Map<String, dynamic>>> getFimItems() async {
    _fimItems ??= await DataService.loadJson('assets/fim_data.json');
    return _fimItems!;
  }

  Future<List<Map<String, dynamic>>> getAllPnItems() async {
    if (_pnItems == null) {
      final base = await DataService.loadJson('assets/pn_data.json');
      final user = await UserDataService.getUserPnItems();
      _pnItems = [...base, ...user];
    }
    return _pnItems!;
  }

  void invalidatePn() => _pnItems = null;
}
