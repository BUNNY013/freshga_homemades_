import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../models/address_model.dart';
import '../../../../providers/customer_provider.dart';
import '../../widgets/checkout/address_bottom_sheet.dart';

class AddressBookScreen extends StatelessWidget {
  const AddressBookScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Saved Addresses', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.white,
        elevation: 0.5,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: Consumer<CustomerProvider>(
        builder: (context, customerProvider, child) {
          final customer = customerProvider.currentCustomer;
          final addresses = customer?.savedAddresses ?? [];

          if (addresses.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(40),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: AppColors.primaryGreen.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.location_on_outlined, size: 56, color: AppColors.primaryGreen),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'No Saved Addresses Yet',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Save your Home, Work, and other delivery addresses for faster checkout.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: addresses.length,
            separatorBuilder: (_, __) => const SizedBox(height: 14),
            itemBuilder: (context, index) {
              final address = addresses[index];
              return _buildAddressCard(context, address, customerProvider);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddEditAddressModal(context, null),
        backgroundColor: AppColors.primaryGreen,
        icon: const Icon(Icons.add_location_alt_outlined, color: Colors.white),
        label: const Text('Add New Address', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
      ),
    );
  }

  Widget _buildAddressCard(BuildContext context, AddressModel address, CustomerProvider provider) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: address.isDefault ? AppColors.primaryGreen : Colors.grey.shade200,
          width: address.isDefault ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            address.addressType == 'Home' ? Icons.home_outlined : 
            address.addressType == 'Work' ? Icons.work_outline : Icons.location_on_outlined,
            color: address.isDefault ? AppColors.primaryGreen : Colors.grey.shade600,
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
                    if (address.isDefault)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: AppColors.primaryGreen, borderRadius: BorderRadius.circular(4)),
                        child: const Text("DEFAULT", style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        address.name,
                        style: TextStyle(color: Colors.grey.shade700, fontSize: 14),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
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
          const SizedBox(width: 8),
          PopupMenuButton<String>(
            padding: EdgeInsets.zero,
            icon: const Icon(Icons.more_vert_rounded, color: AppColors.textSecondary, size: 20),
            onSelected: (value) async {
              if (value == 'edit') {
                _showAddEditAddressModal(context, address);
              } else if (value == 'delete') {
                await provider.removeAddress(address.id);
              } else if (value == 'default') {
                await provider.setDefaultAddress(address.id);
              }
            },
            itemBuilder: (context) => [
              if (!address.isDefault)
                const PopupMenuItem(
                  value: 'default',
                  child: Row(
                    children: [
                      Icon(Icons.check_circle_outline, color: AppColors.primaryGreen, size: 20),
                      SizedBox(width: 8),
                      Text('Set as Default', style: TextStyle(fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              const PopupMenuItem(value: 'edit', child: Text('Edit Address')),
              const PopupMenuItem(
                value: 'delete',
                child: Text('Delete Address', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showAddEditAddressModal(BuildContext context, AddressModel? existing) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddressBottomSheet(
        startInAddMode: existing == null,
        addressToEdit: existing,
      ),
    );
  }
}
