import 'package:flutter/foundation.dart';
import '../models/product_model.dart';

class CartProvider with ChangeNotifier {
  final List<Product> _items = [];
  
  List<Product> get items => List.unmodifiable(_items);
  
  double get total => _items.fold(0, (sum, item) => sum + item.total);
  
  int get itemCount => _items.length;
  
  // Añade un producto al carrito
  void addProduct(Product product) {
    final existingIndex = _items.indexWhere((item) => item.id == product.id);
    
    if (existingIndex >= 0) {
      _items[existingIndex] = _items[existingIndex].copyWith(quantity: _items[existingIndex].quantity + 1);
    } else {
      _items.add(product);
    }
    
    notifyListeners();
  }
  
  // Elimina un producto del carrito
  void removeProduct(String id) {
    _items.removeWhere((item) => item.id == id);
    notifyListeners();
  }
  
  // Actualiza la cantidad de un producto
  void updateProductQuantity(String id, int quantity) {
    final index = _items.indexWhere((item) => item.id == id);
    if (index >= 0) {
      final updatedProduct = _items[index].copyWith(quantity: quantity);
      if (updatedProduct.quantity <= 0) {
        _items.removeAt(index);
      } else {
        _items[index] = updatedProduct;
      }
      notifyListeners();
    }
  }
  
  // Limpia todo el carrito
  void clearCart() {
    _items.clear();
    notifyListeners();
  }
}
