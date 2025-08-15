import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../../core/base/base.dart';
import '../../../../../core/di/dependency_injection.dart';
import '../../../../../domain/entities/product_entity.dart';

part 'create_product_provider.g.dart';

@riverpod
class CreateProduct extends _$CreateProduct {
  @override
  Future<ProductEntity?> build() async {
    return null;
  }

  Future<void> create({
    required String productName,
    required String productCode,
    required String img,
    required String unitPrice,
    required String qty,
    required String totalPrice,
  }) async {
    final entity = ProductEntity(
      productName: productName,
      productCode: productCode,
      img: img,
      unitPrice: unitPrice,
      qty: qty,
      totalPrice: totalPrice,
      createdDate: DateTime.now(),
    );

    state = const AsyncValue.loading();

    final repo = ref.read(productRepositoryProvider);
    final result = await repo.createProduct(entity);

    state = result.when(
      success: (data) => AsyncValue.data(data),
      error: (Failure failure) =>
          AsyncValue.error(failure.message, StackTrace.current),
    );
  }
}
