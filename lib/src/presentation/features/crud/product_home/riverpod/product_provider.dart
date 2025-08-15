import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../../core/base/base.dart';
import '../../../../../core/di/dependency_injection.dart';
import '../../../../../domain/entities/product_entity.dart';
import '../../../../../domain/use_cases/product_use_case_domain.dart';

part 'product_provider.g.dart';

@riverpod
class Product extends _$Product {
  late GetProductUseCase _getProductUseCase;
  late DeleteProductUseCase _deleteProductUseCase;

  @override
  Future<List<ProductEntity>> build() async {
    _getProductUseCase = ref.read(getProductUseCaseProvider);
    _deleteProductUseCase = ref.read(deleteProductUseCaseProvider);

    final result = await _getProductUseCase.call();
    return result.when(success: (data) => data, error: (failure) => []);
  }

  Future<void> delete(String id) async {
    state = const AsyncLoading();

    final result = await _deleteProductUseCase.call(id);
    await result.when(
      success: (_) async {
        final refreshed = await _getProductUseCase.call();
        state = refreshed.when(
          success: (data) => AsyncData(data),
          error: (failure) => const AsyncData([]),
        );
      },
      error: (failure) {
        state = AsyncError(failure, StackTrace.current);
      },
    );
  }
}
