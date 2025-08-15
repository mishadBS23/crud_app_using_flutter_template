part of '../dependency_injection.dart';

@riverpod
LoginUseCase loginUseCase(Ref ref) {
  return LoginUseCase(ref.read(authenticationRepositoryProvider));
}

@riverpod
CheckRememberMeUseCase checkRememberMeUseCase(Ref ref) {
  return CheckRememberMeUseCase(ref.read(authenticationRepositoryProvider));
}

@riverpod
SaveRememberMeUseCase saveRememberMeUseCase(Ref ref) {
  return SaveRememberMeUseCase(ref.read(authenticationRepositoryProvider));
}

@riverpod
LogoutUseCase logoutUseCase(Ref ref) {
  return LogoutUseCase(ref.read(authenticationRepositoryProvider));
}

@riverpod
GetCurrentLocaleUseCase getCurrentLocaleUseCase(Ref ref) {
  return GetCurrentLocaleUseCase(ref.read(localeRepositoryProvider));
}

@riverpod
SetCurrentLocaleUseCase setCurrentLocaleUseCase(Ref ref) {
  return SetCurrentLocaleUseCase(ref.read(localeRepositoryProvider));
}

@riverpod
GetProductUseCase getProductUseCase(Ref ref) {
  return GetProductUseCase(ref.read(productRepositoryProvider));
}

@riverpod
DeleteProductUseCase deleteProductUseCase(Ref ref) {
  return DeleteProductUseCase(ref.read(productRepositoryProvider));
}

@riverpod
CreateProductUseCase createProductUseCase(Ref ref) {
  return CreateProductUseCase(ref.read(productRepositoryProvider));
}

@riverpod
UpdateProductUseCase updateProductUseCase(Ref ref) {
  return UpdateProductUseCase(ref.read(productRepositoryProvider));
}
