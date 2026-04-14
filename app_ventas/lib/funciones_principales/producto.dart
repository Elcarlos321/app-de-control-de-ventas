import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:aplicacion_ventas/funciones_secundarias/agregar_producto.dart';

class PantallaProductos extends StatefulWidget {
  const PantallaProductos({super.key});

  @override
  State<PantallaProductos> createState() => _PantallaProductosState();
}

class _PantallaProductosState extends State<PantallaProductos> {
  final _searchController = TextEditingController();
  List<dynamic> _productos = [];
  List<dynamic> _productosFiltrados = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _cargarProductos();
  }

  Future<void> _cargarProductos() async {
    setState(() => _isLoading = true);
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null && user.email != null) {
        final userData = await Supabase.instance.client
            .from('usuario')
            .select('id_usuario')
            .eq('email', user.email!)
            .maybeSingle();

        if (userData != null) {
          final internalUserId = userData['id_usuario'];

          final data = await Supabase.instance.client
              .from('producto')
              .select('*, categoria(nombre_categoria)')
              .eq('id_usuario', internalUserId)
              .order('nombre_producto', ascending: true);

          setState(() {
            _productos = data;
            _productosFiltrados = data;
          });
        }
      }
    } catch (e) {
      debugPrint("Error al cargar productos: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error al cargar productos: $e")),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _filtrarProductos(String query) {
    setState(() {
      _productosFiltrados = _productos
          .where(
            (p) => p['nombre_producto'].toString().toLowerCase().contains(
              query.toLowerCase(),
            ),
          )
          .toList();
    });
  }

  Future<void> _eliminarProducto(int idProducto) async {
    try {
      await Supabase.instance.client
          .from('producto')
          .delete()
          .eq('id_producto', idProducto);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Producto eliminado exitosamente"),
            backgroundColor: Colors.green,
          ),
        );
        _cargarProductos();
      }
    } catch (e) {
      debugPrint("Error al eliminar producto: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error al eliminar: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _confirmarEliminacion(Map<String, dynamic> p) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("¿Eliminar producto?"),
        content: Text(
          "¿Estás seguro de eliminar '${p['nombre_producto']}'? Esta acción no se puede deshacer.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancelar"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _eliminarProducto(p['id_producto']);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text("Eliminar"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              onChanged: _filtrarProductos,
              decoration: InputDecoration(
                hintText: "Buscar producto por nombre...",
                prefixIcon: const Icon(Icons.search),
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _productosFiltrados.isEmpty
                ? const Center(child: Text("No hay productos registrados aún"))
                : ListView.builder(
                    itemCount: _productosFiltrados.length,
                    itemBuilder: (context, index) {
                      final p = _productosFiltrados[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Theme.of(
                              context,
                            ).colorScheme.primary,
                            foregroundColor: Colors.white,
                            child: const Icon(Icons.inventory_2),
                          ),
                          title: Text(
                            p['nombre_producto'] ?? 'Sin nombre',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Categoría: ${p['categoria']?['nombre_categoria'] ?? 'Sin categoría'}",
                              ),
                              Text(
                                "Stock: ${p['cantidad_producto']} | \$${p['precio_producto']}",
                                style: const TextStyle(
                                  color: Colors.green,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(
                                  Icons.edit,
                                  color: Colors.blue,
                                ),
                                onPressed: () async {
                                  final res = await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          PantallaNuevoProducto(producto: p),
                                    ),
                                  );
                                  if (res == true) _cargarProductos();
                                },
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.red,
                                ),
                                onPressed: () => _confirmarEliminacion(p),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final res = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const PantallaNuevoProducto(),
            ),
          );
          if (res == true) {
            _cargarProductos();
          }
        },
        label: const Text("Nuevo Producto"),
        icon: const Icon(Icons.add_box),
      ),
    );
  }
}
