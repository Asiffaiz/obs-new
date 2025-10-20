import 'package:flutter/material.dart';

class MenuItemModel {
  final String id;
  final String title;
  final IconData icon;
  final String? url;
  final List<MenuItemModel> children;
  final bool isExpanded;

  MenuItemModel({
    required this.id,
    required this.title,
    required this.icon,
    this.url,
    this.children = const [],
    this.isExpanded = false,
  });

  MenuItemModel copyWith({
    String? id,
    String? title,
    IconData? icon,
    String? url,
    List<MenuItemModel>? children,
    bool? isExpanded,
  }) {
    return MenuItemModel(
      id: id ?? this.id,
      title: title ?? this.title,
      icon: icon ?? this.icon,
      url: url ?? this.url,
      children: children ?? this.children,
      isExpanded: isExpanded ?? this.isExpanded,
    );
  }

  bool get hasChildren => children.isNotEmpty;
}
