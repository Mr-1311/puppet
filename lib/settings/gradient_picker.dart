import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:puppet/config/theme.dart' as t;

enum PickerType {
  solid,
  linearGradient,
  radialGradient,
}

class ThemeColorPicker extends StatefulWidget {
  const ThemeColorPicker({
    required this.initial,
    this.availableTypes = const [
      PickerType.solid,
      PickerType.linearGradient,
      PickerType.radialGradient,
    ],
    this.onChange,
    super.key,
  });

  final List<PickerType> availableTypes;
  final t.ThemeColor initial;
  final Function(t.ThemeColor)? onChange;

  @override
  State<ThemeColorPicker> createState() => _ThemeColorPickerState();
}

class _ThemeColorPickerState extends State<ThemeColorPicker> {
  late Set<String> sgmntBtnSelected;
  late Set<String> sgmntBtnGradient;
  double multiSliderWidth = 300;
  List<SliderIndicator> indicators = [];
  SliderIndicator? lastSelected;
  late Color currentColor;
  double colorPickerHeight = 200;
  late LinearGradient sliderBackground;

  late Alignment linearBegin;
  late Alignment linearEnd;
  late Alignment radialCenter;

  @override
  void initState() {
    super.initState();
    sgmntBtnSelected = switch (widget.initial) {
      t.ThemeColorSolid() => {'solid'},
      t.ThemeColorGradient() => {'gradient'},
    };

    sgmntBtnGradient = switch (widget.initial) {
      t.ThemeColorGradient(value: RadialGradient()) => {'radial'},
      _ => {'linear'},
    };

    currentColor = switch (widget.initial) {
      t.ThemeColorGradient() =>
        (widget.initial as t.ThemeColorGradient).value.colors.isEmpty
            ? Colors.black
            : (widget.initial as t.ThemeColorGradient).value.colors.first,
      t.ThemeColorSolid() => (widget.initial as t.ThemeColorSolid).value,
    };

    if (widget.initial is t.ThemeColorGradient) {
      final gre = (widget.initial as t.ThemeColorGradient).value;
      for (int i = 0; i < gre.colors.length; i++) {
        indicators.add(SliderIndicator.withVal(
            gre.stops?[i] ?? (i / (gre.colors.length - 1)),
            multiSliderWidth,
            gre.colors[i]));
      }
    }

    linearBegin = widget.initial is t.ThemeColorGradient
        ? (widget.initial as t.ThemeColorGradient).linearStart
        : Alignment.centerLeft;

    linearEnd = widget.initial is t.ThemeColorGradient
        ? (widget.initial as t.ThemeColorGradient).linearEnd
        : Alignment.centerRight;

    radialCenter = widget.initial is t.ThemeColorGradient
        ? (widget.initial as t.ThemeColorGradient).radialCenter
        : Alignment.center;

    _setColorPickerHeight();
    sliderBackground = _getSliderBackground();
  }

