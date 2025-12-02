import 'package:Eva03/models/customer_model.dart';
import 'package:Eva03/models/kit_model.dart';
import 'package:Eva03/models/product_model.dart';
import 'package:Eva03/models/quote_model.dart';
import 'package:Eva03/services/firestore_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class QuoteFormScreen extends StatefulWidget {
  final QuoteModel? quote;

  const QuoteFormScreen({super.key, this.quote});

  @override
  State<QuoteFormScreen> createState() => _QuoteFormScreenState();
}

class _QuoteFormScreenState extends State<QuoteFormScreen> {
  final _formKey = GlobalKey<FormState>();

  // State
  CustomerModel? _selectedCustomer;
  List<QuoteItem> _items = [];
  DateTime? _validUntil;
  QuoteStatus _status = QuoteStatus.draft;
  double _total = 0.0;

  // Data for dialogs
  List<CustomerModel> _availableCustomers = [];
  List<ProductModel> _availableProducts = [];
  List<KitModel> _availableKits = [];
  bool _isLoading = true;

  bool get isEditing => widget.quote != null;

  @override
  void initState() {
    super.initState();
    _fetchInitialData();
    if (isEditing) {
      _items = List<QuoteItem>.from(widget.quote!.items);
      _status = widget.quote!.status;
      _validUntil = widget.quote!.validUntil?.toDate();
      _calculateTotal();
    }
  }

  Future<void> _fetchInitialData() async {
    final firestoreService = Provider.of<FirestoreService>(context, listen: false);
    // Fetch all data concurrently
    final results = await Future.wait([
      firestoreService.getCustomers().first,
      firestoreService.getProducts().first,
      firestoreService.getKits().first,
    ]);

    _availableCustomers = results[0] as List<CustomerModel>;
    _availableProducts = results[1] as List<ProductModel>;
    _availableKits = results[2] as List<KitModel>;

    // If editing, find and set the selected customer
    if (isEditing && widget.quote!.customerId.isNotEmpty) {
      _selectedCustomer = _availableCustomers.firstWhere((c) => c.id == widget.quote!.customerId, orElse: () => _availableCustomers.first);
    }

    setState(() => _isLoading = false);
  }

  void _calculateTotal() {
    _total = _items.fold(0.0, (sum, item) => sum + item.totalPrice);
  }

