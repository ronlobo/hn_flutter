class HNConfig {
  static final HNConfig _singleton = new HNConfig._internal();

  factory HNConfig () {
    return _singleton;
  }

  HNConfig._internal();

  final String apiHost = 'https://news.ycombinator.com';

  final String path = 'https://hacker-news.firebaseio.com';
  final String version = 'v0';
  // final String url = '${HNConfig._singleton.path}/${HNConfig._singleton.version}';
  String get url => '$path/$version';
}
