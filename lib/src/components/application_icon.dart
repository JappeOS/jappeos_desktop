//  JappeOS-Desktop, The desktop environment for JappeOS.
//  Copyright (C) 2026  The JappeOS team.
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU Affero General Public License as
//  published by the Free Software Foundation, either version 3 of the
//  License, or (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU Affero General Public License for more details.
//
//  You should have received a copy of the GNU Affero General Public License
//  along with this program.  If not, see <https://www.gnu.org/licenses/>.

import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart' show Icons;

import '../provider/application_icon_service.dart';
import '../provider/application_resolver.dart';

class ApplicationIcon extends StatefulWidget {
  final ResolvedApplication application;
  final ApplicationIconService service;
  final double size;

  const ApplicationIcon({
    super.key,
    required this.application,
    required this.service,
    required this.size,
  });

  @override
  State<ApplicationIcon> createState() => _ApplicationIconState();
}

class _ApplicationIconState extends State<ApplicationIcon> {
  ApplicationIconRequest? _request;
  List<ApplicationIconSource>? _sources;
  Object? _identity;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _load();
  }

  @override
  void didUpdateWidget(covariant ApplicationIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
    _load();
  }

  void _load() {
    final request = widget.service.request(
      widget.application,
      size: widget.size,
      dpr: MediaQuery.devicePixelRatioOf(context),
    );

    final identity = (widget.service, widget.application.groupId);
    if (identical(request, _request) && identity == _identity) {
      return;
    }

    _sources = request.value ?? (identity == _identity ? _sources : null);
    _identity = identity;
    _request = request;

    if (request.value != null) return;

    request.future.then((sources) {
      if (!mounted || !identical(request, _request)) return;
      setState(() => _sources = sources);
    }, onError: (Object error, StackTrace stack) {
      if (!mounted || !identical(request, _request)) return;
      setState(() => _sources = const []);
    });
  }

  @override
  Widget build(BuildContext context) => SizedBox.square(
        dimension: widget.size,
        // Loading is not a failed lookup. Keep the previous icon for this app,
        // and only display the generic icon once all candidates are exhausted.
        child: _sources == null
            ? null
            : KeyedSubtree(
                key: ValueKey(_identity), child: _candidate(_sources!, 0)),
      );

  Widget _candidate(List<ApplicationIconSource> sources, int index) {
    if (index >= sources.length) {
      return Icon(Icons.settings_applications, size: widget.size);
    }

    final source = sources[index];

    Widget fallback() => _candidate(sources, index + 1);

    if (source.pixels != null) {
      return _PixelIcon(
        source: source,
        fallback: fallback,
      );
    }

    if (source.svg) {
      return SvgPicture.memory(
        source.bytes!,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => fallback(),
      );
    }

    return Image.memory(
      source.bytes!,
      fit: BoxFit.contain,
      gaplessPlayback: true,
      errorBuilder: (_, __, ___) => fallback(),
    );
  }
}

class _PixelIcon extends StatefulWidget {
  final ApplicationIconSource source;
  final Widget Function() fallback;

  const _PixelIcon({required this.source, required this.fallback});

  @override
  State<_PixelIcon> createState() => _PixelIconState();
}

class _PixelIconState extends State<_PixelIcon> {
  ui.Image? _image;
  bool _failed = false;
  int _generation = 0;

  @override
  void initState() {
    super.initState();
    _decode();
  }

  @override
  void didUpdateWidget(covariant _PixelIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.source.pixels, widget.source.pixels)) {
      _failed = false;
      _decode();
    }
  }

  Future<void> _decode() async {
    final generation = ++_generation;
    final pixels = widget.source.pixels!;
    ui.ImmutableBuffer? buffer;
    ui.ImageDescriptor? descriptor;
    ui.Codec? codec;

    try {
      buffer = await ui.ImmutableBuffer.fromUint8List(pixels.rgba);
      descriptor = ui.ImageDescriptor.raw(
        buffer,
        width: pixels.width,
        height: pixels.height,
        pixelFormat: ui.PixelFormat.rgba8888,
      );
      codec = await descriptor.instantiateCodec();

      final frame = await codec.getNextFrame();
      if (!mounted || generation != _generation) {
        frame.image.dispose();
        return;
      }

      final previous = _image;
      setState(() => _image = frame.image);
      previous?.dispose();
    } catch (_) {
      if (mounted && generation == _generation) {
        setState(() => _failed = true);
      }
    } finally {
      codec?.dispose();
      descriptor?.dispose();
      buffer?.dispose();
    }
  }

  @override
  void dispose() {
    _image?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _failed
      ? widget.fallback()
      : RawImage(image: _image, fit: BoxFit.contain);
}
