import 'package:Eva03/models/kit_model.dart';
import 'package:Eva03/models/product_model.dart';
import 'package:Eva03/screens/kit_form_screen.dart';
import 'package:Eva03/screens/product_form_screen.dart';
import 'package:Eva03/services/firestore_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

class InventoryScreen extends StatelessWidget {
  const InventoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Usamos DefaultTabController para manejar el estado de las pestañas.
    return DefaultTabController(
      length: 2, // Tenemos 2 pestañas: Productos y Kits
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Gestión de Inventario'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Productos', icon: Icon(Icons.widgets_outlined)),
              Tab(text: 'Kits', icon: Icon(Icons.all_inbox_outlined)),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _ProductsList(),
            _KitsList(),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            // Obtenemos el índice de la pestaña actual y navegamos al formulario correcto.
            final tabIndex = DefaultTabController.of(context).index;
            if (tabIndex == 0) {
              // Pestaña de Productos
              Navigator.push(context, MaterialPageRoute(builder: (context) => const ProductFormScreen()));
            } else {
              // Pestaña de Kits
              Navigator.push(context, MaterialPageRoute(builder: (context) => const KitFormScreen()));
            }
          },
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}

/// Widget para mostrar la lista de productos individuales.
class _ProductsList extends StatefulWidget {
  const _ProductsList();

  @override
  State<_ProductsList> createState() => _ProductsListState();
}

class _ProductsListState extends State<_ProductsList> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Nos suscribimos a los cambios del controlador para redibujar el widget.
    _searchController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final firestoreService = Provider.of<FirestoreService>(context);

    return StreamBuilder<List<ProductModel>>(
      stream: firestoreService.getProducts(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No hay productos registrados.'));
        }

        final allProducts = snapshot.data!;
        final searchQuery = _searchController.text.toLowerCase();

        // Aplicamos el filtro de búsqueda
        final filteredProducts = allProducts.where((product) {
          final nameMatches = product.name.toLowerCase().contains(searchQuery);
          final skuMatches = product.sku.toLowerCase().contains(searchQuery);
          return nameMatches || skuMatches;
        }).toList();

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  labelText: 'Buscar por nombre o SKU',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: filteredProducts.length,
                itemBuilder: (context, index) {
                  final product = filteredProducts[index];
                  // Usamos el widget Dismissible para la funcionalidad de deslizar.
                  return Dismissible(
                    key: Key(product.id), // Clave única para cada elemento.
                    direction: DismissDirection.endToStart, // Deslizar de derecha a izquierda.
                    background: Container(
                      color: Colors.red,
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: const Icon(Icons.delete, color: Colors.white),
                    ),
                    // Pedimos confirmación antes de eliminar.
                    confirmDismiss: (direction) async {
                      return await showDialog<bool>(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: const Text('Confirmar Eliminación'),
                            content: Text(
                                '¿Estás seguro de que deseas eliminar "${product.name}"?'),
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
                    },
                    onDismissed: (direction) async {
                      await firestoreService.deleteProduct(product.id);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('"${product.name}" eliminado')),
                      );
                    },
                    child: ListTile(
                      title: Text(product.name),
                      subtitle: Text('SKU: ${product.sku}'),
                      trailing: Text('Stock: ${product.stock}'),
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => ProductFormScreen(product: product)));
                      },
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
}

/// Widget para mostrar la lista de kits.
class _KitsList extends StatelessWidget {
  const _KitsList({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final firestoreService = Provider.of<FirestoreService>(context);

    return StreamBuilder<List<KitModel>>(
      stream: firestoreService.getKits(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No hay kits registrados.'));
        }

        final kits = snapshot.data!;

        return ListView.builder(
          itemCount: kits.length,
          itemBuilder: (context, index) {
            final kit = kits[index];
            return Dismissible(
              key: Key(kit.id),
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
                    content: Text('¿Estás seguro de que deseas eliminar el kit "${kit.name}"?'),
                    actions: [
                      TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('CANCELAR')),
                      TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('ELIMINAR')),
                    ],
                  ),
                );
              },
              onDismissed: (direction) async {
                await firestoreService.deleteKit(kit.id);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('"${kit.name}" eliminado')));
              },
              child: Card(
                margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                child: ListTile(
                  title: Text(kit.name),
                  subtitle: Text('SKU: ${kit.sku}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.build_circle_outlined),
                        tooltip: 'Ensamblar Kit',
                        onPressed: () => _showAssembleDialog(context, kit, firestoreService),
                      ),
                      const Icon(Icons.chevron_right),
                    ],
                  ),
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => KitFormScreen(kit: kit))),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showAssembleDialog(BuildContext context, KitModel kit, FirestoreService firestoreService) {
    final quantityController = TextEditingController(text: '1');

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Ensamblar "${kit.name}"'),
          content: TextFormField(
            controller: quantityController,
            decoration: const InputDecoration(labelText: 'Cantidad a ensamblar'),
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('CANCELAR')),
            ElevatedButton(
              onPressed: () async {
                final quantity = int.tryParse(quantityController.text) ?? 0;
                if (quantity > 0) {
                  try {
                    await firestoreService.assembleKit(kit.id, quantity);
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Stock descontado para $quantity kit(s) de "${kit.name}"')),
                    );
                  } catch (e) {
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                  }
                }
              },
              child: const Text('ENSAMBLAR'),
            ),
          ],
        );
      },
    );
  }
}