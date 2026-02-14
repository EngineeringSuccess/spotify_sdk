import 'package:json_annotation/json_annotation.dart';

part 'content_item.g.dart';

@JsonSerializable()
class ContentItem {
  ContentItem(
    this.id,
    this.uri,
    this.title,
    this.subtitle,
    this.imageUri, {
    required this.playable,
    required this.hasChildren,
  });

  final String? id;
  final String? uri;
  final String? title;
  final String? subtitle;
  @JsonKey(name: 'image_uri')
  final String? imageUri;
  @JsonKey(name: 'playable')
  final bool playable;
  @JsonKey(name: 'has_children')
  final bool hasChildren;

  factory ContentItem.fromJson(Map<String, dynamic> json) =>
      _$ContentItemFromJson(json);

  Map<String, dynamic> toJson() => _$ContentItemToJson(this);
}