  @override
  Widget build(BuildContext context) {
    widget.onChange?.call(_getThemeColor());
    return Column(
      children: [
        if (widget.availableTypes.length > 1)
          SegmentedButton(
            segments: <ButtonSegment<String>>[
              ...widget.availableTypes.contains(PickerType.solid)
                  ? [ButtonSegment(value: 'solid', label: Text('Solid'))]
                  : [],
              ...(widget.availableTypes.contains(PickerType.linearGradient) ||
                      widget.availableTypes.contains(PickerType.radialGradient))
                  ? [ButtonSegment(value: 'gradient', label: Text('Gradient'))]
                  : [],
            ],
            selected: sgmntBtnSelected,
            onSelectionChanged: (p0) => setState(() {
              sgmntBtnSelected = p0;
              _setColorPickerHeight();
            }),
          ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: HueRingPicker(
                  enableAlpha: true,
                  portraitOnly: true,
                  colorPickerHeight: colorPickerHeight,
                  pickerColor: currentColor,
                  onColorChanged: (val) => _updateCurrentIndicatorColor(val),
                ),
              ),
            ),
            if (sgmntBtnSelected.contains('gradient'))
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                      child: MultiSlider(
                        width: multiSliderWidth,
                        indicators: indicators,
                        lastSelected: lastSelected,
                        linearGradient: sliderBackground,
                        onValueChanged: (v) => setState(() {
                          indicators = v;
                          sliderBackground = _getSliderBackground();
                        }),
                        onSelectedChanged: (v) => setState(() {
                          lastSelected = v;
                          currentColor = v.indicator.color!;
                        }),
                      ),
                    ),
                    SegmentedButton(
                      segments: <ButtonSegment<String>>[
                        ButtonSegment(value: 'linear', label: Text('Linear')),
                        ButtonSegment(value: 'radial', label: Text('Radial')),
                      ],
                      selected: sgmntBtnGradient,
                      onSelectionChanged: (p0) => setState(() {
                        sgmntBtnGradient = p0;
                      }),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: ThemeColorIndicator(
                        width: 70,
                        height: 70,
                        radius: sgmntBtnGradient.first == 'radial'
                            ? BorderRadius.circular(35)
                            : null,
                        linearGradient: sgmntBtnGradient.first == 'linear'
                            ? LinearGradient(
                                colors: indicators
                                    .map((e) => e.indicator.color!)
                                    .toList(),
                                stops: indicators.map((e) => e.val).toList(),
                                begin: linearBegin,
                                end: linearEnd,
                              )
                            : null,
                        radialGradient: RadialGradient(
                          colors: indicators
                              .map((e) => e.indicator.color!)
                              .toList(),
                          stops: indicators.map((e) => e.val).toList(),
                          center: radialCenter,
                        ),
                      ),
                    ),
                    sgmntBtnGradient.first == 'linear'
                        ? LinearGradientDirectionSelector(
                            size: 50,
                            begin: linearBegin,
                            end: linearEnd,
                            onBeginChanged: (p0) => setState(() {
                              linearBegin = p0.resolve(null);
                            }),
                            onEndChanged: (p0) => setState(() {
                              linearEnd = p0.resolve(null);
                            }),
                          )
                        : RadialGradientDirectionSelector(
                            size: 50,
                            center: radialCenter,
                            onCenterChanged: (p0) => setState(() {
                              radialCenter = p0.resolve(null);
                            }),
                          ),
                    Column(
                      children: [..._getGradientComponents()],
                    ),
                  ],
                ),
              ),
          ],
        ),
      ],
    );
  }

  List<Padding> _getGradientComponents() {
    List<Padding> res = [];
    for (final i in indicators) {
      res.add(Padding(
        padding: const EdgeInsets.all(4.0),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () => setState(() {
            lastSelected = i;
            currentColor = i.indicator.color!;
          }),
          child: Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color:
                  lastSelected == i ? Theme.of(context).highlightColor : null,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ThemeColorIndicator(
                  color: i.indicator.color,
                  width: 40,
                  height: 40,
                ),
                SizedBox(width: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 7),
                  child: Text(
                    i.indicator.color!.value.toRadixString(16),
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                ),
                SizedBox(width: 16),
                Text(
                  '${(i.val * 100).toInt()}',
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                SizedBox(width: 16),
                IconButton(
                    onPressed: () {
                      indicators.remove(i);
                      setState(() {
                        indicators = indicators;
                        sliderBackground = _getSliderBackground();
                      });
                    },
                    icon: Icon(Icons.delete))
              ],
            ),
          ),
        ),
      ));
    }
    return res;
  }

  void _setColorPickerHeight() {
    setState(() {
      colorPickerHeight = sgmntBtnSelected.first == 'solid' ? 200 : 150;
    });
  }

  LinearGradient _getSliderBackground() {
    var i = List<SliderIndicator>.from(indicators);
    i.sort((a, b) => a.val.compareTo(b.val));
    return LinearGradient(
      colors: i.map((e) => e.indicator.color!).toList(),
      stops: i.map((e) => e.val).toList(),
    );
  }

  _updateCurrentIndicatorColor(Color color) {
    if (lastSelected != null) {
      indicators[indicators.indexOf(lastSelected!)].updateColor(color);
    }
    setState(() {
      currentColor = color;
      sliderBackground = _getSliderBackground();
    });
  }

  t.ThemeColor _getThemeColor() {
    switch (sgmntBtnSelected.first) {
      case 'gradient':
        return switch (sgmntBtnGradient.first) {
          'linear' => t.ThemeColorGradient.fromGradient(LinearGradient(
              colors: indicators.map((e) => e.indicator.color!).toList(),
              stops: indicators.map((e) => e.val).toList(),
              begin: linearBegin,
              end: linearEnd,
            )),
          'radial' => t.ThemeColorGradient.fromGradient(RadialGradient(
              colors: indicators.map((e) => e.indicator.color!).toList(),
              stops: indicators.map((e) => e.val).toList(),
              center: radialCenter,
            )),
          _ => t.ThemeColorSolid('#FFFFFF'),
        };
      default:
        return t.ThemeColorSolid(
            currentColor.red.toRadixString(16).padLeft(2, '0') +
                currentColor.green.toRadixString(16).padLeft(2, '0') +
                currentColor.blue.toRadixString(16).padLeft(2, '0') +
                currentColor.alpha.toRadixString(16).padLeft(2, '0'));
    }
  }
}

