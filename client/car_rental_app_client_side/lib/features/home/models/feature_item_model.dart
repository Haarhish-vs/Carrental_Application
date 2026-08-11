import 'package:flutter/material.dart';

/// Lightweight, reusable model for icon+text content blocks
/// (Why Choose Us, Why Our Platform, etc). Kept separate from
/// CategoryModel because these carry an optional subtitle.
class FeatureItemModel {
  final String id;
  final IconData icon;
  final String title;
  final String? subtitle;

  const FeatureItemModel({
    required this.id,
    required this.icon,
    required this.title,
    this.subtitle,
  });
}
