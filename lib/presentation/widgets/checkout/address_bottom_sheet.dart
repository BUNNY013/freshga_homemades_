import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/address_model.dart';
import '../../../providers/customer_provider.dart';

class AddressBottomSheet extends StatefulWidget {
  final AddressModel? selectedAddress;
  final Function(AddressModel)? onAddressSelected;
  final bool startInAddMode;
  final AddressModel? addressToEdit;

  const AddressBottomSheet({
    super.key,
    this.selectedAddress,
    this.onAddressSelected,
    this.startInAddMode = false,
    this.addressToEdit,
  });

  @override
  State<AddressBottomSheet> createState() => _AddressBottomSheetState();
}

class _AddressBottomSheetState extends State<AddressBottomSheet> {
  bool _isAddingNew = false;
  AddressModel? _addressToEdit;
  bool _isDefault = true;
  
  // Form controllers
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _houseCtrl = TextEditingController();
  final _streetCtrl = TextEditingController();
  final _landmarkCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _districtCtrl = TextEditingController();
  final _stateCtrl = TextEditingController();
  final _pincodeCtrl = TextEditingController();
  final _villageFallbackCtrl = TextEditingController(); // For fallback mode
  String _addressType = 'Home';
  
  bool _isLoadingPincode = false;
  bool _isApiFallback = false; // True when API fails
  List<String> _villages = [];
  String? _selectedVillage;
  
  @override
  void initState() {
    super.initState();
    if (widget.addressToEdit != null) {
      _editAddress(widget.addressToEdit!);
    } else if (widget.startInAddMode) {
      _isAddingNew = true;
      _isDefault = true;
    }
  }
  