class LinearGradientDirectionSelector extends StatefulWidget {
  const LinearGradientDirectionSelector({
    this.size = 70,
    this.cursorSize = 10,
    this.begin,
    this.end,
    this.snapAssistance = 6.0,
    this.onBeginChanged,
    this.onEndChanged,
    super.key,
  });

  final double size;
  final double cursorSize;
  final AlignmentGeometry? begin;
  final AlignmentGeometry? end;
  final double snapAssistance;

  final Function(AlignmentGeometry)? onBeginChanged;
  final Function(AlignmentGeometry)? onEndChanged;

  @override
  State<LinearGradientDirectionSelector> createState() =>
      _LinearGradientDirectionSelectorState();
}

class _LinearGradientDirectionSelectorState
    extends State<LinearGradientDirectionSelector> {
  late double outerSize;
  late double innerSize;
  late double pivot;

  late double beginX;
  late double beginY;
  late double endX;
  late double endY;

  late double beginXStart;
  late double beginYStart;
  late double endXStart;
  late double endYStart;

  late double boundaryMin;
  late double boundaryMax;

  final TextEditingController beginXController = TextEditingController();
  final TextEditingController beginYController = TextEditingController();
  final TextEditingController endXController = TextEditingController();
  final TextEditingController endYController = TextEditingController();

  @override
  void initState() {
    super.initState();
    this.outerSize = (widget.size * 1.5) + widget.cursorSize;
    this.innerSize = widget.size;
    this.pivot = (outerSize / 2) - (widget.cursorSize / 2);

    this.beginX = widget.begin != null
        ? widget.begin!.resolve(null).x * innerSize / 2 + pivot
        : pivot - innerSize / 2;
    this.beginY = widget.begin != null
        ? widget.begin!.resolve(null).y * innerSize / 2 + pivot
        : pivot;
    this.endX = widget.end != null
        ? widget.end!.resolve(null).x * innerSize / 2 + pivot
        : pivot + innerSize / 2;
    this.endY = widget.end != null
        ? widget.end!.resolve(null).y * innerSize / 2 + pivot
        : pivot;

    this.beginXStart = beginX;
    this.beginYStart = beginY;
    this.endXStart = endX;
    this.endYStart = endY;

    this.boundaryMin = pivot - innerSize * 0.75;
    this.boundaryMax = pivot + innerSize * 0.75;

    beginXController.text = _posToValue(beginX).toString();
    beginYController.text = _posToValue(beginY).toString();
    endXController.text = _posToValue(endX).toString();
    endYController.text = _posToValue(endY).toString();
  }

  @override
  void dispose() {
    beginXController.dispose();
    beginYController.dispose();
    endXController.dispose();
    endYController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Padding(
          padding: const EdgeInsets.all(4.0),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: outerSize,
                height: outerSize,
                alignment: Alignment.center,
              ),
              Positioned(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                        color: Theme.of(context).colorScheme.primary),
                  ),
                  width: innerSize,
                  height: innerSize,
                ),
              ),
              Positioned(
                left: endX,
                top: endY,
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onPanUpdate: (details) {
                      setState(() {
                        endX = _checkBoundary(endXStart +
                            details.localPosition.dx -
                            widget.cursorSize / 2);
                        endXController.text =
                            _posToValue(endX).toStringAsFixed(2);
                        endY = _checkBoundary(endYStart +
                            details.localPosition.dy -
                            widget.cursorSize / 2);
                        endYController.text =
                            _posToValue(endY).toStringAsFixed(2);
                        widget.onEndChanged?.call(
                            Alignment(_posToValue(endX), _posToValue(endY)));
                      });
                    },
                    onPanEnd: (_) {
                      endXStart = endX;
                      endYStart = endY;
                    },
                    child: Container(
                      width: widget.cursorSize,
                      height: widget.cursorSize,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.redAccent,
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                left: beginX,
                top: beginY,
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onPanUpdate: (details) {
                      setState(() {
                        beginX = _checkBoundary(beginXStart +
                            details.localPosition.dx -
                            widget.cursorSize / 2);
                        beginXController.text =
                            _posToValue(beginX).toStringAsFixed(2);
                        beginY = _checkBoundary(beginYStart +
                            details.localPosition.dy -
                            widget.cursorSize / 2);
                        beginYController.text =
                            _posToValue(beginY).toStringAsFixed(2);
                        widget.onBeginChanged?.call(Alignment(
                            _posToValue(beginX), _posToValue(beginY)));
                      });
                    },
                    onPanEnd: (_) {
                      beginXStart = beginX;
                      beginYStart = beginY;
                    },
                    child: Container(
                      width: widget.cursorSize,
                      height: widget.cursorSize,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.blueAccent,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        Column(
          children: [
            Row(
              children: [
                Text('Begin X: '),
                ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: 55),
                  child: TextField(
                    controller: beginXController,
                    onChanged: (value) {
                      final parsed = double.tryParse(value)?.clamp(-2.0, 2.0);
                      if (parsed != null) {
                        setState(() {
                          beginX = _checkBoundary(_valueToPos(parsed));
                          beginXStart = beginX;
                          widget.onBeginChanged?.call(Alignment(
                              _posToValue(beginX), _posToValue(beginY)));
                        });
                      }
                    },
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r"^-?[0-9.]*")),
                    ],
                  ),
                ),
              ],
            ),
            Row(
              children: [
                Text('Begin Y: '),
                ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: 55),
                  child: TextField(
                    controller: beginYController,
                    onChanged: (value) {
                      final parsed = double.tryParse(value)?.clamp(-2.0, 2.0);
                      if (parsed != null) {
                        setState(() {
                          beginY = _checkBoundary(_valueToPos(parsed));
                          beginYStart = beginY;
                          widget.onBeginChanged?.call(Alignment(
                              _posToValue(beginX), _posToValue(beginY)));
                        });
                      }
                    },
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r"^-?[0-9.]*")),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
        Column(
          children: [
            Row(
              children: [
                Text('End X: '),
                ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: 55),
                  child: TextField(
                    controller: endXController,
                    onChanged: (value) {
                      final parsed = double.tryParse(value)?.clamp(-2.0, 2.0);
                      if (parsed != null) {
                        setState(() {
                          endX = _checkBoundary(_valueToPos(parsed));
                          endXStart = endX;
                          widget.onEndChanged?.call(
                              Alignment(_posToValue(endX), _posToValue(endY)));
                        });
                      }
                    },
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r"^-?[0-9.]*")),
                    ],
                  ),
                ),
              ],
            ),
            Row(
              children: [
                Text('End Y: '),
                ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: 55),
                  child: TextField(
                    controller: endYController,
                    onChanged: (value) {
                      final parsed = double.tryParse(value)?.clamp(-2.0, 2.0);
                      if (parsed != null) {
                        setState(() {
                          endY = _checkBoundary(_valueToPos(parsed));
                          endYStart = endY;
                          widget.onEndChanged?.call(
                              Alignment(_posToValue(endX), _posToValue(endY)));
                        });
                      }
                    },
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r"^-?[0-9.]*")),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  double _checkBoundary(double pos) {
    final snapMin = pivot - innerSize / 2;
    final snapMax = pivot + innerSize / 2;
    if (pos > snapMin - widget.snapAssistance &&
        pos < snapMin + widget.snapAssistance) {
      return snapMin;
    }
    if (pos > snapMax - widget.snapAssistance &&
        pos < snapMax + widget.snapAssistance) {
      return snapMax;
    }
    if (pos > pivot - widget.snapAssistance &&
        pos < pivot + widget.snapAssistance) {
      return pivot;
    }
    return pos.clamp(boundaryMin, boundaryMax);
  }

  double _posToValue(double pos) {
    return (pos - pivot) / innerSize * 2;
  }

  double _valueToPos(double value) {
    return pivot + value * innerSize / 2;
  }
}

