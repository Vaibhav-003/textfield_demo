import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

/// A custom accessible search text field widget.
///
/// Features:
/// - Prefix widget: back button (focusable in TalkBack)
/// - Suffix widget: clear button (focusable in TalkBack)
/// - Digit-by-digit announcement for numeric input when focused
/// - Normal text reading for non-numeric input
/// - Full TalkBack / accessibility support
class AccessibleSearchField extends StatefulWidget {
  const AccessibleSearchField({
    super.key,
    this.onBackPressed,
    this.onChanged,
    this.onSubmitted,
    this.hintText = 'Search',
    this.controller,
    this.autofocus = false,
  });

  /// Callback when the back button is pressed.
  final VoidCallback? onBackPressed;

  /// Callback when the text changes.
  final ValueChanged<String>? onChanged;

  /// Callback when the user submits (presses done/search on keyboard).
  final ValueChanged<String>? onSubmitted;

  /// Placeholder hint text.
  final String hintText;

  /// Optional external controller.
  final TextEditingController? controller;

  /// Whether the field should autofocus.
  final bool autofocus;

  @override
  State<AccessibleSearchField> createState() => _AccessibleSearchFieldState();
}

class _AccessibleSearchFieldState extends State<AccessibleSearchField> {
  late TextEditingController _controller;
  late FocusNode _textFieldFocusNode;
  bool _hasText = false;
  String _previousValue = '';

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
    _textFieldFocusNode = FocusNode();
    _controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    if (widget.controller == null) {
      _controller.dispose();
    }
    _textFieldFocusNode.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    final currentValue = _controller.text;
    final hadText = _hasText;
    final hasText = currentValue.isNotEmpty;

    if (hadText != hasText) {
      setState(() {
        _hasText = hasText;
      });
    }

    // Announce the newly typed character(s) digit-by-digit if numeric
    if (_textFieldFocusNode.hasFocus &&
        currentValue.length > _previousValue.length) {
      final newChars = currentValue.substring(_previousValue.length);
      _announceNewInput(newChars);
    }

    _previousValue = currentValue;
    widget.onChanged?.call(currentValue);
  }

  /// Announces new input to TalkBack/VoiceOver.
  ///
  /// If the new input is numeric, each digit is announced individually
  /// (e.g., "123" → "1, 2, 3"). Otherwise, the text is announced normally.
  void _announceNewInput(String newChars) {
    if (_isNumeric(newChars)) {
      // Announce digit by digit with spaces for screen reader pacing
      final digitByDigit = newChars.split('').join(', ');
      SemanticsService.announce(digitByDigit, TextDirection.ltr);
    }
    // For non-numeric text, the default TextField semantics handle
    // announcement, so we do not double-announce.
  }

  /// Returns true if the string consists entirely of digits.
  bool _isNumeric(String s) {
    if (s.isEmpty) return false;
    return s.runes.every((r) => r >= 48 && r <= 57); // '0'-'9'
  }

  /// Builds the semantic label for the current text field value.
  ///
  /// For numeric content, the label spells out each digit individually
  /// so the screen reader reads "1, 2, 3" instead of "one hundred
  /// twenty-three".
  String _buildSemanticValue(String value) {
    if (value.isEmpty) return '';
    if (_isNumeric(value)) {
      return value.split('').join(', ');
    }
    return value;
  }

  void _clearText() {
    _controller.clear();
    _textFieldFocusNode.requestFocus();
    SemanticsService.announce('Search cleared', TextDirection.ltr);
  }

  void _handleBack() {
    widget.onBackPressed?.call();
    SemanticsService.announce('Navigating back', TextDirection.ltr);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Semantics(
      label: 'Search bar',
      container: true,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.blue),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            // ─── Prefix: Back Button ───────────────────────────────
            _BackButton(onPressed: _handleBack),

            const SizedBox(width: 4),

            // ─── Text Field ────────────────────────────────────────
            Expanded(
              child: Semantics(
                // Override the semantic value so screen readers read
                // numbers digit-by-digit when the field is focused.
                value: _buildSemanticValue(_controller.text),
                excludeSemantics: true,
                textField: true,
                label: _controller.text.isEmpty ? widget.hintText : null,
                focused: _textFieldFocusNode.hasFocus,
                child: TextField(
                  controller: _controller,
                  focusNode: _textFieldFocusNode,
                  autofocus: widget.autofocus,
                  textInputAction: TextInputAction.search,
                  onSubmitted: widget.onSubmitted,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: colorScheme.onSurface,
                  ),
                  decoration: InputDecoration(
                    hintText: widget.hintText,
                    hintStyle: theme.textTheme.bodyLarge?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 14,
                    ),
                  ),
                ),
              ),
            ),

            // ─── Suffix: Clear Button ─────────────────────────────
            if (_hasText) _ClearButton(onPressed: _clearText),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  Back Button (prefix)
// ═══════════════════════════════════════════════════════════════════════════

/// A semantically independent back button that is individually focusable
/// by TalkBack / VoiceOver.
class _BackButton extends StatelessWidget {
  const _BackButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      // Ensure this is its own focusable node for the screen reader.
      button: true,
      label: 'Back button. Double tap to go back',
      excludeSemantics: true,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onPressed,
          customBorder: const CircleBorder(),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Icon(
              Icons.arrow_back,
              color: Theme.of(context).colorScheme.onSurface,
              semanticLabel: null, // handled by parent Semantics
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  Clear Button (suffix)
// ═══════════════════════════════════════════════════════════════════════════

/// A semantically independent clear button that is individually focusable
/// by TalkBack / VoiceOver.
class _ClearButton extends StatelessWidget {
  const _ClearButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Clear search text. Double tap to clear',
      excludeSemantics: true,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onPressed,
          customBorder: const CircleBorder(),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Icon(
              Icons.close,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              semanticLabel: null, // handled by parent Semantics
            ),
          ),
        ),
      ),
    );
  }
}
