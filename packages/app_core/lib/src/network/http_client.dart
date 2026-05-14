abstract interface class HttpClient {
  Future<HttpResponse> get(
    String path, {
    Map<String, dynamic>? query,
  });
}

class HttpResponse {
  const HttpResponse({
    required this.statusCode,
    required this.body,
  });

  final int statusCode;
  final Map<String, dynamic> body;
}
