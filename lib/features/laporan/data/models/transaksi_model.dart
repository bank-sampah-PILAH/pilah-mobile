import 'package:flutter/material.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:pilah_mobile/features/laporan/domain/entities/transaksi_entity.dart';

part 'transaksi_model.g.dart';

@JsonSerializable()
class ItemSetoranModel extends ItemSetoranEntity {
  ItemSetoranModel({
    required super.jenis,
    required super.berat,
    required super.harga,
    required super.subtotal,
  });

  factory ItemSetoranModel.fromJson(Map<String, dynamic> json) => _$ItemSetoranModelFromJson(json);

  Map<String, dynamic> toJson() => _$ItemSetoranModelToJson(this);
}

@JsonSerializable(converters: [ColorConverter()], explicitToJson: true)
class TransaksiModel extends TransaksiEntity {
  @override
  final List<ItemSetoranModel> items;

  TransaksiModel({
    required super.initials,
    required super.avatarColor,
    required super.textColor,
    required super.name,
    required super.subtitle,
    required super.amount,
    required super.isWaSuccess,
    super.time,
    required super.balance,
    required this.items,
  }) : super(items: items);

  factory TransaksiModel.fromJson(Map<String, dynamic> json) => _$TransaksiModelFromJson(json);

  Map<String, dynamic> toJson() => _$TransaksiModelToJson(this);
}

@JsonSerializable(explicitToJson: true)
class TransaksiGroupModel extends TransaksiGroupEntity {
  @override
  final List<TransaksiModel> transactions;

  TransaksiGroupModel({
    required super.header,
    required this.transactions,
  }) : super(transactions: transactions);

  factory TransaksiGroupModel.fromJson(Map<String, dynamic> json) => _$TransaksiGroupModelFromJson(json);

  Map<String, dynamic> toJson() => _$TransaksiGroupModelToJson(this);
}

class ColorConverter implements JsonConverter<Color, int> {
  const ColorConverter();

  @override
  Color fromJson(int json) => Color(json);

  @override
  // ignore: deprecated_member_use
  int toJson(Color object) => object.value;
}
