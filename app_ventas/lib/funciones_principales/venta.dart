import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:aplicacion_ventas/funciones_secundarias/agregar_venta.dart';

class PantallaVentas extends StatefulWidget {
  const PantallaVentas({super.key});

  @override
  State<PantallaVentas> createState() => _PantallaVentasState();
}

class _PantallaVentasState extends State<PantallaVentas> {
  List<dynamic> _ventas = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _cargarVentas();
  }

  Future<void> _cargarVentas() async {
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
          final negocioData = await Supabase.instance.client
              .from('negocio')
              .select('id_negocio')
              .eq('id_usuario', internalUserId)
              .maybeSingle();

          if (negocioData != null) {
            final idNegocio = negocioData['id_negocio'];
            final data = await Supabase.instance.client
                .from('venta')
                .select('*, detalle_venta(*, producto(nombre_producto))')
                .eq('id_negocio', idNegocio)
                .order('id_venta', ascending: false);

            setState(() {
              _ventas = data;
              _isLoading = false;
            });
          } else {
            setState(() => _isLoading = false);
          }
        }
      }
    } catch (e) {
      debugPrint("Error al cargar ventas: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _formatearFecha(String? fechaIso) {
    if (fechaIso == null) return '';
    try {
      final date = DateTime.parse(fechaIso);
      return "${date.day}/${date.month} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}";
    } catch (e) {
      return '';
    }
  }

  Future<void> _eliminarVenta(Map<String, dynamic> venta) async {
    final detalles = venta['detalle_venta'] as List?;
    if (detalles == null || detalles.isEmpty) return;

    try {
      for (var d in detalles) {
        final idProd = d['id_producto'];
        final cantVendida = d['cantidad'] ?? 0;
        final prodRes = await Supabase.instance.client
            .from('producto')
            .select('cantidad_producto')
            .eq('id_producto', idProd)
            .single();
        final stockActual = (prodRes['cantidad_producto'] as num).toInt();
        await Supabase.instance.client
            .from('producto')
            .update({'cantidad_producto': stockActual + cantVendida})
            .eq('id_producto', idProd);
      }
      await Supabase.instance.client
          .from('detalle_venta')
          .delete()
          .eq('id_venta', venta['id_venta']);
      await Supabase.instance.client
          .from('venta')
          .delete()
          .eq('id_venta', venta['id_venta']);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Venta eliminada y stock restaurado"),
          backgroundColor: Colors.orange,
        ),
      );
      _cargarVentas();
    } catch (e) {
      debugPrint("Error eliminando: $e");
    }
  }

  void _confirmarEliminar(Map<String, dynamic> venta) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Eliminar Venta"),
        content: const Text(
          "¿Estás seguro? Los productos vendidos se sumarán de nuevo a tu inventario.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancelar"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _eliminarVenta(venta);
            },
            child: const Text("Eliminar", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _ventas.isEmpty
          ? const Center(child: Text("No hay ventas registradas aún"))
          : RefreshIndicator(
              onRefresh: _cargarVentas,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _ventas.length,
                itemBuilder: (context, index) {
                  final venta = _ventas[index];
                  final detalles = venta['detalle_venta'] as List?;
                  final detalle = (detalles != null && detalles.isNotEmpty)
                      ? detalles[0]
                      : null;
                  final nombreProducto =
                      detalle?['producto']?['nombre_producto'] ?? 'Producto';

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
                        backgroundColor: const Color.fromARGB(
                          255,
                          28,
                          153,
                          255,
                        ),
                        child: const Icon(
                          Icons.shopping_bag,
                          color: Colors.white,
                        ),
                      ),
                      title: Text(
                        nombreProducto,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Cantidad: ${detalle?['cantidad'] ?? 0}"),
                          Text(
                            "Total: \$${venta['total_venta']}",
                            style: const TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            _formatearFecha(venta['fecha_venta']),
                            style: const TextStyle(
                              fontSize: 10,
                              color: Colors.grey,
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
                              size: 22,
                            ),
                            onPressed: () async {
                              final res = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => PantallaNuevaVenta(
                                    venta: venta,
                                    detalle: detalle,
                                  ),
                                ),
                              );
                              if (res == true) _cargarVentas();
                            },
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.delete,
                              color: Colors.red,
                              size: 22,
                            ),
                            onPressed: () => _confirmarEliminar(venta),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final res = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const PantallaNuevaVenta()),
          );
          if (res == true) _cargarVentas();
        },
        label: const Text("Nueva Venta"),
        icon: const Icon(Icons.add),
      ),
    );
  }
}
