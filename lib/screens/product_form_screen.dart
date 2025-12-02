import 'package:Eva03/models/product_model.dart';
import 'package:Eva03/services/firestore_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

class ProductFormScreen extends StatefulWidget {
  /// El producto a editar. Si es nulo, se asume que se está creando un nuevo producto.
  final ProductModel? product;

  const ProductFormScreen({super.key, this.product});

  @override
  State<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends State<ProductFormScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controladores para cada campo del formulario
  late TextEditingController _nameController;
  late TextEditingController _skuController;
  late TextEditingController _supplierController;
  late TextEditingController _purchasePriceController;
  late TextEditingController _categoryController;
  late TextEditingController _stockController;
  late TextEditingController _minStockController;

  bool get isEditing => widget.product != null;

  @override
  void initState() {
    super.initState();
    // Inicializamos los controladores con los datos del producto si estamos editando.
    _nameController = TextEditingController(text: widget.product?.name ?? '');
    _skuController = TextEditingController(text: widget.product?.sku ?? '');
    _supplierController = TextEditingController(text: widget.product?.supplier ?? '');
    _purchasePriceController = TextEditingController(text: widget.product?.purchasePrice.toString() ?? '');
    _categoryController = TextEditingController(text: widget.product?.category ?? '');
    _stockController = TextEditingController(text: widget.product?.stock.toString() ?? '');
    _minStockController = TextEditingController(text: widget.product?.minStockLevel.toString() ?? '5');
  }

  @override
  void dispose() {
    // Es importante liberar los recursos de los controladores.
    _nameController.dispose();
    _skuController.dispose();
    _supplierController.dispose();
    _purchasePriceController.dispose();
    _categoryController.dispose();
    _stockController.dispose();
    _minStockController.dispose();
    super.dispose();
  }

  Future<void> _saveForm() async {
    // Validamos que todos los campos del formulario cumplan las reglas.
    if (_formKey.currentState!.validate()) {
      final firestoreService = Provider.of<FirestoreService>(context, listen: false);

      try {
        // Creamos un nuevo objeto ProductModel con los datos del formulario.
        // El ID no se puede editar, por lo que lo tomamos del widget.
        final productData = ProductModel(
          id: widget.product?.id ?? '', // El ID es ignorado por Firestore al crear.
          name: _nameController.text,
          sku: _skuController.text,
          supplier: _supplierController.text,
          purchasePrice: double.tryParse(_purchasePriceController.text) ?? 0.0,
          category: _categoryController.text,
          stock: int.tryParse(_stockController.text) ?? 0,
          minStockLevel: int.tryParse(_minStockController.text) ?? 5,
        );

        if (isEditing) {
          await firestoreService.updateProduct(widget.product!.id, productData);
        } else {
          await firestoreService.addProduct(productData);
        }

        // Mostramos un mensaje de éxito y cerramos la pantalla.
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Producto guardado con éxito')),
        );
        Navigator.of(context).pop();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al guardar el producto: $e')),
        );
      }
    }
  }

  Future<void> _deleteProduct() async {
    if (!isEditing) return;

    final bool? shouldDelete = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirmar Eliminación'),
          content: Text('¿Estás seguro de que deseas eliminar "${widget.product!.name}"?'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('CANCELAR'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('ELIMINAR'),
            ),
          ],
        );
      },
    );

    if (shouldDelete == true) {
      final firestoreService = Provider.of<FirestoreService>(context, listen: false);
      try {
        await firestoreService.deleteProduct(widget.product!.id);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Producto eliminado con éxito')));
        Navigator.of(context).pop();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al eliminar el producto: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Editar Producto' : 'Nuevo Producto'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveForm,
          ),
          // Mostramos el botón de eliminar solo en modo edición.
          if (isEditing)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _deleteProduct,
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Nombre del Producto'),
                validator: (value) => (value == null || value.isEmpty) ? 'Campo requerido' : null,
              ),
              TextFormField(
                controller: _skuController,
                decoration: const InputDecoration(labelText: 'Código de Identidad (SKU)'),
                validator: (value) => (value == null || value.isEmpty) ? 'Campo requerido' : null,
              ),
              TextFormField(
                controller: _supplierController,
                decoration: const InputDecoration(labelText: 'Proveedor'),
                validator: (value) => (value == null || value.isEmpty) ? 'Campo requerido' : null,
              ),
              TextFormField(
                controller: _purchasePriceController,
                decoration: const InputDecoration(labelText: 'Valor de Compra'),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))],
                validator: (value) => (value == null || value.isEmpty) ? 'Campo requerido' : null,
              ),
              TextFormField(
                controller: _categoryController,
                decoration: const InputDecoration(labelText: 'Categoría'),
                validator: (value) => (value == null || value.isEmpty) ? 'Campo requerido' : null,
              ),
              TextFormField(
                controller: _stockController,
                decoration: const InputDecoration(labelText: 'Cantidad en Stock'),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (value) => (value == null || value.isEmpty) ? 'Campo requerido' : null,
              ),
              TextFormField(
                controller: _minStockController,
                decoration: const InputDecoration(labelText: 'Nivel Mínimo de Stock para Alerta'),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (value) => (value == null || value.isEmpty) ? 'Campo requerido' : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}