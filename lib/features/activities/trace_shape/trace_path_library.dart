import 'dart:math' as math;
import 'dart:ui';

/// One traceable form: an ordered list of strokes (each a polyline of
/// sample points inside a normalized 0..1 box, authored in the natural
/// writing direction) plus optional decoration dots that pop in
/// automatically once the strokes are traced (e.g. the dot of ب).
class TracePath {
  const TracePath({required this.strokes, this.autoDots = const []});

  /// Strokes in tracing order; each is a dense polyline in a 0..1 box.
  final List<List<Offset>> strokes;

  /// Decoration dots (0..1 box) revealed after the last stroke completes.
  final List<Offset> autoDots;
}

/// Hand-authored trace paths for the TraceShape engine.
///
/// Shapes: circle, square, triangle, heart, star.
/// Digits: 1..5.
/// EN letters: A, C, L, O, S, T. AR letters: ا ب ل و س (simplified).
///
/// Everything else falls back to shapes in the engine.
class TracePathLibrary {
  TracePathLibrary._();

  static TracePath? forItem(String itemId) => _paths[itemId];

  static bool has(String itemId) => _paths.containsKey(itemId);

  /// Which content is unlocked at a given [traceDetail] band value:
  /// 1 = shapes only, 2 = + digits, 3 = + letters.
  static bool allowedAtDetail(String itemId, int traceDetail) {
    if (itemId.startsWith('shape_')) return true;
    if (itemId.startsWith('num_')) return traceDetail >= 2;
    return traceDetail >= 3;
  }

  /// Resamples a polyline to [count] evenly spaced points (arc length).
  static List<Offset> resample(List<Offset> points, int count) {
    if (points.length < 2 || count < 2) return List.of(points);
    final cumulative = <double>[0];
    for (var i = 1; i < points.length; i++) {
      cumulative.add(cumulative[i - 1] + (points[i] - points[i - 1]).distance);
    }
    final total = cumulative.last;
    if (total <= 0) return List.filled(count, points.first);
    final result = <Offset>[];
    var seg = 0;
    for (var i = 0; i < count; i++) {
      final target = total * i / (count - 1);
      while (seg < points.length - 2 && cumulative[seg + 1] < target) {
        seg++;
      }
      final segLen = cumulative[seg + 1] - cumulative[seg];
      final t = segLen <= 0 ? 0.0 : (target - cumulative[seg]) / segLen;
      result.add(Offset.lerp(points[seg], points[seg + 1], t)!);
    }
    return result;
  }

  /// Polyline length.
  static double lengthOf(List<Offset> points) {
    var total = 0.0;
    for (var i = 1; i < points.length; i++) {
      total += (points[i] - points[i - 1]).distance;
    }
    return total;
  }

  // -------------------------------------------------- authoring helpers

  static List<Offset> _line(Offset a, Offset b, [int n = 14]) =>
      [for (var i = 0; i <= n; i++) Offset.lerp(a, b, i / n)!];

  /// Elliptic arc; positive sweep is clockwise on screen (y-down).
  static List<Offset> _arc(
    double cx,
    double cy,
    double rx,
    double ry,
    double startAngle,
    double sweep, [
    int n = 48,
  ]) =>
      [
        for (var i = 0; i <= n; i++)
          Offset(
            cx + rx * math.cos(startAngle + sweep * i / n),
            cy + ry * math.sin(startAngle + sweep * i / n),
          ),
      ];

  static List<Offset> _cubic(
    Offset p0,
    Offset c1,
    Offset c2,
    Offset p1, [
    int n = 24,
  ]) {
    final points = <Offset>[];
    for (var i = 0; i <= n; i++) {
      final t = i / n;
      final u = 1 - t;
      points.add(
        p0 * (u * u * u) +
            c1 * (3 * u * u * t) +
            c2 * (3 * u * t * t) +
            p1 * (t * t * t),
      );
    }
    return points;
  }

  /// Joins segments into one stroke, dropping duplicated join points.
  static List<Offset> _join(List<List<Offset>> segments) {
    final stroke = <Offset>[];
    for (final segment in segments) {
      for (final p in segment) {
        if (stroke.isEmpty || (stroke.last - p).distance > 0.0005) {
          stroke.add(p);
        }
      }
    }
    return stroke;
  }

  // ------------------------------------------------------------- shapes

  static final List<Offset> _circle =
      _arc(0.5, 0.5, 0.42, 0.42, -math.pi / 2, 2 * math.pi, 72);

  static final List<Offset> _square = _join([
    _line(const Offset(0.14, 0.14), const Offset(0.86, 0.14)),
    _line(const Offset(0.86, 0.14), const Offset(0.86, 0.86)),
    _line(const Offset(0.86, 0.86), const Offset(0.14, 0.86)),
    _line(const Offset(0.14, 0.86), const Offset(0.14, 0.14)),
  ]);

