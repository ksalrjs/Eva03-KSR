import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/customer_model.dart';
import '../models/kit_model.dart';
import '../models/product_model.dart';
import '../models/quote_model.dart';

/// Servicio para gestionar todas las operaciones de la base de datos Firestore.
class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  //--- Métodos para Productos (Requerimientos A1, A2, A5) ---

  /// Obtiene un stream con la lista de todos los productos.
  /// La UI se actualizará automáticamente si hay cambios en la base de datos.
  Stream<List<ProductModel>> getProducts() {
    return _db.collection('products').snapshots().map((snapshot) =>
        snapshot.docs.map((doc) => ProductModel.fromFirestore(doc)).toList());
  }

  /// Agrega un nuevo producto a Firestore.
  Future<void> addProduct(ProductModel product) {
    return _db.collection('products').add(product.toJson());
  }

  /// Actualiza un producto existente en Firestore.
  Future<void> updateProduct(String productId, ProductModel product) {
    return _db.collection('products').doc(productId).update(product.toJson());
  }

  /// Elimina un producto de Firestore.
  Future<void> deleteProduct(String productId) {
    return _db.collection('products').doc(productId).delete();
  }

  //--- Métodos para Kits ---

  /// Obtiene un stream con la lista de todos los kits.
  Stream<List<KitModel>> getKits() {
    return _db.collection('kits').snapshots().map((snapshot) =>
        snapshot.docs.map((doc) => KitModel.fromFirestore(doc)).toList());
  }

  /// Agrega un nuevo kit a Firestore.
  Future<void> addKit(KitModel kit) {
    return _db.collection('kits').add(kit.toJson());
  }

  /// Actualiza un kit existente en Firestore.
  Future<void> updateKit(String kitId, KitModel kit) {
    return _db.collection('kits').doc(kitId).update(kit.toJson());
  }

  /// Elimina un kit de Firestore.
  Future<void> deleteKit(String kitId) {
    return _db.collection('kits').doc(kitId).delete();
  }

  //--- Lógica de Negocio Principal (Requerimiento A3) ---

  /// Descuenta el stock de los componentes de un kit.
  /// Utiliza una transacción para garantizar que la operación sea atómica.
  Future<void> assembleKit(String kitId, int quantityToAssemble) async {
    final kitRef = _db.collection('kits').doc(kitId);

    return _db.runTransaction((transaction) async {
      // 1. Leer el documento del kit dentro de la transacción.
      final kitSnapshot = await transaction.get(kitRef);
      if (!kitSnapshot.exists) {
        throw Exception("El Kit no existe!");
      }

      final kit = KitModel.fromFirestore(kitSnapshot);

      // 2. Por cada componente del kit, descontar el stock del producto correspondiente.
      for (final component in kit.components) {
        final productRef = _db.collection('products').doc(component.productId);
        final productSnapshot = await transaction.get(productRef);

        if (!productSnapshot.exists) {
          throw Exception("El producto ${component.productId} no existe!");
        }

        final currentStock = productSnapshot.data()!['stock'] as int;
        final requiredStock = component.quantity * quantityToAssemble;

        if (currentStock < requiredStock) {
          throw Exception(
              "Stock insuficiente para el producto ${productSnapshot.data()!['name']}.");
        }

        // 3. Actualizar el stock del producto dentro de la transacción.
        transaction
            .update(productRef, {'stock': currentStock - requiredStock});
      }
    });
  }

  //--- Métodos para Clientes (CRM - Requerimientos C1, C2) ---

  /// Obtiene un stream con la lista de todos los clientes.
  Stream<List<CustomerModel>> getCustomers() {
    return _db
        .collection('customers')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => CustomerModel.fromFirestore(doc))
            .toList());
  }

  /// Agrega un nuevo cliente a Firestore.
  Future<void> addCustomer(CustomerModel customer) {
    // Usamos el toJson del modelo para convertir el objeto a un mapa.
    return _db.collection('customers').add(customer.toJson());
  }

  /// Actualiza un cliente existente en Firestore.
  Future<void> updateCustomer(String customerId, CustomerModel customer) {
    return _db.collection('customers').doc(customerId).update(customer.toJson());
  }

  /// Elimina un cliente de Firestore.
  Future<void> deleteCustomer(String customerId) {
    return _db.collection('customers').doc(customerId).delete();
  }

  //--- Métodos para Cotizaciones ---

  /// Obtiene un stream con la lista de todas las cotizaciones.
  Stream<List<QuoteModel>> getQuotes() {
    return _db
        .collection('quotes')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => QuoteModel.fromFirestore(doc))
            .toList());
  }

  /// Agrega una nueva cotización a Firestore.
  Future<void> addQuote(QuoteModel quote) {
    return _db.collection('quotes').add(quote.toJson());
  }

  /// Actualiza una cotización existente en Firestore.
  Future<void> updateQuote(String quoteId, QuoteModel quote) {
    return _db.collection('quotes').doc(quoteId).update(quote.toJson());
  }

  /// Elimina una cotización de Firestore.
  Future<void> deleteQuote(String quoteId) {
    return _db.collection('quotes').doc(quoteId).delete();
  }

  /// Obtiene el siguiente número de cotización de forma segura.
  /// Utiliza una transacción para evitar números duplicados.
  Future<String> getNextQuoteNumber() async {
    final counterRef = _db.collection('counters').doc('quoteCounter');
    final year = DateTime.now().year;

    return _db.runTransaction((transaction) async {
      final counterSnapshot = await transaction.get(counterRef);

      if (!counterSnapshot.exists) {
        // Si el contador no existe, lo creamos.
        transaction.set(counterRef, {'currentNumber': 1, 'year': year});
        return 'COT-$year-001';
      }

      final currentNumber = counterSnapshot.data()!['currentNumber'] as int;
      transaction.update(counterRef, {'currentNumber': currentNumber + 1});
      return 'COT-$year-${(currentNumber + 1).toString().padLeft(3, '0')}';
    });
  }
}