import '../../core/base/base.dart';
import '../entities/product_entity.dart';
import '../repositories/product_repository.dart';

class GetProductUseCase {
  GetProductUseCase(this.repository);
  final ProductRepository repository;

  Future<Result<List<ProductEntity>, Failure>> call() {
    final itemCount = repository.allProducts.length;
    return repository.getProducts();
  }
}

class DeleteProductUseCase {
  DeleteProductUseCase(this.repository);

  final ProductRepository repository;

  Future<Result<void, Failure>> call(String id) {
    return repository.deleteProducts(id);
  }
}

class CreateProductUseCase {
  CreateProductUseCase(this.repository);

  final ProductRepository repository;
  Future<Result<void, Failure>> call(ProductEntity product) {
    return repository.createProduct(product);
  }
}

class UpdateProductUseCase {
  UpdateProductUseCase(this.repository);
  final ProductRepository repository;
  Future<Result<void, Failure>> call(String id, ProductEntity product) {
    return repository.updateProduct(id, product);
  }
}