  final List<String> _indianStates = [
    'Andhra Pradesh', 'Arunachal Pradesh', 'Assam', 'Bihar', 'Chhattisgarh',
    'Goa', 'Gujarat', 'Haryana', 'Himachal Pradesh', 'Jharkhand', 'Karnataka',
    'Kerala', 'Madhya Pradesh', 'Maharashtra', 'Manipur', 'Meghalaya', 'Mizoram',
    'Nagaland', 'Odisha', 'Punjab', 'Rajasthan', 'Sikkim', 'Tamil Nadu', 'Telangana',
    'Tripura', 'Uttar Pradesh', 'Uttarakhand', 'West Bengal', 
    'Andaman and Nicobar Islands', 'Chandigarh', 'Dadra and Nagar Haveli and Daman and Diu', 
    'Delhi', 'Lakshadweep', 'Puducherry', 'Jammu and Kashmir', 'Ladakh'
  ];

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _houseCtrl.dispose();
    _streetCtrl.dispose();
    _landmarkCtrl.dispose();
    _cityCtrl.dispose();
    _districtCtrl.dispose();
    _stateCtrl.dispose();
    _pincodeCtrl.dispose();
    _villageFallbackCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchPincodeDetails(String pincode, {String? preserveVillage}) async {
    if (pincode.length != 6) return;

    setState(() {
      _isLoadingPincode = true;
      if (preserveVillage == null) {
        _cityCtrl.text = '';
        _stateCtrl.text = '';
      }
    });

    try {
      final response = await http.get(Uri.parse('https://api.postalpincode.in/pincode/$pincode'));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        if (data.isNotEmpty && data[0]['Status'] == 'Success') {
          final postOffices = data[0]['PostOffice'] as List<dynamic>;
          if (postOffices.isNotEmpty) {
            final district = postOffices[0]['District']?.toString() ?? '';
            final state = postOffices[0]['State']?.toString() ?? '';
            final block = postOffices[0]['Block']?.toString() ?? district;
            
            final villageNames = postOffices
                .map((po) => po['Name']?.toString() ?? '')
                .where((name) => name.isNotEmpty)
                .toSet() // Remove duplicates
                .toList();
            
            setState(() {
              _districtCtrl.text = district;
              _cityCtrl.text = block == 'NA' ? district : block;
              _stateCtrl.text = state;
              _villages = villageNames;
              if (preserveVillage != null && villageNames.contains(preserveVillage)) {
                _selectedVillage = preserveVillage;
              } else {
                _selectedVillage = villageNames.isNotEmpty ? villageNames[0] : null;
              }
              _isApiFallback = false;
            });
          }
        } else {
          // API returned invalid status
          setState(() {
            _isApiFallback = true;
            _villages = [];
            _selectedVillage = null;
          });
          if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not fetch Area automatically. Please enter manually.'), backgroundColor: Colors.orange));
        }
      } else {
        // API failed
        setState(() {
          _isApiFallback = true;
          _villages = [];
          _selectedVillage = null;
        });
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Network error. Please enter area manually.'), backgroundColor: Colors.orange));
      }
    } catch (e) {
      debugPrint("Pincode fetch error: $e");
      setState(() {
        _isApiFallback = true;
        _villages = [];
        _selectedVillage = null;
      });
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error fetching area. Please enter manually.'), backgroundColor: Colors.orange));
    } finally {
      if (mounted) setState(() => _isLoadingPincode = false);
    }
  }

  void _editAddress(AddressModel address) {
    setState(() {
      _addressToEdit = address;
      _isAddingNew = true;
      
      _nameCtrl.text = address.name;
      _phoneCtrl.text = address.phoneNumber;
      _houseCtrl.text = address.houseNumber;
      _streetCtrl.text = address.street;
      _landmarkCtrl.text = address.landmark;
      _pincodeCtrl.text = address.pincode;
      
      final cityParts = address.city.split(',').map((e) => e.trim()).toList();
      String? villageToPreserve;
      if (cityParts.length >= 3) {
        villageToPreserve = cityParts[0];
        _selectedVillage = villageToPreserve;
        _villages = [villageToPreserve];
        _cityCtrl.text = cityParts[1];
        _districtCtrl.text = cityParts[2];
      } else if (cityParts.isNotEmpty) {
        _cityCtrl.text = cityParts[0];
        _districtCtrl.text = cityParts.length > 1 ? cityParts[1] : '';
        _villages = [];
        _selectedVillage = null;
      }
      
      _stateCtrl.text = address.state;
      _addressType = address.addressType;
      _isDefault = address.isDefault;
      
      if (_pincodeCtrl.text.length == 6) {
        _fetchPincodeDetails(_pincodeCtrl.text, preserveVillage: villageToPreserve);
      }
    });
  }

  void _saveNewAddress() async {
    if (_formKey.currentState!.validate()) {
      if (!_isApiFallback && _selectedVillage == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please select a Village/Area")));
        return;
      }
      
      String finalVillage = _isApiFallback ? _villageFallbackCtrl.text.trim() : _selectedVillage!;

      final fullCity = "$finalVillage, ${_cityCtrl.text.trim()}, ${_districtCtrl.text.trim()}";

      final newAddress = AddressModel(
        id: _addressToEdit?.id,
        name: _nameCtrl.text,
        phoneNumber: _phoneCtrl.text,
        houseNumber: _houseCtrl.text,
        street: _streetCtrl.text,
        landmark: _landmarkCtrl.text,
        city: fullCity.replaceAll(RegExp(r',\s*,'), ','), // cleanup just in case
        state: _stateCtrl.text,
        pincode: _pincodeCtrl.text,
        addressType: _addressType,
        isDefault: _isDefault,
      );

      final customerProvider = context.read<CustomerProvider>();
      if (_addressToEdit != null) {
        await customerProvider.updateAddress(newAddress);
      } else {
        await customerProvider.addAddress(newAddress);
      }
      widget.onAddressSelected?.call(newAddress);
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 16),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _isAddingNew
                      ? (_addressToEdit != null ? "Edit Address" : "Add New Address")
                      : "Select Delivery Address",
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                if (_isAddingNew)
                  InkWell(
                    onTap: () {
                      if (widget.startInAddMode || widget.addressToEdit != null) {
                        Navigator.pop(context);
                      } else {
                        setState(() {
                          _isAddingNew = false;
                          _addressToEdit = null;
                          _formKey.currentState?.reset();
                          _nameCtrl.clear();
                          _phoneCtrl.clear();
                          _houseCtrl.clear();
                          _streetCtrl.clear();
                          _landmarkCtrl.clear();
                          _cityCtrl.clear();
                          _districtCtrl.clear();
                          _stateCtrl.clear();
                          _pincodeCtrl.clear();
                          _villages.clear();
                          _selectedVillage = null;
                          _villageFallbackCtrl.clear();
                          _isApiFallback = false;
                          _addressType = 'Home';
                          _isDefault = true;
                        });
                      }
                    },
                    child: const Text("Cancel", style: TextStyle(color: AppColors.primaryGreen, fontWeight: FontWeight.bold)),
                  )
                else
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
              ],
            ),
          ),
          const Divider(),
          
          Expanded(
            child: _isAddingNew ? _buildNewAddressForm() : _buildAddressList(),
          ),
        ],
      ),
    );
  }

  Widget _buildAddressList() {
    return Consumer<CustomerProvider>(
      builder: (context, provider, child) {
        final addresses = provider.currentCustomer?.savedAddresses ?? [];
        
        return Column(
          children: [
            InkWell(
              onTap: () => setState(() => _isAddingNew = true),
              child: Container(
                padding: const EdgeInsets.all(16),
                child: const Row(
                  children: [
                    Icon(Icons.add_location_alt_outlined, color: AppColors.primaryGreen),
                    SizedBox(width: 12),
                    Text("Add a new address", style: TextStyle(color: AppColors.primaryGreen, fontWeight: FontWeight.bold, fontSize: 16)),
                    Spacer(),
                    Icon(Icons.chevron_right, color: Colors.grey),
                  ],
                ),
              ),
            ),
            const Divider(thickness: 4, color: Color(0xFFF5F5F5)),
            
            if (addresses.isEmpty)
              const Expanded(
                child: Center(
                  child: Text("No saved addresses.", style: TextStyle(color: Colors.grey)),
                ),
              )
            else
              Expanded(
                child: ListView.separated(
                  itemCount: addresses.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final address = addresses[index];
                    final isSelected = widget.selectedAddress?.id == address.id;
                    
                    return InkWell(
                      onTap: () {
                        widget.onAddressSelected?.call(address);
                        Navigator.pop(context);
                      },
                      child: Container(
                        color: isSelected ? AppColors.primaryGreen.withOpacity(0.05) : Colors.white,
                        padding: const EdgeInsets.all(20),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              address.addressType == 'Home' ? Icons.home_outlined : 
                              address.addressType == 'Work' ? Icons.work_outline : Icons.location_on_outlined,
                              color: isSelected ? AppColors.primaryGreen : Colors.grey.shade600,
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(address.addressType, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                      const SizedBox(width: 12),
                                      Text(address.name, style: TextStyle(color: Colors.grey.shade700, fontSize: 14)),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    address.formattedAddress,
                                    style: TextStyle(color: Colors.grey.shade600, height: 1.4),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    address.phoneNumber,
                                    style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
                                  ),
                                ],
                              ),
                            ),
                            if (isSelected)
                              const Icon(Icons.check_circle, color: AppColors.primaryGreen),
                            PopupMenuButton<String>(
                              padding: EdgeInsets.zero,
                              icon: const Icon(Icons.more_vert, color: Colors.grey),
                              onSelected: (value) {
                                if (value == 'edit') {
                                  _editAddress(address);
                                } else if (value == 'delete') {
                                  provider.removeAddress(address.id);
                                }
                              },
                              itemBuilder: (context) => [
                                const PopupMenuItem(value: 'edit', child: Text('Edit')),
                                const PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: Colors.red))),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildNewAddressForm() {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildTextField(_nameCtrl, "Full Name"),
          const SizedBox(height: 16),
          _buildTextField(_phoneCtrl, "Phone Number", keyboardType: TextInputType.phone),
          const SizedBox(height: 16),
          
          const Text("Address Type", style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _buildTypeChip('Home')),
              const SizedBox(width: 12),
              Expanded(child: _buildTypeChip('Work')),
              const SizedBox(width: 12),
              Expanded(child: _buildTypeChip('Other')),
            ],
          ),
          
          const SizedBox(height: 16),
          _buildTextField(_streetCtrl, "Address"),
          const SizedBox(height: 16),
          _buildTextField(_landmarkCtrl, "Landmark (Optional)", isRequired: false),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                      _buildTextField(
                        _pincodeCtrl, 
                        "Pincode", 
                        keyboardType: TextInputType.number,
                        maxLength: 6,
                        validator: (val) {
                          if (val == null || val.isEmpty) return "Required";
                          if (val.length != 6 || int.tryParse(val) == null) return "Invalid Pincode";
                          if (_cityCtrl.text.isEmpty) return "Invalid Pincode"; // API fetch failed
                          return null;
                        },
                        onChanged: (val) {
                          if (val.length == 6) {
                            _fetchPincodeDetails(val);
                            FocusScope.of(context).unfocus();
                          } else {
                            // Clear fields if they delete a digit
                            setState(() {
                              _cityCtrl.text = '';
                              _districtCtrl.text = '';
                              _stateCtrl.text = '';
                              _villages = [];
                              _selectedVillage = null;
                            });
                          }
                        }
                      ),
                    if (_isLoadingPincode)
                      const Padding(
                        padding: EdgeInsets.only(top: 4.0),
                        child: Text("Fetching...", style: TextStyle(color: AppColors.primaryGreen, fontSize: 10, fontStyle: FontStyle.italic)),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _isApiFallback 
                  ? _buildTextField(_villageFallbackCtrl, "Village/Area")
                  : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("Village/Area", style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.w500)),
                            const SizedBox(height: 8),
                            Container(
                              height: 48,
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              decoration: BoxDecoration(
                                color: _villages.isEmpty ? Colors.grey.shade50 : Colors.white,
                                border: Border.all(color: Colors.grey.shade300),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: _selectedVillage,
                                  isExpanded: true,
                                  menuMaxHeight: 300,
                                  hint: const Text("Select Area", style: TextStyle(fontSize: 14)),
                                  icon: const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
                                  items: _villages.map((String village) {
                                    return DropdownMenuItem<String>(
                                      value: village,
                                      child: Text(village, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                                    );
                                  }).toList(),
                                  onChanged: _villages.isEmpty ? null : (String? newValue) {
                                    setState(() {
                                      _selectedVillage = newValue;
                                    });
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _buildTextField(_cityCtrl, "City/Taluka", readOnly: !_isApiFallback)),
              const SizedBox(width: 16),
              Expanded(child: _buildTextField(_districtCtrl, "District", readOnly: !_isApiFallback)),
            ],
          ),
          const SizedBox(height: 16),
          _isApiFallback
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("State", style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _indianStates.contains(_stateCtrl.text) ? _stateCtrl.text : null,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
                    ),
                    items: _indianStates.map((state) {
                      return DropdownMenuItem(value: state, child: Text(state, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)));
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          _stateCtrl.text = val;
                        });
                      }
                    },
                    validator: (val) => val == null || val.isEmpty ? "Required" : null,
                  ),
                ],
              )
            : _buildTextField(_stateCtrl, "State", readOnly: true),
          const SizedBox(height: 16),
          CheckboxListTile(
            title: const Text("Make this my default address", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            value: _isDefault,
            activeColor: AppColors.primaryGreen,
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            onChanged: (val) {
              setState(() => _isDefault = val ?? true);
            },
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 50,
            child: ElevatedButton(
              onPressed: _saveNewAddress,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGreen,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: const Text("Save Address", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeChip(String type) {
    final isSelected = _addressType == type;
    return InkWell(
      onTap: () => setState(() => _addressType = type),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryGreen.withOpacity(0.1) : Colors.white,
          border: Border.all(color: isSelected ? AppColors.primaryGreen.withOpacity(0.5) : Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        alignment: Alignment.center,
        child: Text(
          type,
          style: TextStyle(
            color: isSelected ? AppColors.primaryGreen : Colors.black87,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, {bool isRequired = true, TextInputType? keyboardType, bool readOnly = false, Function(String)? onChanged, String? Function(String?)? validator, int? maxLength}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.grey,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          readOnly: readOnly,
          onChanged: onChanged,
          maxLength: maxLength,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: readOnly ? Colors.grey.shade700 : Colors.black87
          ),
          validator: validator ?? (isRequired ? (value) {
            if (value == null || value.trim().isEmpty) return "Required";
            return null;
          } : null),
          decoration: InputDecoration(
            filled: true,
            counterText: "", // Hides the max length counter
            fillColor: readOnly ? Colors.grey.shade50 : Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.primaryGreen),
            ),
          ),
        ),
      ],
    );
  }
}
