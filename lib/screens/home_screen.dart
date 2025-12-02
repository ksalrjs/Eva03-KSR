import 'package:Eva03/models/user_model.dart';
import 'package:Eva03/services/auth_service.dart';
import 'package:Eva03/screens/customer_list_screen.dart';
import 'package:Eva03/screens/inventory_screen.dart';
import 'package:Eva03/screens/quotes_list_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});
 
  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);
    // Obtenemos la información del usuario que proveímos desde el AuthWrapper
    final user = Provider.of<UserModel>(context);
 
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('FRACTAR Dashboard'),
            Text(
              'Usuario: ${user.displayName}',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar Sesión',
            onPressed: () async {
              await authService.signOut();
            },
          ),
        ],
      ),
      body: GridView.count(
        crossAxisCount: 2, // 2 tarjetas por fila
        padding: const EdgeInsets.all(16.0),
        crossAxisSpacing: 16.0,
        mainAxisSpacing: 16.0,
        children: <Widget>[
          _buildDashboardCard(
            context,
            title: 'Gestión de Inventario',
            icon: Icons.inventory_2_outlined,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const InventoryScreen()),
              );
            },
          ),
          _buildDashboardCard(
            context,
            title: 'Gestión de Clientes',
            icon: Icons.people_alt_outlined,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const CustomerListScreen()),
              );
            },
          ),
          _buildDashboardCard(
            context,
            title: 'Cotizaciones',
            icon: Icons.request_quote_outlined,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const QuotesListScreen(),
                ),
              );
            },
          ),
          _buildDashboardCard(
            context,
            title: 'Catálogo',
            icon: Icons.auto_stories_outlined,
            onTap: () {
              // TODO: Navegar a la pantalla de catálogo
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Navegando a Catálogo...')),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardCard(BuildContext context,
      {required String title, required IconData icon, required VoidCallback onTap}) {
    return Card(
      elevation: 4.0,
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(icon, size: 50.0, color: Theme.of(context).primaryColor),
            const SizedBox(height: 10.0),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
