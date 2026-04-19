import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';

class EditTripDialog extends StatefulWidget {
  final int tripId;
  final double? currentFuelExpense;
  final double? currentParkingCost;
  final double? currentTollCost;
  final Function() onSuccess;

  const EditTripDialog({
    Key? key,
    required this.tripId,
    this.currentFuelExpense,
    this.currentParkingCost,
    this.currentTollCost,
    required this.onSuccess,
  }) : super(key: key);

  @override
  State<EditTripDialog> createState() => _EditTripDialogState();
}

class _EditTripDialogState extends State<EditTripDialog> {
  final _formKey = GlobalKey<FormState>();
  final _fuelController = TextEditingController();
  final _parkingController = TextEditingController();
  final _tollController = TextEditingController();

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Pre-fill with existing values
    if (widget.currentFuelExpense != null) {
      _fuelController.text = widget.currentFuelExpense.toString();
    }
    if (widget.currentParkingCost != null) {
      _parkingController.text = widget.currentParkingCost.toString();
    }
    if (widget.currentTollCost != null) {
      _tollController.text = widget.currentTollCost.toString();
    }
  }

  @override
  void dispose() {
    _fuelController.dispose();
    _parkingController.dispose();
    _tollController.dispose();
    super.dispose();
  }

  Future<void> _updateTrip() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final apiService = context.read<ApiService>();

      // Parse values (null if empty)
      final fuelExpense = _fuelController.text.isNotEmpty
          ? double.tryParse(_fuelController.text)
          : null;
      final parkingCost = _parkingController.text.isNotEmpty
          ? double.tryParse(_parkingController.text)
          : null;
      final tollCost = _tollController.text.isNotEmpty
          ? double.tryParse(_tollController.text)
          : null;

      await apiService.updateTripDetails(
        tripId: widget.tripId,
        fuelExpense: fuelExpense,
        parkingCost: parkingCost,
        tollCost: tollCost,
      );

      if (mounted) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Trip updated successfully!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );

        // Close dialog
        Navigator.pop(context);

        // Trigger refresh
        widget.onSuccess();
      }
    } catch (e) {
      debugPrint('❌ Error updating trip: $e');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update trip: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF16213e),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    const Icon(
                      Icons.edit,
                      color: Color(0xFF00adb5),
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Edit Trip Expenses',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white70),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Fuel Expense
                _buildExpenseField(
                  controller: _fuelController,
                  label: 'Fuel Expense',
                  icon: Icons.local_gas_station,
                  hint: 'Enter fuel cost',
                ),
                const SizedBox(height: 16),

                // Parking Cost
                _buildExpenseField(
                  controller: _parkingController,
                  label: 'Parking Cost',
                  icon: Icons.local_parking,
                  hint: 'Enter parking cost',
                ),
                const SizedBox(height: 16),

                // Toll Cost
                _buildExpenseField(
                  controller: _tollController,
                  label: 'Toll Cost',
                  icon: Icons.toll,
                  hint: 'Enter toll cost',
                ),
                const SizedBox(height: 24),

                // Total Preview
                _buildTotalPreview(),
                const SizedBox(height: 24),

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isLoading ? null : () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: const BorderSide(color: Colors.white38),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _updateTrip,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00adb5),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                            : const Text(
                          'Update',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildExpenseField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required String hint,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: const Color(0xFF00adb5), size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
          ],
          style: const TextStyle(color: Colors.white, fontSize: 16),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
            prefixText: '₹ ',
            prefixStyle: const TextStyle(
              color: Color(0xFF00adb5),
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.05),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF00adb5), width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
          validator: (value) {
            if (value != null && value.isNotEmpty) {
              final amount = double.tryParse(value);
              if (amount == null) {
                return 'Invalid amount';
              }
              if (amount < 0) {
                return 'Amount cannot be negative';
              }
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildTotalPreview() {
    return ValueListenableBuilder(
      valueListenable: _fuelController,
      builder: (context, fuel, _) {
        return ValueListenableBuilder(
          valueListenable: _parkingController,
          builder: (context, parking, _) {
            return ValueListenableBuilder(
              valueListenable: _tollController,
              builder: (context, toll, _) {
                final fuelAmount = double.tryParse(_fuelController.text) ?? 0.0;
                final parkingAmount = double.tryParse(_parkingController.text) ?? 0.0;
                final tollAmount = double.tryParse(_tollController.text) ?? 0.0;
                final total = fuelAmount + parkingAmount + tollAmount;

                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00adb5).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFF00adb5).withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total Expense',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '₹ ${total.toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: Color(0xFF00adb5),
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}

// Helper function to show the dialog
void showEditTripDialog({
  required BuildContext context,
  required int tripId,
  double? currentFuelExpense,
  double? currentParkingCost,
  double? currentTollCost,
  required Function() onSuccess,
}) {
  showDialog(
    context: context,
    builder: (context) => EditTripDialog(
      tripId: tripId,
      currentFuelExpense: currentFuelExpense,
      currentParkingCost: currentParkingCost,
      currentTollCost: currentTollCost,
      onSuccess: onSuccess,
    ),
  );
}