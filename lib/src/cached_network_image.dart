import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui show instantiateImageCodec, Codec;
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:http/http.dart';

import 'package:http_client_helper/http_client_helper.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:transparent_image/transparent_image.dart';
import 'package:crypto/crypto.dart';

const String cacheImageFolderName = "extenedtext";

class CachedNetworkImage extends ImageProvider<CachedNetworkImage> {
  /// Creates an object that fetches the image at the given URL.
  ///
  /// The arguments must not be null.
  CachedNetworkImage(this.url,
      {this.scale = 1.0,
      this.headers,
      this.cache: false,
      this.retries = 3,
      this.timeLimit,
      this.timeRetry = const Duration(milliseconds: 100)})
      : assert(url != null),
        assert(scale != null);

  ///time Limit to request image
  final Duration timeLimit;

  ///the time to retry to request
  final int retries;

  ///the time duration to retry to request
  final Duration timeRetry;

  ///whether cache image to local
  final bool cache;

  /// The URL from which the image will be fetched.
  final String url;

  /// The scale to place in the [ImageInfo] object of the image.
  final double scale;

  /// The HTTP headers that will be used with [HttpClient.get] to fetch image from network.
  final Map<String, String> headers;

  bool loadFailed = false;

  @override
  ImageStreamCompleter load(CachedNetworkImage key) {
    // TODO: implement load
    return MultiFrameImageStreamCompleter(
        codec: _loadAsync(key),
        scale: key.scale,
        informationCollector: (StringBuffer information) {
          information.writeln('Image provider: $this');
          information.write('Image key: $key');
        });
  }

  @override
  Future<CachedNetworkImage> obtainKey(ImageConfiguration configuration) {
    // TODO: implement obtainKey
    return SynchronousFuture<CachedNetworkImage>(this);
  }

  Future<ui.Codec> _loadAsync(CachedNetworkImage key) async {
    assert(key == this);
    final md5Key = toMd5(key.url);
    ui.Codec reuslt;
    if (cache) {
      try {
        var data = await _loadCache(key, md5Key);
        if (data != null) {
          loadFailed = false;
          reuslt = await ui.instantiateImageCodec(data);
        }
      } catch (e) {
        print(e);
      }
    }

    if (reuslt == null) {
      try {
        var data = await _loadNetwork(key);
        if (data != null) {
          loadFailed = false;
          reuslt = await ui.instantiateImageCodec(data);
        }
      } catch (e) {
        print(e);
      }
    }

    if (reuslt == null) {
      loadFailed = true;
      reuslt = await ui.instantiateImageCodec(kTransparentImage);
    }

    return reuslt;
  }

  ///get the image from cache folder.
  Future<Uint8List> _loadCache(CachedNetworkImage key, String md5Key) async {
    Directory _cacheImagesDirectory = Directory(
        join((await getTemporaryDirectory()).path, cacheImageFolderName));
    //exist, try to find cache image file
    if (_cacheImagesDirectory.existsSync()) {
      File cacheFlie = File(join(_cacheImagesDirectory.path, md5Key));
      if (cacheFlie.existsSync()) {
        return await cacheFlie.readAsBytes();
      }
    }
    //create folder
    else {
      await _cacheImagesDirectory.create();
    }

    //load from network
    Uint8List data = await _loadNetwork(key);
    if (data != null) {
      //cache image file
      await (File(join(_cacheImagesDirectory.path, md5Key))).writeAsBytes(data);
      return data;
    }

    return null;
  }

  /// get the image from network.
  Future<Uint8List> _loadNetwork(CachedNetworkImage key) async {
    try {
      Response response = await HttpClientHelper.get(url,
          headers: headers,
          timeLimit: key.timeLimit,
          timeRetry: key.timeRetry,
          retries: key.retries);
      return response.bodyBytes;
    } catch (e) {}
    return null;
  }

  @override
  bool operator ==(dynamic other) {
    if (other.runtimeType != runtimeType) return false;
    final CachedNetworkImage typedOther = other;
    return url == typedOther.url && scale == typedOther.scale;
  }

  @override
  int get hashCode => hashValues(url, scale);

  @override
  String toString() => '$runtimeType("$url", scale: $scale)';
}

String toMd5(String str) => md5.convert(utf8.encode(str)).toString();

/// Clear the disk cache directory then return if it succeed.
///  <param name="duration">timespan to compute whether file has expired or not</param>
Future<bool> clearExtendedTextDiskCachedImages({Duration duration}) async {
  try {
    Directory _cacheImagesDirectory = Directory(
        join((await getTemporaryDirectory()).path, cacheImageFolderName));
    if (_cacheImagesDirectory.existsSync()) {
      if (duration == null) {
        _cacheImagesDirectory.deleteSync(recursive: true);
      } else {
        var now = DateTime.now();
        for (var file in _cacheImagesDirectory.listSync()) {
          FileStat fs = file.statSync();
          if (now.subtract(duration).isAfter(fs.changed)) {
            //print("remove expired cached image");
            file.deleteSync(recursive: true);
          }
        }
      }
    }
  } catch (_) {
    return false;
  }
  return true;
}