class RadialGradientDirectionSelector extends StatefulWidget {
  const RadialGradientDirectionSelector({
    this.size = 70,
    this.cursorSize = 10,
    this.center,
    this.snapAssistance = 6.0,
    this.onCenterChanged,
    super.key,
  });

  final double size;
  final double cursorSize;
  final AlignmentGeometry? center;
  final double snapAssistance;

  final Function(AlignmentGeometry)? onCenterChanged;

  @override
  State<RadialGradientDirectionSelector> createState() =>
      _RadialGradientDirectionSelectorState();
}

class _RadialGradientDirectionSelectorState
    extends State<RadialGradientDirectionSelector> {
  late double outerSize;
  late double innerSize;
  late double pivot;

  late double centerX;
  late double centerY;

  late double centerXStart;
  late double centerYStart;

  late double boundaryMin;
  late double boundaryMax;

  final TextEditingController centerXController = TextEditingController();
  final TextEditingController centerYController = TextEditingController();

  @override
  void initState() {
    super.initState();
    this.outerSize = (widget.size * 1.5) + widget.cursorSize;
    this.innerSize = widget.size;
    this.pivot = (outerSize / 2) - (widget.cursorSize / 2);

    this.centerX = widget.center != null
        ? widget.center!.resolve(null).x * innerSize / 2 + pivot
        : pivot;
    this.centerY = widget.center != null
        ? widget.center!.resolve(null).y * innerSize / 2 + pivot
        : pivot;

    this.centerXStart = centerX;
    this.centerYStart = centerY;

    this.boundaryMin = pivot - innerSize * 0.75;
    this.boundaryMax = pivot + innerSize * 0.75;

    centerXController.text = _posToValue(centerX).toString();
    centerYController.text = _posToValue(centerY).toString();
  }

  @override
  void dispose() {
    centerXController.dispose();
    centerYController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Padding(
          padding: const EdgeInsets.all(4.0),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: outerSize,
                height: outerSize,
                alignment: Alignment.center,
              ),
              Positioned(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(innerSize / 2),
                    border: Border.all(
                        color: Theme.of(context).colorScheme.primary),
                  ),
                  width: innerSize,
                  height: innerSize,
                ),
              ),
              Positioned(
                left: centerX,
                top: centerY,
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onPanUpdate: (details) {
                      setState(() {
                        centerX = _checkBoundary(centerXStart +
                            details.localPosition.dx -
                            widget.cursorSize / 2);
                        centerXController.text =
                            _posToValue(centerX).toStringAsFixed(2);
                        centerY = _checkBoundary(centerYStart +
                            details.localPosition.dy -
                            widget.cursorSize / 2);
                        centerYController.text =
                            _posToValue(centerY).toStringAsFixed(2);
                        widget.onCenterChanged?.call(Alignment(
                            _posToValue(centerX), _posToValue(centerY)));
                      });
                    },
                    onPanEnd: (_) {
                      centerXStart = centerX;
                      centerYStart = centerY;
                    },
                    child: Container(
                      width: widget.cursorSize,
                      height: widget.cursorSize,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.blueAccent,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        Column(
          children: [
            Row(
              children: [
                Text('Center X: '),
                ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: 55),
                  child: TextField(
                    controller: centerXController,
                    onChanged: (value) {
                      final parsed = double.tryParse(value)?.clamp(-2.0, 2.0);
                      if (parsed != null) {
                        setState(() {
                          centerX = _checkBoundary(_valueToPos(parsed));
                          centerXStart = centerX;
                          widget.onCenterChanged?.call(Alignment(
                              _posToValue(centerX), _posToValue(centerY)));
                        });
                      }
                    },
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r"^-?[0-9.]*")),
                    ],
                  ),
                ),
              ],
            ),
            Row(
              children: [
                Text('Center Y: '),
                ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: 55),
                  child: TextField(
                    controller: centerYController,
                    onChanged: (value) {
                      final parsed = double.tryParse(value)?.clamp(-2.0, 2.0);
                      if (parsed != null) {
                        setState(() {
                          centerY = _checkBoundary(_valueToPos(parsed));
                          centerYStart = centerY;
                          widget.onCenterChanged?.call(Alignment(
                              _posToValue(centerX), _posToValue(centerY)));
                        });
                      }
                    },
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r"^-?[0-9.]*")),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  double _checkBoundary(double pos) {
    final snapMin = pivot - innerSize / 2;
    final snapMax = pivot + innerSize / 2;
    if (pos > snapMin - widget.snapAssistance &&
        pos < snapMin + widget.snapAssistance) {
      return snapMin;
    }
    if (pos > snapMax - widget.snapAssistance &&
        pos < snapMax + widget.snapAssistance) {
      return snapMax;
    }
    if (pos > pivot - widget.snapAssistance &&
        pos < pivot + widget.snapAssistance) {
      return pivot;
    }
    return pos.clamp(boundaryMin, boundaryMax);
  }

  double _posToValue(double pos) {
    return (pos - pivot) / innerSize * 2;
  }

  double _valueToPos(double value) {
    return pivot + value * innerSize / 2;
  }
}

