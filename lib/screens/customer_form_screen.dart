import 'package:Eva03/models/customer_model.dart';
import 'package:Eva03/services/firestore_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class CustomerFormScreen extends StatefulWidget {
  final CustomerModel? customer;

  const CustomerFormScreen({super.key, this.customer});

  @override
  State<CustomerFormScreen> createState() => _CustomerFormScreenState();
}

class _CustomerFormScreenState extends State<CustomerFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _contactPersonController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  CustomerSegment? _selectedSegment;

  bool get isEditing => widget.customer != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.customer?.name ?? '');
    _contactPersonController = TextEditingController(text: widget.customer?.contactPerson ?? '');
    _emailController = TextEditingController(text: widget.customer?.email ?? '');
    _phoneController = TextEditingController(text: widget.customer?.phone ?? '');
    _addressController = TextEditingController(text: widget.customer?.address ?? '');
    _selectedSegment = widget.customer?.segment;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _contactPersonController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _saveForm() async {
    if (_formKey.currentState!.validate()) {
      final firestoreService = Provider.of<FirestoreService>(context, listen: false);

      final customerData = CustomerModel(
        id: widget.customer?.id ?? '',
        name: _nameController.text,
        segment: _selectedSegment!,
        contactPerson: _contactPersonController.text,
        email: _emailController.text,
        phone: _phoneController.text,
        address: _addressController.text,
        createdAt: widget.customer?.createdAt ?? Timestamp.now(),
      );

      try {
        if (isEditing) {
          await firestoreService.updateCustomer(widget.customer!.id, customerData);
        } else {
          await firestoreService.addCustomer(customerData);
        }
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cliente guardado con éxito')));
        Navigator.of(context).pop();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al guardar el cliente: $e')));
      }
    }
  }

  Future<void> _deleteCustomer() async {
    if (!isEditing) return;

    final bool? shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Eliminación'),
        content: Text('¿Estás seguro de que deseas eliminar a "${widget.customer!.name}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('CANCELAR')),
          TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('ELIMINAR')),
        ],
      ),
    );

    if (shouldDelete == true) {
      final firestoreService = Provider.of<FirestoreService>(context, listen: false);
      try {
        await firestoreService.deleteCustomer(widget.customer!.id);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cliente eliminado con éxito')));
        Navigator.of(context).pop();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al eliminar el cliente: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Editar Cliente' : 'Nuevo Cliente'),
        actions: [
          if (isEditing) IconButton(icon: const Icon(Icons.delete), onPressed: _deleteCustomer),
          IconButton(icon: const Icon(Icons.save), onPressed: _saveForm),
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
                decoration: const InputDecoration(labelText: 'Nombre (Colegio, Empresa o Familia)'),
                validator: (value) => (value == null || value.isEmpty) ? 'Campo requerido' : null,
              ),
              DropdownButtonFormField<CustomerSegment>(
                value: _selectedSegment,
                decoration: const InputDecoration(labelText: 'Segmento'),
                items: CustomerSegment.values
                    .where((segment) => segment != CustomerSegment.unknown) // No mostrar 'unknown'
                    .map((segment) => DropdownMenuItem(
                          value: segment,
                          child: Text(segment.name[0].toUpperCase() + segment.name.substring(1)),
                        ))
                    .toList(),
                onChanged: (value) => setState(() => _selectedSegment = value),
                validator: (value) => value == null ? 'Seleccione un segmento' : null,
              ),
              TextFormField(
                controller: _contactPersonController,
                decoration: const InputDecoration(labelText: 'Persona de Contacto (Opcional)'),
              ),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Campo requerido';
                  if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) return 'Ingrese un email válido';
                  return null;
                },
              ),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(labelText: 'Teléfono (Opcional)'),
                keyboardType: TextInputType.phone,
              ),
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(labelText: 'Dirección (Opcional)'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}