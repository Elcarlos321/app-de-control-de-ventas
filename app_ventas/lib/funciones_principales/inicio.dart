import 'package:aplicacion_ventas/funciones_principales/ajustes.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PantallaInicio extends StatefulWidget {
  const PantallaInicio({super.key});

  @override
  State<PantallaInicio> createState() => _PantallaInicioState();
}

class _PantallaInicioState extends State<PantallaInicio> {
  bool _isLoading = true;
  String _nombreNegocio = "Mi Negocio";
  String _slogan = "Cargando...";
  int _totalProductos = 0;
  int _totalCategorias = 0;
  double _totalVentasUsd = 0.0;
  int _cantidadVentas = 0;

  @override
  void initState() {
    super.initState();
    _cargarEstadisticas();
  }

  Future<void> _cargarEstadisticas() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      final userData = await Supabase.instance.client
          .from('usuario')
          .select('id_usuario')
          .eq('email', user.email!)
          .maybeSingle();

      if (userData != null) {
        final internalUserId = userData['id_usuario'];

        final negocioData = await Supabase.instance.client
            .from('negocio')
            .select('id_negocio, nombre_negocio, slogan')
            .eq('id_usuario', internalUserId)
            .maybeSingle();

        if (negocioData != null) {
          _nombreNegocio = negocioData['nombre_negocio'] ?? "Mi Negocio";
          _slogan = negocioData['slogan'] ?? "Gestiona tus ventas";
          final idNegocio = negocioData['id_negocio'];

          final productosData = await Supabase.instance.client
              .from('producto')
              .select('id_producto')
              .eq('id_usuario', internalUserId);
          _totalProductos = (productosData as List).length;

          final categoriasData = await Supabase.instance.client
              .from('categoria')
              .select('id_categoria')
              .eq('id_usuario', internalUserId);
          _totalCategorias = (categoriasData as List).length;

          final ventasData = await Supabase.instance.client
              .from('venta')
              .select('total_venta')
              .eq('id_negocio', idNegocio);

          _cantidadVentas = (ventasData as List).length;
          _totalVentasUsd = (ventasData).fold(
            0.0,
            (sum, item) => sum + (item['total_venta'] ?? 0.0),
          );
        }
      }
    } catch (e) {
      debugPrint("Error al cargar estadísticas: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _cargarEstadisticas,
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(20, 40, 20, 30),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color.fromARGB(255, 28, 153, 255),
                          Color.fromARGB(255, 0, 102, 204),
                        ],
                      ),
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(30),
                        bottomRight: Radius.circular(30),
                      ),
                    ),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.business_center,
                          size: 60,
                          color: Colors.white,
                        ),
                        const SizedBox(height: 15),
                        Text(
                          _nombreNegocio,
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        Text(
                          _slogan,
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.white70,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton.icon(
                          onPressed: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const PantallaAjustesNegocio(),
                              ),
                            );
                            _cargarEstadisticas();
                          },
                          icon: const Icon(Icons.edit, size: 18),
                          label: const Text("Editar Negocio"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: const Color.fromARGB(
                              255,
                              28,
                              153,
                              255,
                            ),
                            elevation: 0,
                          ),
                        ),
                      ],
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Resumen General",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Fila 1: Ventas
                        Row(
                          children: [
                            Expanded(
                              child: _buildStatCard(
                                "Ingresos Totales",
                                "\$${_totalVentasUsd.toStringAsFixed(2)}",
                                Icons.attach_money,
                                Colors.green,
                              ),
                            ),
                            const SizedBox(width: 15),
                            Expanded(
                              child: _buildStatCard(
                                "Total Ventas",
                                _cantidadVentas.toString(),
                                Icons.shopping_cart,
                                Colors.orange,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 15),

                        Row(
                          children: [
                            Expanded(
                              child: _buildStatCard(
                                "Productos",
                                _totalProductos.toString(),
                                Icons.inventory_2,
                                Colors.blue,
                              ),
                            ),
                            const SizedBox(width: 15),
                            Expanded(
                              child: _buildStatCard(
                                "Categorías",
                                _totalCategorias.toString(),
                                Icons.category,
                                Colors.purple,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      elevation: 4,
      shadowColor: color.withOpacity(0.2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 15),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 30),
            ),
            const SizedBox(height: 15),
            Text(
              value,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              title,
              style: const TextStyle(
                fontSize: 13,
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
