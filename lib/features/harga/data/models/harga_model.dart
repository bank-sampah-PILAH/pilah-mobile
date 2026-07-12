import 'package:flutter/material.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:pilah_mobile/features/harga/domain/entities/harga_entity.dart';

part 'harga_model.g.dart';

@JsonSerializable(converters: [ColorConverter(), IconDataConverter()])
class HargaModel extends HargaEntity {
  HargaModel({
    required super.id,
    required super.kodeSampah,
    required super.name,
    required super.price,
    required super.priceFormatted,
    required super.category,
    required super.subtitle,
    required super.badgeText,
    required super.icon,
    required super.iconColor,
    required super.isActive,
  });

  factory HargaModel.fromJson(Map<String, dynamic> json) => _$HargaModelFromJson(json);

  Map<String, dynamic> toJson() => _$HargaModelToJson(this);
}

class ColorConverter implements JsonConverter<Color, int> {
  const ColorConverter();

  @override
  Color fromJson(int json) => Color(json);

  @override
  // ignore: deprecated_member_use
  int toJson(Color object) => object.value;
}

class IconDataConverter implements JsonConverter<IconData, int> {
  const IconDataConverter();

  @override
  IconData fromJson(int json) => IconData(json, fontFamily: 'MaterialIcons');

  @override
  int toJson(IconData object) => object.codePoint;
}
