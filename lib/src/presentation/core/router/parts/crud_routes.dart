part of '../router.dart';

List<GoRoute> _crudRoutes(Ref ref) {
  return [
    GoRoute(
      path: Routes.productHome,
      name: Routes.productHome,
      builder: (context, state) => const ProductHomeView(),
    ),
    GoRoute(
      path: Routes.addProduct,
      name: Routes.addProduct,
      builder: (context, state) => const AddProductView(),
    ),
    GoRoute(
      path: Routes.updateProduct,
      name: Routes.updateProduct,
      builder: (context, state) {
        final product = state.extra as ProductEntity;

        return UpdateProductView(
          id: product.id!,
          productId: product.productCode ?? '',
          productName: product.productName ?? '',
          image: product.img ?? '',
          unitPrice: product.unitPrice ?? '',
          qty: product.qty ?? '',
          totalPrice: product.totalPrice ?? '',
          productCode: product.productCode ?? '',
        );
      },
    ),
  ];
}
