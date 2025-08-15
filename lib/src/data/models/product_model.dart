import 'package:dart_mappable/dart_mappable.dart';

import '../../domain/entities/product_entity.dart';

part 'product_model.mapper.dart';

@MappableClass(
  generateMethods: GenerateMethods.encode | GenerateMethods.decode,
  caseStyle: CaseStyle.pascalCase,
)
class ProductResponseModel extends ProductEntity
    with ProductResponseModelMappable {
  ProductResponseModel({
    super.productName,
    super.productCode,
    super.img,
    super.unitPrice,
    super.qty,
    super.totalPrice,
    super.createdDate,
    @MappableField(key: '_id') super.id,
  }) : super();

  /// 🔁 Converts from entity to model (for POSTing data)
  factory ProductResponseModel.fromEntity(ProductEntity entity) {
    return ProductResponseModel(
      productName: entity.productName,
      productCode: entity.productCode,
      img: entity.img,
      unitPrice: entity.unitPrice,
      qty: entity.qty,
      totalPrice: entity.totalPrice,
      createdDate: entity.createdDate,
      id: entity.id,
    );
  }

  factory ProductResponseModel.fromJson(Map<String, dynamic> json) {
    return ProductResponseModelMapper.fromJson(json);
  }
}
