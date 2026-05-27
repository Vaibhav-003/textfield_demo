import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'custom_mobile_field.dart';
import 'nominee_store.dart';

class NomineeScreen extends StatefulWidget {
  const NomineeScreen({super.key});

  @override
  State<NomineeScreen> createState() => _NomineeScreenState();
}

class _NomineeScreenState extends State<NomineeScreen> {
  final NomineeStore _store = NomineeStore();
  final PageController _pageController = PageController();
  int _activeTab = 0;
  // Nominee nominee = Nominee();

  // We maintain controllers for each possible nominee tab to keep cursor behavior smooth.
  final List<TextEditingController> _nameControllers = [];
  final List<TextEditingController> _addressControllers = [];

  @override
  void initState() {
    super.initState();
    _syncControllers();
    // nominee = _store.nominees[0];
  }

  void _syncControllers() {
    final targetLength = _store.nominees.length;

    while (_nameControllers.length < targetLength) {
      final index = _nameControllers.length;
      final nominee = _store.nominees[index];

      final nameController = TextEditingController(text: nominee.name);
      final addressController = TextEditingController(text: nominee.address);

      nameController.addListener(() {
        _store.updateNominee(index, name: nameController.text);
      });
      addressController.addListener(() {
        _store.updateNominee(index, address: addressController.text);
      });

      _nameControllers.add(nameController);
      _addressControllers.add(addressController);
    }

    while (_nameControllers.length > targetLength) {
      _nameControllers.removeLast().dispose();
      _addressControllers.removeLast().dispose();
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    for (final c in _nameControllers) {
      c.dispose();
    }
    for (final c in _addressControllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _addNominee() {
    if (_store.nominees.length < 4) {
      _store.addNominee();
      _syncControllers();
      // Animate to the newly added nominee tab
      final newIndex = _store.nominees.length - 1;
      setState(() {
        _activeTab = newIndex;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_pageController.hasClients) {
          _pageController.animateToPage(
            newIndex,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        }
      });
    }
  }

  void _removeNominee(int index) {
    if (_store.nominees.length > 1) {
      _store.removeNominee(index);
      _syncControllers();

      int newIndex = _activeTab;
      if (_activeTab >= _store.nominees.length) {
        newIndex = _store.nominees.length - 1;
      }
      setState(() {
        _activeTab = newIndex;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_pageController.hasClients) {
          _pageController.jumpToPage(newIndex);
        }
      });
    }
  }

  void _showSummarySheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final theme = Theme.of(context);
        final colorScheme = theme.colorScheme;

        return Observer(
          builder: (context) {
            return Container(
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(28),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 16,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              padding: EdgeInsets.only(
                top: 24,
                left: 24,
                right: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: colorScheme.outlineVariant,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Icon(
                        Icons.assignment_ind_outlined,
                        color: colorScheme.primary,
                        size: 28,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Nominees Summary',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Stored successfully inside the MobX store',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const Divider(height: 32),
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.of(context).size.height * 0.5,
                    ),
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: _store.nominees.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 16),
                      itemBuilder: (context, index) {
                        final nominee = _store.nominees[index];
                        final name = nominee.name.trim().isEmpty
                            ? 'Nominee ${index + 1}'
                            : nominee.name;
                        final address = nominee.address.trim().isEmpty
                            ? 'Not Provided'
                            : nominee.address;
                        final phone = nominee.mobileNumber.trim().isEmpty
                            ? 'Not Provided'
                            : '${nominee.countryCode} ${nominee.mobileNumber}';

                        return Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                colorScheme.primaryContainer.withValues(
                                  alpha: 0.2,
                                ),
                                colorScheme.secondaryContainer.withValues(
                                  alpha: 0.1,
                                ),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: colorScheme.primaryContainer.withValues(
                                alpha: 0.4,
                              ),
                              width: 1,
                            ),
                          ),
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    name,
                                    style: theme.textTheme.titleMedium
                                        ?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: colorScheme.onPrimaryContainer,
                                        ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: colorScheme.primary,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      '#${index + 1}',
                                      style: theme.textTheme.labelSmall
                                          ?.copyWith(
                                            color: colorScheme.onPrimary,
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(
                                    Icons.location_on_outlined,
                                    size: 16,
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      address,
                                      style: theme.textTheme.bodyMedium
                                          ?.copyWith(
                                            color: colorScheme.onSurfaceVariant,
                                          ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(
                                    Icons.phone_outlined,
                                    size: 16,
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    phone,
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: colorScheme.onSurfaceVariant,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      backgroundColor: colorScheme.primary,
                      foregroundColor: colorScheme.onPrimary,
                      elevation: 0,
                    ),
                    child: const Text(
                      'Close Summary',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Observer(
      builder: (context) {
        final nomineeCount = _store.nominees.length;

        return Scaffold(
          appBar: AppBar(
            title: const Text(
              'Nominees Info',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            elevation: 0,
            backgroundColor: colorScheme.surface,
            surfaceTintColor: Colors.transparent,
            actions: [
              IconButton(
                icon: const Icon(Icons.info_outline_rounded),
                onPressed: () => _showSummarySheet(context),
              ),
            ],
          ),
          body: Column(
            children: [
              // Beautiful Custom Tab bar + Add Button Row
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                color: colorScheme.surface,
                child: Row(
                  children: [
                    // Dynamic horizontal tabs list
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: List.generate(nomineeCount, (index) {
                            final isActive = index == _activeTab;
                            final nominee = _store.nominees[index];
                            final displayName = nominee.name.trim().isEmpty
                                ? 'Nominee ${index + 1}'
                                : nominee.name.split(' ').first;

                            return Container(
                              margin: const EdgeInsets.only(right: 8),
                              child: ChoiceChip(
                                label: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(displayName),
                                    if (nomineeCount > 1) ...[
                                      const SizedBox(width: 4),
                                      GestureDetector(
                                        onTap: () => _removeNominee(index),
                                        child: Icon(
                                          Icons.close_rounded,
                                          size: 14,
                                          color: isActive
                                              ? colorScheme.onPrimary
                                              : colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                selected: isActive,
                                onSelected: (selected) {
                                  if (selected) {
                                    setState(() {
                                      _activeTab = index;
                                      // nominee = _store.nominees[index];
                                    });
                                    _pageController.animateToPage(
                                      index,
                                      duration: const Duration(
                                        milliseconds: 300,
                                      ),
                                      curve: Curves.easeInOut,
                                    );
                                  }
                                },
                                selectedColor: colorScheme.primary,
                                labelStyle: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: isActive
                                      ? colorScheme.onPrimary
                                      : colorScheme.onSurface,
                                ),
                                backgroundColor: colorScheme
                                    .surfaceContainerHighest
                                    .withValues(alpha: 0.5),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: BorderSide(
                                    color: isActive
                                        ? Colors.transparent
                                        : colorScheme.outlineVariant.withValues(
                                            alpha: 0.5,
                                          ),
                                  ),
                                ),
                                showCheckmark: false,
                              ),
                            );
                          }),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Add Nominee Button
                    if (nomineeCount < 4)
                      Container(
                        decoration: BoxDecoration(
                          color: colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: IconButton(
                          icon: Icon(
                            Icons.add,
                            color: colorScheme.onPrimaryContainer,
                          ),
                          tooltip: 'Add Nominee',
                          onPressed: _addNominee,
                        ),
                      )
                    else
                      Container(
                        decoration: BoxDecoration(
                          color: colorScheme.outlineVariant.withValues(
                            alpha: 0.3,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const IconButton(
                          icon: Icon(Icons.add, color: Colors.grey),
                          onPressed: null,
                        ),
                      ),
                  ],
                ),
              ),
              const Divider(height: 1),
              // Tab contents using PageView
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: nomineeCount,
                  onPageChanged: (index) {
                    setState(() {
                      _activeTab = index;
                    });
                  },
                  itemBuilder: (context, index) {
                    final nominee = _store.nominees[index];

                    return SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Nominee Details #${index + 1}',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: colorScheme.primary,
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Name Input
                          Text(
                            'Name',
                            style: theme.textTheme.labelMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _nameControllers[index],
                            style: const TextStyle(fontWeight: FontWeight.w500),
                            decoration: InputDecoration(
                              prefixIcon: const Icon(
                                Icons.person_outline_rounded,
                              ),
                              hintText: 'Enter full name',
                              filled: true,
                              fillColor: colorScheme.surfaceContainerHighest
                                  .withValues(alpha: 0.15),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: colorScheme.outlineVariant.withValues(
                                    alpha: 0.5,
                                  ),
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: colorScheme.outlineVariant.withValues(
                                    alpha: 0.5,
                                  ),
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: colorScheme.primary,
                                  width: 2,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Address Input
                          Text(
                            'Address',
                            style: theme.textTheme.labelMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _addressControllers[index],
                            style: const TextStyle(fontWeight: FontWeight.w500),
                            maxLines: 3,
                            decoration: InputDecoration(
                              prefixIcon: const Padding(
                                padding: EdgeInsets.only(bottom: 32.0),
                                child: Icon(Icons.home_outlined),
                              ),
                              hintText: 'Enter home address',
                              filled: true,
                              fillColor: colorScheme.surfaceContainerHighest
                                  .withValues(alpha: 0.15),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: colorScheme.outlineVariant.withValues(
                                    alpha: 0.5,
                                  ),
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: colorScheme.outlineVariant.withValues(
                                    alpha: 0.5,
                                  ),
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: colorScheme.primary,
                                  width: 2,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Mobile Number Input
                          CustomMobileField(
                            initialCountryCode: nominee.countryCode,
                            initialMobileNumber: nominee.mobileNumber,
                            onCountryCodeChanged: (code) {
                              _store.updateNominee(index, countryCode: code);
                            },
                            onMobileNumberChanged: (number) {
                              _store.updateNominee(index, mobileNumber: number);
                            },
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
          bottomNavigationBar: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton.icon(
                onPressed: () => _showSummarySheet(context),
                icon: const Icon(Icons.check_circle_outline_rounded),
                label: const Text(
                  'Save & View Summary',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                  elevation: 2,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