  Future<void> _saveForm() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedCustomer == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Debe seleccionar un cliente.')));
        return;
      }
      if (_items.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('La cotización debe tener al menos un ítem.')));
        return;
      }

      final firestoreService = Provider.of<FirestoreService>(context, listen: false);
      final quoteNumber = isEditing ? widget.quote!.quoteNumber : await firestoreService.getNextQuoteNumber();

      final quoteData = QuoteModel(
        id: widget.quote?.id ?? '',
        quoteNumber: quoteNumber,
        customerId: _selectedCustomer!.id,
        customerName: _selectedCustomer!.name,
        items: _items,
        total: _total,
        status: _status,
        createdAt: widget.quote?.createdAt ?? Timestamp.now(),
        validUntil: _validUntil != null ? Timestamp.fromDate(_validUntil!) : null,
      );

      try {
        if (isEditing) {
          await firestoreService.updateQuote(widget.quote!.id, quoteData);
        } else {
          await firestoreService.addQuote(quoteData);
        }
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cotización guardada con éxito')));
        Navigator.of(context).pop();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al guardar la cotización: $e')));
      }
    }
  }

  void _showAddItemDialog() {
    // Usamos un StatefulBuilder para manejar el estado interno del diálogo.
    showDialog(
      context: context,
      builder: (BuildContext context) {
        String itemType = 'product'; // 'product' o 'kit'
        dynamic selectedItem; // Puede ser ProductModel o KitModel
        final quantityController = TextEditingController(text: '1');
        final priceController = TextEditingController();

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Añadir Ítem a la Cotización'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ToggleButtons(
                      isSelected: [itemType == 'product', itemType == 'kit'],
                      onPressed: (index) {
                        setDialogState(() {
                          itemType = index == 0 ? 'product' : 'kit';
                          selectedItem = null;
                          priceController.clear();
                        });
                      },
                      children: const [
                        Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Text('Producto')),
                        Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Text('Kit')),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (itemType == 'product')
                      DropdownButtonFormField<ProductModel>(
                        hint: const Text('Seleccionar producto'),
                        isExpanded: true,
                        items: _availableProducts.map((p) => DropdownMenuItem(value: p, child: Text(p.name))).toList(),
                        onChanged: (product) {
                          setDialogState(() {
                            selectedItem = product;
                            // Usamos el precio de compra como sugerencia, pero es editable.
                            priceController.text = product?.purchasePrice.toStringAsFixed(2) ?? '0.00';
                          });
                        },
                      )
                    else // itemType == 'kit'
                      DropdownButtonFormField<KitModel>(
                        hint: const Text('Seleccionar kit'),
                        isExpanded: true,
                        items: _availableKits.map((k) => DropdownMenuItem(value: k, child: Text(k.name))).toList(),
                        onChanged: (kit) {
                          setDialogState(() {
                            selectedItem = kit;
                            priceController.text = kit?.salePrice.toStringAsFixed(2) ?? '0.00';
                          });
                        },
                      ),
                    TextFormField(controller: quantityController, decoration: const InputDecoration(labelText: 'Cantidad'), keyboardType: TextInputType.number),
                    TextFormField(controller: priceController, decoration: const InputDecoration(labelText: 'Precio Unitario'), keyboardType: const TextInputType.numberWithOptions(decimal: true)),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('CANCELAR')),
                ElevatedButton(
                  onPressed: () => _addItemToQuote(selectedItem, quantityController.text, priceController.text),
                  child: const Text('AÑADIR'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _addItemToQuote(dynamic item, String quantityStr, String priceStr) {
    if (item == null) return;

    final quantity = int.tryParse(quantityStr) ?? 1;
    final price = double.tryParse(priceStr) ?? 0.0;

    final newQuoteItem = QuoteItem(
      itemId: item.id,
      name: item.name,
      quantity: quantity,
      unitPrice: price,
    );

    setState(() {
      _items.add(newQuoteItem);
      _calculateTotal();
    });
    Navigator.of(context).pop();
  }

  // UI methods and build method will go here...
  // This is a complex screen, so we will build it step by step.
  // For now, let's just show a loading indicator or the form.

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Editar Cotización' : 'Nueva Cotización'),
        actions: [IconButton(icon: const Icon(Icons.save), onPressed: _saveForm)],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    // Customer Dropdown
                    DropdownButtonFormField<CustomerModel>(
                      value: _selectedCustomer,
                      hint: const Text('Seleccionar Cliente'),
                      isExpanded: true,
                      items: _availableCustomers.map((customer) {
                        return DropdownMenuItem(value: customer, child: Text(customer.name));
                      }).toList(),
                      onChanged: (value) => setState(() => _selectedCustomer = value),
                      validator: (value) => value == null ? 'Campo requerido' : null,
                    ),
                    const SizedBox(height: 20),
                    // Items section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Ítems', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.add),
                          label: const Text('Añadir'),
                          onPressed: _showAddItemDialog,
                        ),
                      ],
                    ),
                    Expanded(
                      child: _items.isEmpty
                          ? const Center(child: Text('Añada ítems a la cotización.'))
                          : ListView.builder(
                              itemCount: _items.length,
                              itemBuilder: (context, index) {
                                final item = _items[index];
                                return ListTile(
                                  title: Text(item.name),
                                  subtitle: Text('${item.quantity} x \$${item.unitPrice.toStringAsFixed(2)}'),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text('\$${item.totalPrice.toStringAsFixed(2)}'),
                                      IconButton(
                                        icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                                        onPressed: () {
                                          setState(() {
                                            _items.removeAt(index);
                                            _calculateTotal();
                                          });
                                        },
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                    ),
                    // Total section
                    const Divider(),
                    ListTile(
                      title: const Text('Total', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
                      trailing: Text('\$${_total.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
                    ),
                    // Status and Date
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<QuoteStatus>(
                            value: _status,
                            decoration: const InputDecoration(labelText: 'Estado'),
                            items: QuoteStatus.values
                                .where((s) => s != QuoteStatus.unknown)
                                .map((status) => DropdownMenuItem(value: status, child: Text(status.name)))
                                .toList(),
                            onChanged: (value) => setState(() => _status = value!),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: InputDecorator(
                            decoration: const InputDecoration(labelText: 'Válido hasta'),
                            child: GestureDetector(
                              onTap: () async {
                                final date = await showDatePicker(
                                  context: context,
                                  initialDate: _validUntil ?? DateTime.now(),
                                  firstDate: DateTime.now(),
                                  lastDate: DateTime.now().add(const Duration(days: 365)),
                                );
                                if (date != null) {
                                  setState(() => _validUntil = date);
                                }
                              },
                              child: Text(
                                _validUntil != null ? DateFormat.yMd().format(_validUntil!) : 'Seleccionar fecha',
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
    );
  }
}