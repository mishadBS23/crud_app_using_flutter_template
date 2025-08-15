import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../../models/login_model.dart';
import 'endpoints.dart';

part 'rest_client.g.dart';

@RestApi(baseUrl: Endpoints.base)
abstract class RestClient {
  factory RestClient(
    Dio dio, {
    String? baseUrl,
    ParseErrorLogger? errorLogger,
  }) = _RestClient;

  /// Authentication
  @POST(Endpoints.login)
  Future<HttpResponse> login(@Body() LoginRequestModel request);

  /// Products
  @GET(Endpoints.getProduct)
  Future<HttpResponse> getProducts();

  @POST(Endpoints.createProduct)
  Future<HttpResponse> createProduct({
    @Body() required Map<String, dynamic> body,
  });

  @POST(Endpoints.updateProductPath)
  Future<HttpResponse> updateProduct({
    @Path('id') required String id,
    @Body() required Map<String, dynamic> body,
  });

  @GET(Endpoints.deleteProductPath)
  Future<HttpResponse> deleteProduct({@Path('id') required String id});
}
