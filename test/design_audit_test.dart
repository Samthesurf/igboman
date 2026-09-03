import 'dart:io';

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/source/line_info.dart';
import 'package:flutter_test/flutter_test.dart';

// ---------------------------------------------------------------------------
// Design-system audit
//
// Runs the Dart parser over every file under lib/ (no resolution needed) and
// enforces the visual rules of the design system:
//   1. no gradients anywhere, except intentional game-look depth in the
//      files listed in _gameLookFiles (temple-run-look branch only);
//   2. no BoxShadow with a positive blur radius, except soft lifted shadows
//      in the same _gameLookFiles (temple-run-look branch only);
//   3. EdgeInsets arguments must be multiples of 4 (the 4px grid);
//   4. BorderRadius/Radius circular arguments must be multiples of 4;
//   5. SizedBox/Container width and height must be multiples of 4, except
//      hairline values of 3px or less (thin strokes, connector lines);
//   6. TextStyle fontSize literals restricted to the type scale
//      {12, 14, 16, 20, 24, 32};
//   7. Icon/IconButton size literals restricted to {16, 20, 24, 32}.
//
// TEMPLE-RUN-LOOK EXEMPTION (this branch only):
//   Relaxed: rule 1 (gradients) and rule 2 (shadows), scoped to
//   _gameLookFiles. Why: the flat-only look felt static for an adventurous
//   winding-path journey UI, so shallow brown/green/cream gradients plus
//   soft shadows add trail depth, current-position emphasis, momentum HUD
//   lift, and bolder streak celebrations while staying in the palette.
//   Removed: the old unit-path connector centering allowlist entry, because
//   _UnitConnector was replaced by the token-clean _TrailSegment painter.
//   Still enforced everywhere, game files included: the 4px grid, radii,
//   sizes, type scale, and icon scale. All new game-look code uses only
//   Spacing, Radii, IconSizes, AvatarSizes, ControlSizes, TypeScale, and
//   AppColors tokens.
//
// Const layout expressions that reference design tokens (Spacing.md,
// ControlSizes.chipHeight and so on) are folded with the token table below,
// so a value like `Spacing.md + ControlSizes.chipHeight / 2 - 1` is still
// checked (grid rules 3-5 only; scale rules 6-7 apply to literals).
//
// NOTE: in this analyzer version, `const Foo(...)` parses as an
// InstanceCreationExpression while a non-const `Foo(...)` parses as a
// MethodInvocation, and `EdgeInsets.symmetric(...)` projects the class onto
// the import-prefix slot. Both shapes are handled below.
// ---------------------------------------------------------------------------

/// Values of the design tokens from lib/theme/dimens.dart, used to fold
/// const layout expressions during the audit.
const _tokenValues = <String, double>{
  // Spacing
  'Spacing.xs': 4,
  'Spacing.s': 8,
  'Spacing.m': 12,
  'Spacing.md': 16,
  'Spacing.lg': 24,
  'Spacing.xl': 32,
  'Spacing.xxl': 40,
  'Spacing.xxxl': 48,
  'Spacing.huge': 64,
  // Radii
  'Radii.chip': 8,
  'Radii.button': 12,
  'Radii.card': 16,
  'Radii.hero': 24,
  // IconSizes
  'IconSizes.s': 16,
  'IconSizes.m': 20,
  'IconSizes.md': 24,
  'IconSizes.lg': 32,
  // AvatarSizes
  'AvatarSizes.chat': 48,
  'AvatarSizes.card': 64,
  'AvatarSizes.hero': 96,
  'AvatarSizes.mini': 32,
  // ControlSizes
  'ControlSizes.buttonHeight': 48,
  'ControlSizes.chipHeight': 32,
  'ControlSizes.progressBarS': 8,
  'ControlSizes.progressBarMd': 12,
  'ControlSizes.minTouchTarget': 48,
  'ControlSizes.contentMaxWidth': 600,
  // TypeScale
  'TypeScale.display': 32,
  'TypeScale.headline': 24,
  'TypeScale.title': 20,
  'TypeScale.body': 16,
  'TypeScale.bodySmall': 14,
  'TypeScale.label': 14,
  'TypeScale.caption': 12,
};

/// Allowed TextStyle fontSize literals (the type scale).
final _allowedFontSizes = <double>{12, 14, 16, 20, 24, 32};

/// Allowed Icon/IconButton size literals.
final _allowedIconSizes = <double>{16, 20, 24, 32};

/// Game-look surfaces where gradients and soft shadows are intentionally
/// allowed (temple-run-look branch only). Every other file still bans them.
const _gameLookFiles = <String>{
  'lib/screens/home_screen.dart',
  'lib/screens/lesson_screen.dart',
  'lib/widgets/streak_celebration.dart',
  'lib/widgets/streak_chip.dart',
};