  static final List<Offset> _triangle = _join([
    _line(const Offset(0.5, 0.12), const Offset(0.88, 0.85)),
    _line(const Offset(0.88, 0.85), const Offset(0.12, 0.85)),
    _line(const Offset(0.12, 0.85), const Offset(0.5, 0.12)),
  ]);

  static final List<Offset> _heart = _join([
    _cubic(const Offset(0.5, 0.32), const Offset(0.42, 0.1),
        const Offset(0.14, 0.1), const Offset(0.11, 0.36)),
    _cubic(const Offset(0.11, 0.36), const Offset(0.09, 0.56),
        const Offset(0.32, 0.72), const Offset(0.5, 0.88)),
    _cubic(const Offset(0.5, 0.88), const Offset(0.68, 0.72),
        const Offset(0.91, 0.56), const Offset(0.89, 0.36)),
    _cubic(const Offset(0.89, 0.36), const Offset(0.86, 0.1),
        const Offset(0.58, 0.1), const Offset(0.5, 0.32)),
  ]);

  /// Classic one-stroke star: top, lower-right, mid-left, mid-right,
  /// lower-left, back to top.
  static final List<Offset> _star = _join([
    _line(const Offset(0.5, 0.07), const Offset(0.765, 0.884), 20),
    _line(const Offset(0.765, 0.884), const Offset(0.072, 0.381), 20),
    _line(const Offset(0.072, 0.381), const Offset(0.928, 0.381), 20),
    _line(const Offset(0.928, 0.381), const Offset(0.236, 0.884), 20),
    _line(const Offset(0.236, 0.884), const Offset(0.5, 0.07), 20),
  ]);

  // ------------------------------------------------------------- digits

  static final List<Offset> _digit1 = _join([
    _line(const Offset(0.36, 0.28), const Offset(0.54, 0.12), 8),
    _line(const Offset(0.54, 0.12), const Offset(0.54, 0.88), 22),
  ]);

  static final List<Offset> _digit2 = _join([
    _cubic(const Offset(0.3, 0.3), const Offset(0.3, 0.08),
        const Offset(0.7, 0.08), const Offset(0.7, 0.32)),
    _cubic(const Offset(0.7, 0.32), const Offset(0.7, 0.5),
        const Offset(0.42, 0.62), const Offset(0.28, 0.84)),
    _line(const Offset(0.28, 0.84), const Offset(0.74, 0.84)),
  ]);

  static final List<Offset> _digit3 = _join([
    _cubic(const Offset(0.3, 0.2), const Offset(0.45, 0.06),
        const Offset(0.72, 0.1), const Offset(0.72, 0.28)),
    _cubic(const Offset(0.72, 0.28), const Offset(0.72, 0.44),
        const Offset(0.56, 0.48), const Offset(0.46, 0.48)),
    _cubic(const Offset(0.46, 0.48), const Offset(0.6, 0.48),
        const Offset(0.74, 0.54), const Offset(0.74, 0.68)),
    _cubic(const Offset(0.74, 0.68), const Offset(0.74, 0.9),
        const Offset(0.42, 0.94), const Offset(0.28, 0.8)),
  ]);

  static final TracePath _digit4 = TracePath(strokes: [
    _join([
      _line(const Offset(0.58, 0.12), const Offset(0.22, 0.6), 18),
      _line(const Offset(0.22, 0.6), const Offset(0.8, 0.6), 18),
    ]),
    _line(const Offset(0.66, 0.12), const Offset(0.66, 0.9), 22),
  ]);

  static final TracePath _digit5 = TracePath(strokes: [
    _join([
      _line(const Offset(0.36, 0.12), const Offset(0.36, 0.46), 12),
      _cubic(const Offset(0.36, 0.46), const Offset(0.5, 0.38),
          const Offset(0.74, 0.44), const Offset(0.74, 0.64)),
      _cubic(const Offset(0.74, 0.64), const Offset(0.74, 0.86),
          const Offset(0.44, 0.94), const Offset(0.3, 0.8)),
    ]),
    _line(const Offset(0.36, 0.12), const Offset(0.72, 0.12), 12),
  ]);

  // -------------------------------------------------- English letters

  static final TracePath _letterA = TracePath(strokes: [
    _line(const Offset(0.5, 0.08), const Offset(0.14, 0.92), 22),
    _line(const Offset(0.5, 0.08), const Offset(0.86, 0.92), 22),
    _line(const Offset(0.28, 0.62), const Offset(0.72, 0.62), 14),
  ]);

  /// C: start upper right, sweep over the top, around and out at the
  /// lower right (counter-clockwise on screen).
  static final List<Offset> _letterC =
      _arc(0.54, 0.5, 0.38, 0.42, -math.pi / 3, -4 * math.pi / 3, 56);

  static final List<Offset> _letterL = _join([
    _line(const Offset(0.32, 0.1), const Offset(0.32, 0.88), 22),
    _line(const Offset(0.32, 0.88), const Offset(0.76, 0.88), 14),
  ]);

