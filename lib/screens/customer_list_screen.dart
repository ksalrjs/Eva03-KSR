import 'package:Eva03/models/customer_model.dart';
import 'package:Eva03/screens/customer_form_screen.dart';
import 'package:Eva03/services/firestore_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class CustomerListScreen extends StatelessWidget {
  const CustomerListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final firestoreService = Provider.of<FirestoreService>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Clientes'),
      ),
      body: StreamBuilder<List<CustomerModel>>(
        stream: firestoreService.getCustomers(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No hay clientes registrados.'));
          }

          final customers = snapshot.data!;

          return ListView.builder(
            itemCount: customers.length,
            itemBuilder: (context, index) {
              final customer = customers[index];
              return Dismissible(
                key: Key(customer.id),
                direction: DismissDirection.endToStart,
                background: Container(
                  color: Colors.red,
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                confirmDismiss: (direction) async {
                  return await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Confirmar Eliminación'),
                      content: Text('¿Estás seguro de que deseas eliminar a "${customer.name}"?'),
                      actions: [
                        TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('CANCELAR')),
                        TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('ELIMINAR')),
                      ],
                    ),
                  );
                },
                onDismissed: (direction) async {
                  await firestoreService.deleteCustomer(customer.id);
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('"${customer.name}" eliminado')));
                },
                child: ListTile(
                  title: Text(customer.name),
                  subtitle: Text(customer.email),
                  trailing: Icon(Icons.chevron_right),
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => CustomerFormScreen(customer: customer))),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const CustomerFormScreen())),
        child: const Icon(Icons.add),
      ),
    );
  }
}