/// Justified exceptions, keyed by `file:line`. Keep this list as small as
/// possible; every entry must be a real layout value that cannot be
/// expressed with the existing tokens.
const _allowlist = <String, String>{};

/// Recursively folds a const layout expression to a double. Literals and
/// token references (Spacing.md, IconSizes.lg) fold; anything else returns
/// null and is treated as compliant (indirection, parameters, locals).
double? _fold(Expression expression) {
  if (expression is IntegerLiteral) return expression.value?.toDouble();
  if (expression is DoubleLiteral) return expression.value;
  if (expression is PrefixedIdentifier) {
    final name = '${expression.prefix.name}.${expression.identifier.name}';
    return _tokenValues[name];
  }
  if (expression is ParenthesizedExpression) {
    return _fold(expression.expression);
  }
  if (expression is BinaryExpression) {
    final left = _fold(expression.leftOperand);
    final right = _fold(expression.rightOperand);
    if (left == null || right == null) return null;
    switch (expression.operator.lexeme) {
      case '+':
        return left + right;
      case '-':
        return left - right;
      case '*':
        return left * right;
      case '/':
        return right == 0 ? null : left / right;
      default:
        return null;
    }
  }
  if (expression is PrefixExpression && expression.operator.lexeme == '-') {
    final operand = _fold(expression.operand);
    return operand == null ? null : -operand;
  }
  return null;
}

class _AuditVisitor extends RecursiveAstVisitor<void> {
  _AuditVisitor(this.filePath, this.lineInfo);

  final String filePath;
  final LineInfo lineInfo;
  final List<String> violations = [];
  final Set<String> usedAllowlistKeys = {};

  String _key(AstNode node) {
    final line = lineInfo.getLocation(node.offset).lineNumber;
    return '$filePath:$line';
  }

  void _flag(AstNode node, String rule, String detail) {
    final key = _key(node);
    if (_allowlist.containsKey(key)) {
      usedAllowlistKeys.add(key);
      return;
    }
    violations.add('$key [$rule]: $detail');
  }

  Expression? _namedArgument(ArgumentList arguments, String name) {
    for (final argument in arguments.arguments) {
      if (argument is NamedArgument && argument.name.lexeme == name) {
        return argument.argumentExpression;
      }
    }
    return null;
  }

  double? _foldNamed(ArgumentList arguments, String name) {
    final argument = _namedArgument(arguments, name);
    return argument == null ? null : _fold(argument);
  }

  /// The value of a literal-only expression (no token indirection), used by
  /// the scale rules (6 and 7).
  double? _literalValue(Expression? expression) {
    if (expression is IntegerLiteral) return expression.value?.toDouble();
    if (expression is DoubleLiteral) return expression.value;
    return null;
  }

  /// Grid rules (3-5) check every argument, folding const token expressions.
  void _checkGrid({
    required ArgumentList args,
    required String rule,
    required AstNode node,
  }) {
    for (final argument in args.arguments) {
      final value = _fold(argument.argumentExpression);
      if (value != null && value % 4 != 0) {
        _flag(node, rule, 'value $value');
      }
    }
  }