  static final List<Offset> _letterO =
      _arc(0.5, 0.5, 0.34, 0.42, -math.pi / 2, 2 * math.pi, 64);

  static final List<Offset> _letterS = _join([
    _cubic(const Offset(0.72, 0.2), const Offset(0.6, 0.06),
        const Offset(0.3, 0.08), const Offset(0.3, 0.3)),
    _cubic(const Offset(0.3, 0.3), const Offset(0.3, 0.5),
        const Offset(0.7, 0.5), const Offset(0.7, 0.7)),
    _cubic(const Offset(0.7, 0.7), const Offset(0.7, 0.92),
        const Offset(0.36, 0.94), const Offset(0.26, 0.78)),
  ]);

  static final TracePath _letterT = TracePath(strokes: [
    _line(const Offset(0.16, 0.14), const Offset(0.84, 0.14), 18),
    _line(const Offset(0.5, 0.14), const Offset(0.5, 0.9), 22),
  ]);

  // --------------------------------------------------- Arabic letters

  /// ا — one calm vertical stroke, top to bottom.
  static final List<Offset> _arAlif =
      _line(const Offset(0.5, 0.08), const Offset(0.5, 0.92), 26);

  /// ب — the bowl in one stroke (right tip, along the boat, up at the
  /// left), then the dot below pops in automatically.
  static final TracePath _arBa = TracePath(
    strokes: [
      _join([
        _cubic(const Offset(0.86, 0.26), const Offset(0.9, 0.4),
            const Offset(0.9, 0.5), const Offset(0.8, 0.56)),
        _cubic(const Offset(0.8, 0.56), const Offset(0.6, 0.64),
            const Offset(0.34, 0.64), const Offset(0.18, 0.54)),
        _cubic(const Offset(0.18, 0.54), const Offset(0.12, 0.5),
            const Offset(0.1, 0.42), const Offset(0.13, 0.34)),
      ]),
    ],
    autoDots: [Offset(0.5, 0.8)],
  );

  /// ل — tall stroke down into a rounded bowl swinging left and up.
  static final List<Offset> _arLam = _join([
    _line(const Offset(0.66, 0.08), const Offset(0.66, 0.52), 16),
    _cubic(const Offset(0.66, 0.52), const Offset(0.66, 0.78),
        const Offset(0.46, 0.9), const Offset(0.3, 0.84)),
    _cubic(const Offset(0.3, 0.84), const Offset(0.2, 0.79),
        const Offset(0.16, 0.7), const Offset(0.18, 0.6)),
  ]);

  /// و — little round head, then the tail sweeping down to the left.
  static final List<Offset> _arWaw = _join([
    _arc(0.58, 0.3, 0.13, 0.13, 0, -2 * math.pi, 40),
    _cubic(const Offset(0.71, 0.3), const Offset(0.7, 0.5),
        const Offset(0.56, 0.72), const Offset(0.3, 0.84)),
  ]);

  /// س — two gentle teeth flowing into a wide bowl (simplified).
  static final List<Offset> _arSin = _join([
    _line(const Offset(0.88, 0.38), const Offset(0.8, 0.52), 6),
    _line(const Offset(0.8, 0.52), const Offset(0.72, 0.38), 6),
    _line(const Offset(0.72, 0.38), const Offset(0.64, 0.52), 6),
    _line(const Offset(0.64, 0.52), const Offset(0.56, 0.38), 6),
    _cubic(const Offset(0.56, 0.38), const Offset(0.58, 0.6),
        const Offset(0.5, 0.78), const Offset(0.36, 0.78)),
    _cubic(const Offset(0.36, 0.78), const Offset(0.24, 0.78),
        const Offset(0.14, 0.68), const Offset(0.14, 0.52)),
  ]);

  // ------------------------------------------------------------- table

  static final Map<String, TracePath> _paths = {
    'shape_circle': TracePath(strokes: [_circle]),
    'shape_square': TracePath(strokes: [_square]),
    'shape_triangle': TracePath(strokes: [_triangle]),
    'shape_heart': TracePath(strokes: [_heart]),
    'shape_star': TracePath(strokes: [_star]),
    'num_1': TracePath(strokes: [_digit1]),
    'num_2': TracePath(strokes: [_digit2]),
    'num_3': TracePath(strokes: [_digit3]),
    'num_4': _digit4,
    'num_5': _digit5,
    'letter_a': _letterA,
    'letter_c': TracePath(strokes: [_letterC]),
    'letter_l': TracePath(strokes: [_letterL]),
    'letter_o': TracePath(strokes: [_letterO]),
    'letter_s': TracePath(strokes: [_letterS]),
    'letter_t': _letterT,
    'ar_alif': TracePath(strokes: [_arAlif]),
    'ar_ba': _arBa,
    'ar_lam': TracePath(strokes: [_arLam]),
    'ar_waw': TracePath(strokes: [_arWaw]),
    'ar_sin': TracePath(strokes: [_arSin]),
  };
}
