import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:aplicacion_ventas/funciones_secundarias/agregar_categoria.dart';
import 'package:flutter/material.dart';

class PantallaCategorias extends StatefulWidget {
  const PantallaCategorias({super.key});

  @override
  State<PantallaCategorias> createState() => _PantallaCategoriasState();
}

class _PantallaCategoriasState extends State<PantallaCategorias> {
  final _searchController = TextEditingController();
  List<dynamic> _categorias = [];
  List<dynamic> _categoriasFiltradas = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _cargarCategorias();
  }

  Future<void> _cargarCategorias() async {
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
              .from('categoria')
              .select()
              .eq('id_usuario', internalUserId)
              .order('nombre_categoria', ascending: true);

          setState(() {
            _categorias = data;
            _categoriasFiltradas = data;
          });
        }
      }
    } catch (e) {
      debugPrint("Error al cargar categorías: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error al cargar categorías: $e")),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _filtrarCategorias(String query) {
    setState(() {
      _categoriasFiltradas = _categorias
          .where(
            (c) => c['nombre_categoria'].toString().toLowerCase().contains(
              query.toLowerCase(),
            ),
          )
          .toList();
    });
  }

  Future<void> _eliminarCategoria(int idCategoria) async {
    try {
      await Supabase.instance.client
          .from('categoria')
          .delete()
          .eq('id_categoria', idCategoria);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Categoría eliminada con éxito"),
            backgroundColor: Colors.green,
          ),
        );
        _cargarCategorias();
      }
    } catch (e) {
      debugPrint("Error al eliminar categoría: $e");
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

  void _confirmarEliminacion(Map<String, dynamic> cat) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("¿Eliminar categoría?"),
        content: Text(
          "Esta acción eliminará la categoría '${cat['nombre_categoria']}'. Esta acción no se puede deshacer.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancelar"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _eliminarCategoria(cat['id_categoria']);
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
              onChanged: _filtrarCategorias,
              decoration: InputDecoration(
                hintText: "Buscar categoría por nombre...",
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
                : _categoriasFiltradas.isEmpty
                ? const Center(child: Text("No hay categorías registradas aún"))
                : ListView.builder(
                    itemCount: _categoriasFiltradas.length,
                    itemBuilder: (context, index) {
                      final cat = _categoriasFiltradas[index];
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
                            child: const Icon(Icons.category),
                          ),
                          title: Text(
                            cat['nombre_categoria'] ?? 'Sin nombre',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            cat['descripcion'] ?? 'Sin descripción',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
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
                                          PantallaNuevaCategoria(
                                            categoria: cat,
                                          ),
                                    ),
                                  );
                                  if (res == true) _cargarCategorias();
                                },
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.red,
                                ),
                                onPressed: () => _confirmarEliminacion(cat),
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
              builder: (context) => const PantallaNuevaCategoria(),
            ),
          );
          if (res == true) {
            _cargarCategorias();
          }
        },
        label: const Text("Agregar categoria"),
        icon: const Icon(Icons.category),
      ),
    );
  }
}
