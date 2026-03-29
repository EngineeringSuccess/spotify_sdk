// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'content_item.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ContentItem _$ContentItemFromJson(Map<String, dynamic> json) => ContentItem(
      json['id'] as String?,
      json['uri'] as String?,
      json['title'] as String?,
      json['subtitle'] as String?,
      json['image_uri'] as String?,
      playable: json['playable'] as bool,
      hasChildren: json['has_children'] as bool,
    );

Map<String, dynamic> _$ContentItemToJson(ContentItem instance) =>
    <String, dynamic>{
      'id': instance.id,
      'uri': instance.uri,
      'title': instance.title,
      'subtitle': instance.subtitle,
      'image_uri': instance.imageUri,
      'playable': instance.playable,
      'has_children': instance.hasChildren,
    };
