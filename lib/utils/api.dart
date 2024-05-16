import 'package:dio/dio.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import 'package:supmti_events/utils/box.dart';

final baseConfig = BaseOptions(
  connectTimeout: const Duration(seconds: 30),
  receiveTimeout: const Duration(seconds: 30),
  headers: {
    'Accept': 'application/json',
  },
);

final apiProvider = Provider<Dio>((ref) {
  // final idToken = await ref.watch(authProviderFirebase).user?.getIdToken();
  final dio = Dio(baseConfig);
  dio.interceptors.add(PrettyDioLogger(
      requestHeader: true,
      requestBody: true,
      responseBody: true,
      responseHeader: false,
      error: true,
      compact: true,
      maxWidth: 90));
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest:
          (RequestOptions options, RequestInterceptorHandler handler) async {
        final idToken = Box.getToken();

        if (idToken != null) {
          options.headers.update('Authorization', (value) => 'Bearer $idToken',
              ifAbsent: () => 'Bearer $idToken');
        }

        return handler.next(options);
      },
      onResponse: (Response response, ResponseInterceptorHandler handler) {
        return handler.next(response);
      },
      onError: (DioException error, ErrorInterceptorHandler handler) async {
        if (error.response?.statusCode == 401) {
          await Box.clearToken();
        }
        return handler.next(error);
      },
    ),
  );
  return dio;
});