const LinearGradient random = LinearGradient(
  colors: [
    Color.fromRGBO(255, 37, 0, 1),
    Color.fromRGBO(255, 165, 0, 1),
    Color.fromRGBO(218, 255, 0, 1),
    Color.fromRGBO(90, 255, 0, 1),
    Color.fromRGBO(0, 255, 37, 1),
    Color.fromRGBO(0, 255, 165, 1),
    Color.fromRGBO(0, 218, 255, 1),
    Color.fromRGBO(0, 90, 255, 1),
    Color.fromRGBO(37, 0, 255, 1),
    Color.fromRGBO(165, 0, 255, 1),
    Color.fromRGBO(255, 0, 217, 1),
    Color.fromRGBO(255, 0, 90, 1),
  ],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);

class ThemeColorIndicator extends StatefulWidget {
  ThemeColorIndicator(
      {this.color,
      this.linearGradient,
      this.radialGradient,
      this.width = 100,
      this.height = 100,
      BorderRadius? radius,
      super.key}) {
    this.radius = radius ?? BorderRadius.circular(12);
  }

  ThemeColorIndicator.random(
      {this.width = 100, this.height = 100, BorderRadius? radius})
      : color = null,
        linearGradient = random,
        radialGradient = null,
        this.radius = radius ?? BorderRadius.circular(12);

