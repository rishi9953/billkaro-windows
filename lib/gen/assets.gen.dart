// dart format width=80

/// GENERATED CODE - DO NOT MODIFY BY HAND
/// *****************************************************
///  FlutterGen
/// *****************************************************

// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: deprecated_member_use,directives_ordering,implicit_dynamic_list_literal,unnecessary_import

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart' as _svg;
import 'package:vector_graphics/vector_graphics.dart' as _vg;

class $AssetsLottieGen {
  const $AssetsLottieGen();

  /// File path: assets/lottie/ChatWhatsApp.json
  String get chatWhatsApp => 'assets/lottie/ChatWhatsApp.json';

  /// File path: assets/lottie/ConnectionLost.json
  String get connectionLost => 'assets/lottie/ConnectionLost.json';

  /// File path: assets/lottie/Emptybox.json
  String get emptybox => 'assets/lottie/Emptybox.json';

  /// File path: assets/lottie/Fail.json
  String get fail => 'assets/lottie/Fail.json';

  /// File path: assets/lottie/Loader.json
  String get loader => 'assets/lottie/Loader.json';

  /// File path: assets/lottie/LocationPin.json
  String get locationPin => 'assets/lottie/LocationPin.json';

  /// File path: assets/lottie/Success.json
  String get success => 'assets/lottie/Success.json';

  /// File path: assets/lottie/Verification.json
  String get verification => 'assets/lottie/Verification.json';

  /// File path: assets/lottie/addproduct.json
  String get addproduct => 'assets/lottie/addproduct.json';

  /// File path: assets/lottie/developer.json
  String get developer => 'assets/lottie/developer.json';

  /// File path: assets/lottie/items.json
  String get items => 'assets/lottie/items.json';

  /// File path: assets/lottie/loading.json
  String get loading => 'assets/lottie/loading.json';

  /// File path: assets/lottie/sales.json
  String get sales => 'assets/lottie/sales.json';

  /// File path: assets/lottie/staff.json
  String get staff => 'assets/lottie/staff.json';

  /// File path: assets/lottie/translatelanguage.json
  String get translatelanguage => 'assets/lottie/translatelanguage.json';

  /// File path: assets/lottie/usingmobilephone.json
  String get usingmobilephone => 'assets/lottie/usingmobilephone.json';

  /// List of all assets
  List<String> get values => [
    chatWhatsApp,
    connectionLost,
    emptybox,
    fail,
    loader,
    locationPin,
    success,
    verification,
    addproduct,
    developer,
    items,
    loading,
    sales,
    staff,
    translatelanguage,
    usingmobilephone,
  ];
}

class $AssetsSvgGen {
  const $AssetsSvgGen();

  /// File path: assets/svg/Small shop.svg
  SvgGenImage get smallShop => const SvgGenImage('assets/svg/Small shop.svg');

  /// File path: assets/svg/bank.svg
  SvgGenImage get bank => const SvgGenImage('assets/svg/bank.svg');

  /// File path: assets/svg/calendar.svg
  SvgGenImage get calendar => const SvgGenImage('assets/svg/calendar.svg');

  /// File path: assets/svg/categories.svg
  SvgGenImage get categories => const SvgGenImage('assets/svg/categories.svg');

  /// File path: assets/svg/delete.svg
  SvgGenImage get delete => const SvgGenImage('assets/svg/delete.svg');

  /// File path: assets/svg/excel.svg
  SvgGenImage get excel => const SvgGenImage('assets/svg/excel.svg');

  /// File path: assets/svg/export.svg
  SvgGenImage get export => const SvgGenImage('assets/svg/export.svg');

  /// File path: assets/svg/group.svg
  SvgGenImage get group => const SvgGenImage('assets/svg/group.svg');

  /// File path: assets/svg/home.svg
  SvgGenImage get home => const SvgGenImage('assets/svg/home.svg');

  /// File path: assets/svg/items.svg
  SvgGenImage get items => const SvgGenImage('assets/svg/items.svg');

  /// File path: assets/svg/menu.svg
  SvgGenImage get menu => const SvgGenImage('assets/svg/menu.svg');

  /// File path: assets/svg/pdf.svg
  SvgGenImage get pdf => const SvgGenImage('assets/svg/pdf.svg');

  /// File path: assets/svg/placeholder.svg
  SvgGenImage get placeholder =>
      const SvgGenImage('assets/svg/placeholder.svg');

  /// File path: assets/svg/print.svg
  SvgGenImage get print => const SvgGenImage('assets/svg/print.svg');

  /// File path: assets/svg/reports.svg
  SvgGenImage get reports => const SvgGenImage('assets/svg/reports.svg');

  /// File path: assets/svg/swiggy.svg
  SvgGenImage get swiggy => const SvgGenImage('assets/svg/swiggy.svg');

  /// File path: assets/svg/whatsapp.svg
  SvgGenImage get whatsapp => const SvgGenImage('assets/svg/whatsapp.svg');

  /// File path: assets/svg/zomato.svg
  SvgGenImage get zomato => const SvgGenImage('assets/svg/zomato.svg');

  /// List of all assets
  List<SvgGenImage> get values => [
    smallShop,
    bank,
    calendar,
    categories,
    delete,
    excel,
    export,
    group,
    home,
    items,
    menu,
    pdf,
    placeholder,
    print,
    reports,
    swiggy,
    whatsapp,
    zomato,
  ];
}

class Assets {
  const Assets._();

