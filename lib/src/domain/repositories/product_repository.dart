import '../../core/base/base.dart';
import '../entities/product_entity.dart';

abstract base class ProductRepository extends Repository {
  Future<Result<List<ProductEntity>, Failure>> getProducts();
  Future<Result<void, Failure>> deleteProducts(String id);
  List<ProductEntity> get allProducts;
  Future<Result<ProductEntity, Failure>> createProduct(ProductEntity entity);
  Future<Result<ProductEntity, Failure>> updateProduct(
    String id,
    ProductEntity entity,
  );
}
