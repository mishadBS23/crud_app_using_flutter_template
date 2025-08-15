import '../../core/base/base.dart';
import '../../domain/entities/product_entity.dart';
import '../../domain/repositories/product_repository.dart';
import '../models/product_model.dart';
import '../services/network/rest_client.dart';

final class ProductRepositoryImpl extends ProductRepository {
  ProductRepositoryImpl(this.remote);

  final RestClient remote;

  final List<ProductEntity> _allProducts = [];
  @override
  List<ProductEntity> get allProducts => _allProducts;

  /*  @override
  Future<Result<List<ProductEntity>, Failure>> getProducts() {
    return asyncGuard(() async {
      final response = await remote.getProducts();
      if (response.data['data'] is List) {
        final List<dynamic> rawList = response.data['data'];
        _allProducts.addAll(
          rawList.map((e) => ProductResponseModel.fromJson(e)).toList(),
          //rawList.map((e) => ProductResponseModelMapper.fromJson(e)).toList(),
          */ /*
            - Cleaner: It's easier to read and immediately tells other developers what model you're working with.
            - More maintainable: If you ever decide to change the internal logic of fromJson, you only update it in one place (inside the factory constructor), not everywhere else in the codebase.
            - More idiomatic Dart: It's a Dart convention to use Model.fromJson() when deserializing JSON.
            */ /*
        );

      }

      return _allProducts;
    });
  }*/

  @override
  Future<Result<List<ProductEntity>, Failure>> getProducts() {
    return asyncGuard(() async {
      final response = await remote.getProducts();

      if (response.data['data'] is List) {
        final List<dynamic> rawList = response.data['data'];

        _allProducts
          ..clear()
          ..addAll(
            rawList.map((e) => ProductResponseModel.fromJson(e)).toList(),
          );
      }

      return _allProducts;
    });
  }

  /*@override
  Future<Result<List<ProductEntity>, Failure>> getProducts() async {
    return asyncGuard(() async {
      final response = await remote.getProducts();

      _allProducts
        ..clear()
        ..addAll(
          List<ProductResponseModel>.from(
            response.data.map((e) => ProductResponseModel.fromJson(e)),
          ),
        );

      return _allProducts;
    });
  }*/

  @override
  Future<Result<void, Failure>> deleteProducts(String id) {
    return asyncGuard(() async {
      final res = await remote.deleteProduct(id: id);

      final code = res.response.statusCode ?? 0;
      if (code >= 200 && code < 300) {
        // keep local cache in sync
        _allProducts.removeWhere((e) => e.id == id);
        return;
      }
      throw Exception('Failed to delete product (status: $code)');
    });
  }

  @override
  Future<Result<ProductEntity, Failure>> createProduct(
    ProductEntity product,
  ) async {
    return asyncGuard(() async {
      await remote.createProduct(
        body: ProductResponseModel.fromEntity(product).toJson(),
      );
      return product;
    });
  }

  @override
  Future<Result<ProductEntity, Failure>> updateProduct(
    String id,
    ProductEntity product,
  ) async {
    return asyncGuard(() async {
      await remote.updateProduct(
        id: id,
        body: ProductResponseModel.fromEntity(product).toJson(),
      );
      // Refresh local cache
      await getProducts();
      return product;
    });
  }
}