  static const String aEnv = '.env';
  static const AssetGenImage dineIn = AssetGenImage('assets/Dine In.png');
  static const AssetGenImage takeaway = AssetGenImage('assets/Takeaway.png');
  static const AssetGenImage delivery = AssetGenImage('assets/delivery.png');
  static const AssetGenImage logo = AssetGenImage('assets/logo.jpeg');
  static const $AssetsLottieGen lottie = $AssetsLottieGen();
  static const AssetGenImage pdf = AssetGenImage('assets/pdf.png');
  static const AssetGenImage plan = AssetGenImage('assets/plan.png');
  static const AssetGenImage printer = AssetGenImage('assets/printer.png');
  static const $AssetsSvgGen svg = $AssetsSvgGen();

  /// List of all assets
  static List<dynamic> get values => [
    aEnv,
    dineIn,
    takeaway,
    delivery,
    logo,
    pdf,
    plan,
    printer,
  ];
}

class AssetGenImage {
  const AssetGenImage(
    this._assetName, {
    this.size,
    this.flavors = const {},
    this.animation,
  });

  final String _assetName;

  final Size? size;
  final Set<String> flavors;
  final AssetGenImageAnimation? animation;

  Image image({
    Key? key,
    AssetBundle? bundle,
    ImageFrameBuilder? frameBuilder,
    ImageErrorWidgetBuilder? errorBuilder,
    String? semanticLabel,
    bool excludeFromSemantics = false,
    double? scale,
    double? width,
    double? height,
    Color? color,
    Animation<double>? opacity,
    BlendMode? colorBlendMode,
    BoxFit? fit,
    AlignmentGeometry alignment = Alignment.center,
    ImageRepeat repeat = ImageRepeat.noRepeat,
    Rect? centerSlice,
    bool matchTextDirection = false,
    bool gaplessPlayback = true,
    bool isAntiAlias = false,
    String? package,
    FilterQuality filterQuality = FilterQuality.medium,
    int? cacheWidth,
    int? cacheHeight,
  }) {
    return Image.asset(
      _assetName,
      key: key,
      bundle: bundle,
      frameBuilder: frameBuilder,
      errorBuilder: errorBuilder,
      semanticLabel: semanticLabel,
      excludeFromSemantics: excludeFromSemantics,
      scale: scale,
      width: width,
      height: height,
      color: color,
      opacity: opacity,
      colorBlendMode: colorBlendMode,
      fit: fit,
      alignment: alignment,
      repeat: repeat,
      centerSlice: centerSlice,
      matchTextDirection: matchTextDirection,
      gaplessPlayback: gaplessPlayback,
      isAntiAlias: isAntiAlias,
      package: package,
      filterQuality: filterQuality,
      cacheWidth: cacheWidth,
      cacheHeight: cacheHeight,
    );
  }

  ImageProvider provider({AssetBundle? bundle, String? package}) {
    return AssetImage(_assetName, bundle: bundle, package: package);
  }

  String get path => _assetName;

  String get keyName => _assetName;
}

class AssetGenImageAnimation {
  const AssetGenImageAnimation({
    required this.isAnimation,
    required this.duration,
    required this.frames,
  });

  final bool isAnimation;
  final Duration duration;
  final int frames;
}

class SvgGenImage {
  const SvgGenImage(this._assetName, {this.size, this.flavors = const {}})
    : _isVecFormat = false;

  const SvgGenImage.vec(this._assetName, {this.size, this.flavors = const {}})
    : _isVecFormat = true;

  final String _assetName;
  final Size? size;
  final Set<String> flavors;
  final bool _isVecFormat;

  _svg.SvgPicture svg({
    Key? key,
    bool matchTextDirection = false,
    AssetBundle? bundle,
    String? package,
    double? width,
    double? height,
    BoxFit fit = BoxFit.contain,
    AlignmentGeometry alignment = Alignment.center,
    bool allowDrawingOutsideViewBox = false,
    WidgetBuilder? placeholderBuilder,
    String? semanticsLabel,
    bool excludeFromSemantics = false,
    _svg.SvgTheme? theme,
    _svg.ColorMapper? colorMapper,
    ColorFilter? colorFilter,
    Clip clipBehavior = Clip.hardEdge,
    @deprecated Color? color,
    @deprecated BlendMode colorBlendMode = BlendMode.srcIn,
    @deprecated bool cacheColorFilter = false,
  }) {
    final _svg.BytesLoader loader;
    if (_isVecFormat) {
      loader = _vg.AssetBytesLoader(
        _assetName,
        assetBundle: bundle,
        packageName: package,
      );
    } else {
      loader = _svg.SvgAssetLoader(
        _assetName,
        assetBundle: bundle,
        packageName: package,
        theme: theme,
        colorMapper: colorMapper,
      );
    }
    return _svg.SvgPicture(
      loader,
      key: key,
      matchTextDirection: matchTextDirection,
      width: width,
      height: height,
      fit: fit,
      alignment: alignment,
      allowDrawingOutsideViewBox: allowDrawingOutsideViewBox,
      placeholderBuilder: placeholderBuilder,
      semanticsLabel: semanticsLabel,
      excludeFromSemantics: excludeFromSemantics,
      colorFilter:
          colorFilter ??
          (color == null ? null : ColorFilter.mode(color, colorBlendMode)),
      clipBehavior: clipBehavior,
      cacheColorFilter: cacheColorFilter,
    );
  }

  String get path => _assetName;

  String get keyName => _assetName;
}
