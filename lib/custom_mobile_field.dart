import 'package:flutter/material.dart';

class Country {
  final String code;
  final String name;

  const Country({required this.code, required this.name});
}

const List<Country> countries = [
  Country(code: '+1', name: 'United States'),
  Country(code: '+91', name: 'India'),
  Country(code: '+44', name: 'United Kingdom'),
  Country(code: '+61', name: 'Australia'),
  Country(code: '+65', name: 'Singapore'),
  Country(code: '+49', name: 'Germany'),
  Country(code: '+971', name: 'UAE'),
];

class CustomMobileField extends StatefulWidget {
  final String initialCountryCode;
  final String initialMobileNumber;
  final ValueChanged<String>? onCountryCodeChanged;
  final ValueChanged<String>? onMobileNumberChanged;
  final FocusNode? focusNode;

  const CustomMobileField({
    super.key,
    this.initialCountryCode = '+91',
    this.initialMobileNumber = '',
    this.onCountryCodeChanged,
    this.onMobileNumberChanged,
    this.focusNode,
  });

  @override
  State<CustomMobileField> createState() => _CustomMobileFieldState();
}

class _CustomMobileFieldState extends State<CustomMobileField> {
  late String _selectedCountryCode;
  late TextEditingController _controller;
  late FocusNode _focusNode;
  bool _isFocused = false;
  final OverlayPortalController _overlayController = OverlayPortalController();
  final _link = LayerLink();
  double _width = 300;

  @override
  void initState() {
    super.initState();
    _selectedCountryCode = widget.initialCountryCode;
    _controller = TextEditingController(text: widget.initialMobileNumber);
    _focusNode = widget.focusNode ?? FocusNode();
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void didUpdateWidget(covariant CustomMobileField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialCountryCode != oldWidget.initialCountryCode) {
      setState(() {
        _selectedCountryCode = widget.initialCountryCode;
      });
    }
    if (widget.initialMobileNumber != _controller.text) {
      final selection = _controller.selection;
      _controller.text = widget.initialMobileNumber;
      try {
        _controller.selection = selection;
      } catch (_) {
        _controller.selection = TextSelection.fromPosition(
          TextPosition(offset: _controller.text.length),
        );
      }
    }
  }

  @override
  void dispose() {
    if (widget.focusNode == null) {
      _focusNode.dispose();
    } else {
      _focusNode.removeListener(_onFocusChange);
    }
    _controller.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    setState(() {
      _isFocused = _focusNode.hasFocus;
    });
  }

  Widget _buildDropdown(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      margin: const EdgeInsets.only(top: 8),
      height: 180,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: colorScheme.primary, width: 1.5),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Scrollbar(
          thumbVisibility: true,
          thickness: 6,
          radius: const Radius.circular(3),
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 4),
            itemCount: countries.length,
            itemBuilder: (context, index) {
              final country = countries[index];
              final isSelected = country.code == _selectedCountryCode;

              return InkWell(
                onTap: () {
                  setState(() {
                    _selectedCountryCode = country.code;
                  });
                  if (widget.onCountryCodeChanged != null) {
                    widget.onCountryCodeChanged!(country.code);
                  }
                  _overlayController.hide();
                },
                child: Container(
                  color: isSelected ? Colors.grey.shade100 : Colors.transparent,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 50,
                        child: Text(
                          country.code,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                      Text(
                        country.name,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        _width = constraints.maxWidth;

        return CompositedTransformTarget(
          link: _link,
          child: OverlayPortal(
            controller: _overlayController,
            overlayChildBuilder: (context) {
              return Stack(
                children: [
                  Positioned.fill(
                    child: GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onTap: () {
                        _overlayController.hide();
                      },
                      child: Container(
                        color: Colors.transparent,
                      ),
                    ),
                  ),
                  CompositedTransformFollower(
                    link: _link,
                    showWhenUnlinked: false,
                    targetAnchor: Alignment.bottomLeft,
                    followerAnchor: Alignment.topLeft,
                    child: Material(
                      type: MaterialType.transparency,
                      child: Align(
                        alignment: Alignment.topLeft,
                        child: SizedBox(
                          width: _width,
                          child: _buildDropdown(context),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Mobile Number',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Clickable Country Code
                    GestureDetector(
                      onTap: () {
                        _overlayController.toggle();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _selectedCountryCode,
                              style: theme.textTheme.bodyLarge?.copyWith(
                                color: Colors.grey.shade500,
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(width: 2),
                          ],
                        ),
                      ),
                    ),
                    // Divider '|'
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        '|',
                        style: TextStyle(
                          color: colorScheme.primary,
                          fontSize: 22,
                          fontWeight: FontWeight.w300,
                        ),
                      ),
                    ),
                    // Input TextField
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        focusNode: _focusNode,
                        keyboardType: TextInputType.phone,
                        onChanged: widget.onMobileNumberChanged,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                        decoration: InputDecoration(
                          hintText: '00000 00000',
                          hintStyle: TextStyle(
                            color: Colors.grey.shade400,
                            fontWeight: FontWeight.w600,
                          ),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                    // "Verify" Text Link
                    GestureDetector(
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Verification sent to $_selectedCountryCode ${_controller.text}!'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                      child: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                        child: Text(
                          'Verify',
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            decoration: TextDecoration.underline,
                            decorationColor: Colors.grey,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                // Underscore Indicator
                Container(
                  height: 1.5,
                  color: _isFocused ? colorScheme.primary : Colors.grey.shade300,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
