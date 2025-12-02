import 'package:Eva03/models/kit_model.dart';
import 'package:Eva03/models/product_model.dart';
import 'package:Eva03/services/firestore_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

class KitFormScreen extends StatefulWidget {
  final KitModel? kit;

  const KitFormScreen({super.key, this.kit});

  @override
  State<KitFormScreen> createState() => _KitFormScreenState();
}

class _KitFormScreenState extends State<KitFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _skuController;
  late TextEditingController _categoryController;
  late TextEditingController _salePriceController;
  late List<KitComponent> _components;

  List<ProductModel> _availableProducts = [];
  bool _isLoadingProducts = true;

  bool get isEditing => widget.kit != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.kit?.name ?? '');
    _skuController = TextEditingController(text: widget.kit?.sku ?? '');
    _categoryController = TextEditingController(text: widget.kit?.category ?? '');
    _salePriceController = TextEditingController(text: widget.kit?.salePrice.toString() ?? '');
    _components = List<KitComponent>.from(widget.kit?.components ?? []);
    _fetchProducts();
  }

  Future<void> _fetchProducts() async {
    final firestoreService = Provider.of<FirestoreService>(context, listen: false);
    // Usamos .first para obtener el valor actual del stream una sola vez.
    final products = await firestoreService.getProducts().first;
    setState(() {
      _availableProducts = products;
      _isLoadingProducts = false;
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _skuController.dispose();
    _categoryController.dispose();
    _salePriceController.dispose();
    super.dispose();
  }

  Future<void> _saveForm() async {
    if (_formKey.currentState!.validate()) {
      if (_components.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Un kit debe tener al menos un componente.')),
        );
        return;
      }

      final firestoreService = Provider.of<FirestoreService>(context, listen: false);
      final kitData = KitModel(
        id: widget.kit?.id ?? '',
        name: _nameController.text,
        sku: _skuController.text,
        category: _categoryController.text,
        salePrice: double.tryParse(_salePriceController.text) ?? 0.0,
        components: _components,
      );

      try {
        if (isEditing) {
          await firestoreService.updateKit(widget.kit!.id, kitData);
        } else {
          await firestoreService.addKit(kitData);
        }
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Kit guardado con éxito')));
        Navigator.of(context).pop();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al guardar el kit: $e')));
      }
    }
  }

  Future<void> _deleteKit() async {
    if (!isEditing) return;

    final bool? shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Eliminación'),
        content: Text('¿Estás seguro de que deseas eliminar el kit "${widget.kit!.name}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('CANCELAR')),
          TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('ELIMINAR')),
        ],
      ),
    );

    if (shouldDelete == true) {
      final firestoreService = Provider.of<FirestoreService>(context, listen: false);
      try {
        // Usamos el método deleteKit que ya existe en nuestro servicio.
        await firestoreService.deleteKit(widget.kit!.id);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Kit eliminado con éxito')));
        // Usamos pop para cerrar la pantalla de edición después de eliminar.
        Navigator.of(context).pop();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al eliminar el kit: $e')));
      }
    }
  }

  void _showAddComponentDialog() {
    ProductModel? selectedProduct;
    final quantityController = TextEditingController(text: '1');

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Añadir Componente'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<ProductModel>(
                hint: const Text('Seleccionar producto'),
                isExpanded: true,
                items: _availableProducts.map((product) {
                  return DropdownMenuItem(value: product, child: Text(product.name));
                }).toList(),
                onChanged: (product) => selectedProduct = product,
                validator: (value) => value == null ? 'Seleccione un producto' : null,
              ),
              TextFormField(
                controller: quantityController,
                decoration: const InputDecoration(labelText: 'Cantidad'),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('CANCELAR')),
            ElevatedButton(
              onPressed: () {
                if (selectedProduct != null) {
                  final quantity = int.tryParse(quantityController.text) ?? 1;
                  setState(() {
                    _components.add(KitComponent(productId: selectedProduct!.id, quantity: quantity));
                  });
                  Navigator.of(context).pop();
                }
              },
              child: const Text('AÑADIR'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Editar Kit' : 'Nuevo Kit'),
        actions: [
          // Mostramos el botón de eliminar solo en modo edición.
          if (isEditing) IconButton(icon: const Icon(Icons.delete), onPressed: _deleteKit),
          IconButton(icon: const Icon(Icons.save), onPressed: _saveForm),
        ],
      ),
      body: _isLoadingProducts
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(labelText: 'Nombre del Kit'),
                      validator: (value) => (value == null || value.isEmpty) ? 'Campo requerido' : null,
                    ),
                    TextFormField(
                      controller: _skuController,
                      decoration: const InputDecoration(labelText: 'Código de Identidad (SKU)'),
                      validator: (value) => (value == null || value.isEmpty) ? 'Campo requerido' : null,
                    ),
                    TextFormField(
                      controller: _categoryController,
                      decoration: const InputDecoration(labelText: 'Categoría'),
                      validator: (value) => (value == null || value.isEmpty) ? 'Campo requerido' : null,
                    ),
                    TextFormField(
                      controller: _salePriceController,
                      decoration: const InputDecoration(labelText: 'Precio de Venta'),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))],
                      validator: (value) => (value == null || value.isEmpty) ? 'Campo requerido' : null,
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Componentes', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.add),
                          label: const Text('Añadir'),
                          onPressed: _showAddComponentDialog,
                        ),
                      ],
                    ),
                    Expanded(
                      child: _components.isEmpty
                          ? const Center(child: Text('Añada componentes al kit.'))
                          : ListView.builder(
                              itemCount: _components.length,
                              itemBuilder: (context, index) {
                                final component = _components[index];
                                // Buscamos el nombre del producto para mostrarlo
                                final product = _availableProducts.firstWhere(
                                  (p) => p.id == component.productId,
                                  orElse: () => ProductModel(
                                      id: '?', name: 'Producto no encontrado', sku: '', supplier: '', purchasePrice: 0, category: '', stock: 0),
                                );

                                return ListTile(
                                  title: Text(product.name),
                                  subtitle: Text('Cantidad: ${component.quantity}'),
                                  trailing: IconButton(
                                    icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                                    onPressed: () {
                                      setState(() {
                                        _components.removeAt(index);
                                      });
                                    },
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}