  /// Applies every audit rule to a creation-like invocation.
  ///
  /// [className] is the constructed class and [ctorName] the named
  /// constructor segment (null for the unnamed constructor).
  void _auditCreation({
    required String className,
    String? ctorName,
    required ArgumentList arguments,
    required AstNode node,
  }) {
    // Rule 1: no gradients, except intentional game-look depth.
    if (className == 'LinearGradient' ||
        className == 'RadialGradient' ||
        className == 'SweepGradient') {
      if (_gameLookFiles.contains(filePath)) return;
      _flag(node, 'gradient', className);
      return;
    }

    // Rule 2: no BoxShadow with a positive blur radius, except soft
    // game-look lift.
    if (className == 'BoxShadow') {
      final blur = _foldNamed(arguments, 'blurRadius');
      if (blur != null && blur > 0 && !_gameLookFiles.contains(filePath)) {
        _flag(node, 'shadow', 'blurRadius $blur');
      }
      return;
    }

    // Rule 3: EdgeInsets arguments on the 4px grid.
    if (className == 'EdgeInsets' &&
        const {'all', 'only', 'fromLTRB', 'symmetric'}.contains(ctorName)) {
      _checkGrid(args: arguments, rule: 'edge_insets', node: node);
      return;
    }

    // Rule 4: BorderRadius/Radius arguments on the 4px grid.
    if ((className == 'BorderRadius' &&
            const {'circular', 'only', 'all'}.contains(ctorName)) ||
        (className == 'Radius' && ctorName == 'circular')) {
      _checkGrid(args: arguments, rule: 'border_radius', node: node);
      return;
    }

    // Rule 5: SizedBox/Container width and height on the 4px grid, with a
    // hairline exemption for values of 3px or less.
    if (className == 'SizedBox' || className == 'Container') {
      for (final name in const ['width', 'height']) {
        final value = _foldNamed(arguments, name);
        if (value != null && value > 3 && value % 4 != 0) {
          _flag(node, 'size', '$name $value');
        }
      }
      return;
    }

    // Rule 6: TextStyle fontSize literals from the type scale.
    if (className == 'TextStyle') {
      final value = _literalValue(_namedArgument(arguments, 'fontSize'));
      if (value != null && !_allowedFontSizes.contains(value)) {
        _flag(node, 'font_size', 'fontSize $value');
      }
      return;
    }

    // Rule 7: Icon/IconButton size literals from the icon scale. An
    // IconButton with no explicit size uses the theme default (24) and is
    // not flagged.
    if (className == 'Icon' || className == 'IconButton') {
      final sizeName = className == 'Icon' ? 'size' : 'iconSize';
      final value = _literalValue(_namedArgument(arguments, sizeName));
      if (value != null && !_allowedIconSizes.contains(value)) {
        _flag(node, 'icon_size', '$sizeName $value');
      }
    }
  }

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    super.visitInstanceCreationExpression(node);
    final constructor = node.constructorName;
    final typeName = constructor.type;
    // In this analyzer version, `EdgeInsets.symmetric(...)` projects the
    // class onto the import-prefix slot and the constructor onto the type
    // name. Resolve both so prefixed constructors are still audited.
    final prefix = typeName.importPrefix;
    final className = prefix != null
        ? prefix.name.lexeme
        : typeName.name.lexeme;
    final ctorName = prefix != null
        ? typeName.name.lexeme
        : constructor.name?.name;

    _auditCreation(
      className: className,
      ctorName: ctorName,
      arguments: node.argumentList,
      node: node,
    );
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    super.visitMethodInvocation(node);
    final method = node.methodName.name;
    if (method.isEmpty) return;
    final first = method.codeUnitAt(0);
    final target = node.target;
    if (target == null) {
      // Non-const object creation `Foo(...)` projects to a method
      // invocation with an uppercase callee in this analyzer version.
      if (first >= 0x41 && first <= 0x5A) {
        _auditCreation(
          className: method,
          ctorName: null,
          arguments: node.argumentList,
          node: node,
        );
      }
    } else if (target is SimpleIdentifier) {
      // Named constructor `Class.ctor(...)` (e.g. EdgeInsets.all,
      // BorderRadius.circular) projects to a method invocation on the class.
      final targetFirst = target.name.codeUnitAt(0);
      if (targetFirst >= 0x41 && targetFirst <= 0x5A) {
        _auditCreation(
          className: target.name,
          ctorName: method,
          arguments: node.argumentList,
          node: node,
        );
      }
    }
  }
}

void main() {
  test('design audit: lib/ follows the design-system rules', () {
    final libDir = Directory('lib');
    final files = libDir
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('.dart'))
        .toList();
    expect(files, isNotEmpty, reason: 'no lib/ files found to audit');

    final violations = <String>[];
    final usedAllowlistKeys = <String>{};

    for (final file in files) {
      final result = parseString(
        content: file.readAsStringSync(),
        path: file.path,
      );
      final visitor = _AuditVisitor(file.path, result.lineInfo);
      result.unit.accept(visitor);
      violations.addAll(visitor.violations);
      usedAllowlistKeys.addAll(visitor.usedAllowlistKeys);
    }

    expect(
      _allowlist.length,
      lessThanOrEqualTo(5),
      reason:
          'allowlist is capped at 5 entries '
          '(got ${_allowlist.length})',
    );

    expect(
      violations,
      isEmpty,
      reason: 'design audit violations:\n${violations.join('\n')}',
    );
  });

  test('design audit: allowlist has no dead entries', () {
    final libDir = Directory('lib');
    final usedAllowlistKeys = <String>{};

    for (final file
        in libDir
            .listSync(recursive: true)
            .whereType<File>()
            .where((file) => file.path.endsWith('.dart'))) {
      final result = parseString(
        content: file.readAsStringSync(),
        path: file.path,
      );
      final visitor = _AuditVisitor(file.path, result.lineInfo);
      result.unit.accept(visitor);
      usedAllowlistKeys.addAll(visitor.usedAllowlistKeys);
    }

    for (final entry in _allowlist.entries) {
      expect(
        usedAllowlistKeys,
        contains(entry.key),
        reason: 'dead allowlist entry ${entry.key} (${entry.value})',
      );
    }
  });
}
