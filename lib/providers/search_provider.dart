import 'package:flutter/material.dart';

class SearchProvider with ChangeNotifier {
  String _searchQuery = '';
  String _activeTab = 'Note';

  String get searchQuery => _searchQuery;
  String get activeTab => _activeTab;

  void updateSearchQuery(String query) {
    _searchQuery = query.toLowerCase();
    if (_searchQuery.isNotEmpty && _activeTab == 'User') {
      _activeTab = 'Note';
    }
    notifyListeners();
  }

  void setActiveTab(String tab) {
    _activeTab = tab;
    notifyListeners();
  }

  void clearSearch() {
    _searchQuery = '';
    notifyListeners();
  }
}