  ThemeColorIndicator.fromThemeColor(
      {this.width = 100,
      this.height = 100,
      BorderRadius? radius,
      required t.ThemeColor themeColor})
      : color = themeColor is t.ThemeColorSolid ? themeColor.value : null,
        linearGradient = themeColor is t.ThemeColorGradient
            ? (themeColor.value is LinearGradient
                ? themeColor.value as LinearGradient
                : null)
            : null,
        radialGradient = themeColor is t.ThemeColorGradient
            ? (themeColor.value is RadialGradient
                ? themeColor.value as RadialGradient
                : null)
            : null,
        this.radius = radius ?? BorderRadius.circular(12);

  final Color? color;
  final LinearGradient? linearGradient;
  final RadialGradient? radialGradient;
  final double width;
  final double height;
  late final BorderRadius radius;

  @override
  State<ThemeColorIndicator> createState() => _ThemeColorIndicatorState();

  ThemeColorIndicator copyWith({required Color color}) {
    return ThemeColorIndicator(
      color: color,
      linearGradient: linearGradient,
      radialGradient: radialGradient,
      width: width,
      height: height,
    );
  }
}

class _ThemeColorIndicatorState extends State<ThemeColorIndicator> {
  // final border = Border.all(color: Colors.white, width: 1);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        borderRadius: widget.radius,
        image: DecorationImage(
          image: AssetImage('assets/transparent_bg.png'),
          fit: BoxFit.cover,
        ),
        border:
            Border.all(color: Theme.of(context).colorScheme.outline, width: 1),
      ),
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              borderRadius: widget.radius,
              gradient: widget.linearGradient ?? widget.radialGradient,
              color: widget.color,
            ),
          ),
        ],
      ),
    );
  }
}

