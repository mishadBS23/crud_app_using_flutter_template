import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../riverpod/update_product_provider.dart';

class UpdateProductView extends ConsumerStatefulWidget {
  const UpdateProductView({
    super.key,
    required this.id,
    required this.productId,
    required this.productName,
    required this.image,
    required this.unitPrice,
    required this.qty,
    required this.totalPrice,
    required this.productCode,
  });

  final String id;
  final String productId;
  final String productName;
  final String productCode;
  final String image;
  final String unitPrice;
  final String qty;
  final String totalPrice;

  @override
  ConsumerState<UpdateProductView> createState() => _UpdateProductViewState();
}

class _UpdateProductViewState extends ConsumerState<UpdateProductView> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _productNameController;
  late final TextEditingController _productCodeController;
  late final TextEditingController _imgController;
  late final TextEditingController _unitPriceController;
  late final TextEditingController _qtyController;
  late final TextEditingController _totalPriceController;

  @override
  void initState() {
    super.initState();
    _productNameController = TextEditingController(text: widget.productName);
    _productCodeController = TextEditingController(text: widget.productCode);
    _imgController = TextEditingController(text: widget.image);
    _unitPriceController = TextEditingController(text: widget.unitPrice);
    _qtyController = TextEditingController(text: widget.qty);
    _totalPriceController = TextEditingController(text: widget.totalPrice);
  }

  @override
  void dispose() {
    _productNameController.dispose();
    _productCodeController.dispose();
    _imgController.dispose();
    _unitPriceController.dispose();
    _qtyController.dispose();
    _totalPriceController.dispose();
    super.dispose();
  }

  Future<void> _updateProduct() async {
    if (_formKey.currentState!.validate()) {
      await ref
          .read(updateProductProvider.notifier)
          .updateProduct(
            id: widget.id,
            productName: _productNameController.text,
            productCode: _productCodeController.text,
            img: _imgController.text,
            unitPrice: _unitPriceController.text,
            qty: _qtyController.text,
            totalPrice: _totalPriceController.text,
          );

      final state = ref.read(updateProductProvider);

      if (state.hasError) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(state.error.toString())));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Product updated successfully!")),
        );
        Navigator.pop(context);
      }
    }
  }

  Widget _buildTextField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        validator: (value) =>
            (value == null || value.isEmpty) ? 'This field is required' : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(updateProductProvider);

    return Scaffold(
      appBar: AppBar(title: const Text("Update Product")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              _buildTextField("Product Name", _productNameController),
              _buildTextField("Product Code", _productCodeController),
              _buildTextField("Image URL", _imgController),
              _buildTextField("Unit Price", _unitPriceController),
              _buildTextField("Quantity", _qtyController),
              _buildTextField("Total Price", _totalPriceController),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: state.isLoading ? null : _updateProduct,
                child: state.isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text("Submit"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
