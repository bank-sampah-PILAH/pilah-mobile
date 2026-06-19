import 'package:flutter/material.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:pilah_mobile/features/nasabah/domain/entities/nasabah_entity.dart';

part 'nasabah_model.g.dart';

@JsonSerializable(converters: [ColorConverter()])
class NasabahModel extends NasabahEntity {
  NasabahModel({
    required super.id,
    required super.name,
    required super.phone,
    required super.balance,
    required super.isActive,
    required super.address,
    required super.initials,
    @ColorConverter() required super.avatarColor,
    @ColorConverter() required super.textColor,
  });

  factory NasabahModel.fromJson(Map<String, dynamic> json) => _$NasabahModelFromJson(json);

  Map<String, dynamic> toJson() => _$NasabahModelToJson(this);
}

class ColorConverter implements JsonConverter<Color, int> {
  const ColorConverter();

  @override
  Color fromJson(int json) => Color(json);

  @override
  // ignore: deprecated_member_use
  int toJson(Color object) => object.value;
}