const indicatorWidth = 11.0;
const indicatorHeight = 30.0;

class MultiSlider extends StatefulWidget {
  MultiSlider({
    this.color = Colors.white,
    this.linearGradient,
    this.width = 300,
    this.height = 15,
    required this.indicators,
    this.lastSelected,
    this.onValueChanged,
    this.onSelectedChanged,
    super.key,
  });

  final double width;
  final double height;

  final Color? color;
  final LinearGradient? linearGradient;

  final List<SliderIndicator> indicators;
  SliderIndicator? lastSelected;

  final Function(List<SliderIndicator>)? onValueChanged;
  final Function(SliderIndicator)? onSelectedChanged;

  @override
  State<MultiSlider> createState() => _MultiSliderState();
}

class _MultiSliderState extends State<MultiSlider> {
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Padding(
          padding: EdgeInsets.symmetric(
              horizontal: indicatorWidth / 2,
              vertical: max((indicatorHeight - widget.height) / 2, 0)),
          child: GestureDetector(
            onDoubleTapDown: (details) => setState(() {
              widget.indicators.add(SliderIndicator.withVal(
                  _toVal(details.localPosition.dx),
                  widget.width,
                  widget.lastSelected?.indicator.color));
              widget.indicators.sort((a, b) => a.pos.compareTo(b.pos));
              widget.lastSelected = widget.indicators
                  .firstWhere((i) => i.val == _toVal(details.localPosition.dx));
              widget.onSelectedChanged?.call(widget.lastSelected!);
              widget.onValueChanged?.call(widget.indicators);
            }),
            child: Container(
              width: widget.width,
              height: widget.height,
              constraints: BoxConstraints(minWidth: widget.width),
              decoration: BoxDecoration(
                gradient: widget.linearGradient,
                color: widget.color,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ),
        for (final i in widget.indicators)
          Positioned(
              left: i.pos.clamp(0, widget.width),
              top: max((widget.height - indicatorHeight) / 2, 0),
              child: GestureDetector(
                onTapDown: (_) => setState(() {
                  widget.lastSelected = i;
                  widget.onSelectedChanged?.call(widget.lastSelected!);
                }),
                onHorizontalDragEnd: (_) {
                  i.pos = i.pos.clamp(0, widget.width);
                  widget.indicators.sort((a, b) => a.pos.compareTo(b.pos));
                  widget.onValueChanged?.call(widget.indicators);
                },
                onHorizontalDragUpdate: (details) => setState(() {
                  i.pos += details.primaryDelta ?? 0;
                  i.updateVal(widget.width);
                  widget.onValueChanged?.call(widget.indicators);
                  widget.lastSelected = i;
                  widget.onSelectedChanged?.call(widget.lastSelected!);
                }),
                onDoubleTap: () => setState(() {
                  widget.indicators.remove(i);
                  widget.onValueChanged?.call(widget.indicators);
                }),
                child: Transform.scale(
                    scale: widget.lastSelected == i ? 1.2 : 1,
                    child: i.indicator),
              ))
      ],
    );
  }

  double _toVal(double pos) {
    return pos.clamp(0, widget.width) / widget.width;
  }
}

class SliderIndicator {
  late ThemeColorIndicator indicator;
  late double pos;
  late double val;

  SliderIndicator() {
    this.indicator = ThemeColorIndicator(
      width: indicatorWidth,
      height: indicatorHeight,
      color: Colors.white,
    );
    pos = 0;
    val = 0;
  }

  SliderIndicator.withVal(this.val, double width, [Color? color]) {
    this.pos = width * val;
    this.indicator = ThemeColorIndicator(
      width: indicatorWidth,
      height: indicatorHeight,
      color: color ?? Colors.white,
    );
  }

  void updateVal(double width) {
    val = (pos / width).clamp(0, 1);
  }

  void updateColor(Color color) {
    indicator = indicator.copyWith(color: color);
  }
}
