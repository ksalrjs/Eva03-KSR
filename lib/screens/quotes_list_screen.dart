import 'package:Eva03/models/quote_model.dart';
import 'package:Eva03/screens/quote_form_screen.dart';
import 'package:Eva03/services/firestore_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class QuotesListScreen extends StatelessWidget {
  const QuotesListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final firestoreService = Provider.of<FirestoreService>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cotizaciones'),
      ),
      body: StreamBuilder<List<QuoteModel>>(
        stream: firestoreService.getQuotes(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No hay cotizaciones registradas.'));
          }

          final quotes = snapshot.data!;
          return ListView.builder(
            itemCount: quotes.length,
            itemBuilder: (context, index) {
              final quote = quotes[index];
              return _buildQuoteListTile(context, quote);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const QuoteFormScreen())),
        child: const Icon(Icons.add),
        tooltip: 'Nueva Cotización',
      ),
    );
  }

  Widget _buildQuoteListTile(BuildContext context, QuoteModel quote) {
    return ListTile(
      title: Text('${quote.quoteNumber} - ${quote.customerName}'),
      subtitle: Text('Total: \$${quote.total.toStringAsFixed(2)}'),
      trailing: Chip(
        label: Text(
          quote.status.name.toUpperCase(),
          style: const TextStyle(color: Colors.white, fontSize: 12),
        ),
        backgroundColor: _getStatusColor(quote.status),
      ),
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => QuoteFormScreen(quote: quote))),
    );
  }

  Color _getStatusColor(QuoteStatus status) {
    switch (status) {
      case QuoteStatus.accepted:
        return Colors.green;
      case QuoteStatus.sent:
        return Colors.blue;
      case QuoteStatus.rejected:
        return Colors.red;
      default: // draft
        return Colors.grey;
    }
  }
}