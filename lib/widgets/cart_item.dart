import 'package:flutter/material.dart';
import '../models/product_model.dart';

class CartItem extends StatelessWidget {
  final Product product;
  final VoidCallback onDelete;
  final Function(int) onQuantityChanged;

  const CartItem({
    super.key,
    required this.product,
    required this.onDelete,
    required this.onQuantityChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        title: Text(
          product.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text('\$${product.price.toStringAsFixed(2)} c/u'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Botón para disminuir cantidad
            IconButton(
              icon: const Icon(Icons.remove_circle_outline),
              onPressed: () {
                if (product.quantity > 1) {
                  onQuantityChanged(product.quantity - 1);
                } else {
                  onDelete();
                }
              },
            ),
            
            // Cantidad
            Text(
              '${product.quantity}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            
            // Botón para aumentar cantidad
            IconButton(
              icon: const Icon(Icons.add_circle_outline),
              onPressed: () {
                onQuantityChanged(product.quantity + 1);
              },
            ),
            
            // Botón para eliminar
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: onDelete,
            ),
            
            // Total del producto
            SizedBox(
              width: 70,
              child: Text(
                '\$${product.total.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
                textAlign: TextAlign.right,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
