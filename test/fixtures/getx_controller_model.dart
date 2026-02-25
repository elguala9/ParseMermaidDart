import 'package:freezed_annotation/freezed_annotation.dart';

part 'getx_controller_model.freezed.dart';
part 'getx_controller_model.g.dart';

/// A model class that extends Freezed from freezed_annotation package
/// This demonstrates inheritance from external pub.dev libraries
@freezed
class ProductModel with _$ProductModel {
  const factory ProductModel({
    required String id,
    required String title,
    required double price,
    required String description,
    @Default(0.0) double rating,
  }) = _ProductModel;

  factory ProductModel.fromJson(Map<String, dynamic> json) =>
      _$ProductModelFromJson(json);

  /// Get display price with currency
  String getPriceDisplay() {
    return '\$$price';
  }

  /// Check if product is premium (price > 100)
  bool isPremium() {
    return price > 100;
  }

  /// Check if product is highly rated
  bool isHighlyRated() {
    return rating >= 4.0;
  }
}
