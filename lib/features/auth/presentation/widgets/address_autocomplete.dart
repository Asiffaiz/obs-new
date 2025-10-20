import 'dart:async';

import 'package:flutter/material.dart';
import '../../domain/models/address_model.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/services/google_places_service.dart';
import '../../../../core/config/api_keys.dart';

class AddressAutocomplete extends StatefulWidget {
  final TextEditingController controller;
  final Function(AddressModel) onAddressSelected;
  final String label;
  final String? errorText;

  const AddressAutocomplete({
    Key? key,
    required this.controller,
    required this.onAddressSelected,
    required this.label,
    this.errorText,
  }) : super(key: key);

  @override
  State<AddressAutocomplete> createState() => _AddressAutocompleteState();
}

class _AddressAutocompleteState extends State<AddressAutocomplete> {
  final FocusNode _focusNode = FocusNode();
  final LayerLink _layerLink = LayerLink();
  bool _showSuggestions = false;
  List<AddressModel> _filteredAddresses = [];
  OverlayEntry? _overlayEntry;
  Timer? _debounce;
  bool _isLoading = false;

  // Google Places API key from config
  final _placesService = GooglePlacesService(
    apiKey: ApiKeys.googlePlacesApiKey,
  );

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onSearchChanged);
    _focusNode.addListener(_onFocusChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onSearchChanged);
    _focusNode.removeListener(_onFocusChanged);
    _focusNode.dispose();
    _debounce?.cancel();
    _removeOverlay();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = widget.controller.text;

    if (_debounce?.isActive ?? false) _debounce!.cancel();

    _debounce = Timer(const Duration(milliseconds: 500), () async {
      if (query.isEmpty) {
        setState(() => _filteredAddresses = []);
      } else {
        // Use the Google Places API to fetch address predictions
        final predictions = await _placesService.getPlacePredictions(query);
        setState(() => _filteredAddresses = predictions);
      }

      if (_focusNode.hasFocus) {
        _updateOverlay();
      }
    });
  }

  void _onFocusChanged() {
    if (_focusNode.hasFocus) {
      _showSuggestions = true;
      _updateOverlay();
    } else {
      _showSuggestions = false;
      _removeOverlay();
    }
  }

  void _updateOverlay() {
    _removeOverlay();

    if (_filteredAddresses.isEmpty) {
      return;
    }

    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final size = renderBox.size;

    _overlayEntry = OverlayEntry(
      builder:
          (context) => Positioned(
            width: size.width,
            child: CompositedTransformFollower(
              link: _layerLink,
              showWhenUnlinked: false,
              offset: Offset(0, size.height + 5),
              child: Material(
                elevation: 4,
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  constraints: const BoxConstraints(maxHeight: 200),
                  child: ListView.builder(
                    padding: EdgeInsets.zero,
                    shrinkWrap: true,
                    itemCount: _filteredAddresses.length,
                    itemBuilder: (context, index) {
                      final address = _filteredAddresses[index];
                      final description = address.street;

                      return ListTile(
                        dense: true,
                        title: Text(
                          description,
                          style: AppTextStyles.bodyMedium,
                        ),
                        onTap: () async {
                          // When user taps an address prediction, fetch the full details
                          widget.controller.text = description;
                          // Hide keyboard
                          FocusScope.of(context).unfocus();

                          if (address.placeId != null) {
                            // Show loading indicator in the widget
                            setState(() {
                              _isLoading = true;
                            });

                            // Get full address details
                            final fullAddress = await _placesService
                                .getPlaceDetails(address.placeId!);

                            setState(() {
                              _isLoading = false;
                            });

                            if (fullAddress != null) {
                              widget.onAddressSelected(fullAddress);

                              // Update the controller with the formatted address
                              widget.controller.text = fullAddress.street;
                            }
                          }

                          _removeOverlay();
                          _focusNode.unfocus();
                        },
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _clearText() {
    widget.controller.clear();
    setState(() => _filteredAddresses = []);
    _removeOverlay();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CompositedTransformTarget(
          link: _layerLink,
          child: TextFormField(
            controller: widget.controller,
            focusNode: _focusNode,
            decoration: InputDecoration(
              labelText: widget.label,
              errorText: widget.errorText,
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 18,
              ),
              prefixIcon: Icon(
                Icons.location_on,
                color: AppColors.primaryColor,
              ),
              suffixIcon:
                  widget.controller.text.isNotEmpty
                      ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: _clearText,
                      )
                      : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onChanged: (_) => setState(() {}),
          ),
        ),
        if (_isLoading)
          Padding(
            padding: const EdgeInsets.only(top: 8.0, left: 4),
            child: Row(
              children: [
                SizedBox(
                  height: 16,
                  width: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.primaryColor,
                  ),
                ),
                const SizedBox(width: 8),
                const Text('Loading address details...'),
              ],
            ),
          ),
      ],
    );
  }
}
