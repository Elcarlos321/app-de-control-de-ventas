import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PantallaNuevaVenta extends StatefulWidget {
  final Map<String, dynamic>? venta;
  final Map<String, dynamic>? detalle;

  const PantallaNuevaVenta({super.key, this.venta, this.detalle});

  @override
  State<PantallaNuevaVenta> createState() => _PantallaNuevaVentaState();
}

class _PantallaNuevaVentaState extends State<PantallaNuevaVenta> {
  final _cantidadController = TextEditingController();
  final _precioController = TextEditingController();
  final _totalController = TextEditingController();

  List<dynamic> _productos = [];
  String? _idProductoSeleccionado;
  bool _isLoadingProducts = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _inicializarDatos();
    _cantidadController.addListener(_calcularTotal);
    _precioController.addListener(_calcularTotal);
  }

  Future<void> _inicializarDatos() async {
    await _cargarProductos();
    
    if (widget.venta != null && widget.detalle != null) {
      setState(() {
        _idProductoSeleccionado = widget.detalle!['id_producto']?.toString();
        _cantidadController.text = widget.detalle!['cantidad']?.toString() ?? '';
        _precioController.text = widget.detalle!['precio_unitario']?.toString() ?? '';
        _totalController.text = widget.venta!['total_venta']?.toString() ?? '';
      });
    }
  }

  @override
  void dispose() {
    _cantidadController.dispose();
    _precioController.dispose();
    _totalController.dispose();
    super.dispose();
  }

  Future<void> _cargarProductos() async {
    if (!mounted) return;
    setState(() => _isLoadingProducts = true);
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
              .select()
              .eq('id_usuario', internalUserId)
              .order('nombre_producto', ascending: true);

          if (mounted) {
            setState(() {
              _productos = data;
              _isLoadingProducts = false;
            });
          }
        }
      }
    } catch (e) {
      debugPrint("Error al cargar productos: $e");
      if (mounted) setState(() => _isLoadingProducts = false);
    }
  }

  void _calcularTotal() {
    final cantidadText = _cantidadController.text.replaceAll(',', '.');
    final precioText = _precioController.text.replaceAll(',', '.');
    final cantidad = double.tryParse(cantidadText) ?? 0;
    final precio = double.tryParse(precioText) ?? 0;
    final total = cantidad * precio;
    _totalController.text = total.toStringAsFixed(2);
  }

  Future<void> _guardarVenta() async {
    if (_idProductoSeleccionado == null ||
        _cantidadController.text.isEmpty ||
        _precioController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Por favor rellena todos los campos")),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null || user.email == null) throw "No hay sesión activa";

      final userData = await Supabase.instance.client
          .from('usuario')
          .select('id_usuario')
          .eq('email', user.email!)
          .maybeSingle();

      if (userData == null) throw "No se encontró tu registro de usuario.";
      final internalUserId = userData['id_usuario'];

      final negocioData = await Supabase.instance.client
          .from('negocio')
          .select('id_negocio')
          .eq('id_usuario', internalUserId)
          .maybeSingle();

      if (negocioData == null) throw "Primero configura los datos de tu negocio";

      final idNegocio = negocioData['id_negocio'];
      final totalVenta = double.tryParse(_totalController.text) ?? 0;
      final cantidadNueva = int.tryParse(_cantidadController.text) ?? 0;
      final idProdNuevo = int.parse(_idProductoSeleccionado!);

      // LÓGICA DE EDICIÓN O CREACIÓN
      if (widget.venta != null) {
        // --- MODO EDICIÓN ---
        final idVenta = widget.venta!['id_venta'];
        final idProdAnterior = widget.detalle!['id_producto'];
        final cantidadAnterior = widget.detalle!['cantidad'] ?? 0;

        // 1. Revertir stock anterior si el producto es el mismo
        if (idProdAnterior == idProdNuevo) {
          final prodData = await Supabase.instance.client
              .from('producto')
              .select('cantidad_producto')
              .eq('id_producto', idProdNuevo)
              .single();
          final stockActualReal = (prodData['cantidad_producto'] as num).toInt();
          
          // El stock disponible para la edición es (actual + lo que ya habíamos quitado)
          final stockDisponible = stockActualReal + cantidadAnterior;

          if (stockDisponible < cantidadNueva) {
            throw "Stock insuficiente. Máximo disponible: $stockDisponible";
          }

          // 2. Actualizar registros
          await Supabase.instance.client.from('venta').update({'total_venta': totalVenta}).eq('id_venta', idVenta);
          await Supabase.instance.client.from('detalle_venta').update({
            'cantidad': cantidadNueva,
            'precio_unitario': double.tryParse(_precioController.text.replaceAll(',', '.')) ?? 0,
          }).eq('id_venta', idVenta).eq('id_producto', idProdNuevo);

          // 3. Ajustar stock final
          await Supabase.instance.client.from('producto').update({
            'cantidad_producto': stockDisponible - cantidadNueva
          }).eq('id_producto', idProdNuevo);

        } else {
          // El producto cambió: Revertir stock del viejo y quitar del nuevo
          // Revertir viejo
          await _ajustarStock(idProdAnterior, cantidadAnterior); // Sumar
          
          // Quitar del nuevo
          final prodNuevoData = await Supabase.instance.client
              .from('producto')
              .select('cantidad_producto')
              .eq('id_producto', idProdNuevo)
              .single();
          final stockNuevoActual = (prodNuevoData['cantidad_producto'] as num).toInt();

          if (stockNuevoActual < cantidadNueva) {
             // Si no hay stock del nuevo, revertimos el ajuste del viejo antes de lanzar error
             await _ajustarStock(idProdAnterior, -cantidadAnterior); 
             throw "Stock insuficiente del nuevo producto.";
          }

          await Supabase.instance.client.from('venta').update({'total_venta': totalVenta}).eq('id_venta', idVenta);
          await Supabase.instance.client.from('detalle_venta').update({
            'id_producto': idProdNuevo,
            'cantidad': cantidadNueva,
            'precio_unitario': double.tryParse(_precioController.text.replaceAll(',', '.')) ?? 0,
          }).eq('id_venta', idVenta);

          await Supabase.instance.client.from('producto').update({
            'cantidad_producto': stockNuevoActual - cantidadNueva
          }).eq('id_producto', idProdNuevo);
        }
      } else {
        // --- MODO CREACIÓN (Existing logic) ---
        final prodData = await Supabase.instance.client.from('producto').select('cantidad_producto').eq('id_producto', idProdNuevo).single();
        final stockDisponible = (prodData['cantidad_producto'] as num).toInt();

        if (stockDisponible < cantidadNueva) throw "Stock insuficiente.";

        final ventaResponse = await Supabase.instance.client.from('venta').insert({'id_negocio': idNegocio, 'total_venta': totalVenta}).select('id_venta').single();
        final idVenta = ventaResponse['id_venta'];

        await Supabase.instance.client.from('detalle_venta').insert({
          'id_venta': idVenta,
          'id_producto': idProdNuevo,
          'cantidad': cantidadNueva,
          'precio_unitario': double.tryParse(_precioController.text.replaceAll(',', '.')) ?? 0,
        });

        await Supabase.instance.client.from('producto').update({'cantidad_producto': stockDisponible - cantidadNueva}).eq('id_producto', idProdNuevo);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Venta guardada con éxito"), backgroundColor: Colors.green),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      debugPrint("Error: $e");
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _ajustarStock(int idProd, int cantidad) async {
    final prod = await Supabase.instance.client.from('producto').select('cantidad_producto').eq('id_producto', idProd).single();
    final actual = (prod['cantidad_producto'] as num).toInt();
    await Supabase.instance.client.from('producto').update({'cantidad_producto': actual + cantidad}).eq('id_producto', idProd);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Nueva Venta"),
        backgroundColor: const Color.fromARGB(255, 28, 153, 255),
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 16.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 550),
            child: Card(
              elevation: 6,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _isLoadingProducts
                        ? const CircularProgressIndicator()
                        : DropdownButtonFormField<String>(
                            value: _idProductoSeleccionado,
                            decoration: const InputDecoration(
                              labelText: "Seleccionar Producto",
                              prefixIcon: Icon(Icons.shopping_bag),
                            ),
                            items: _productos.map((p) {
                              final id = p['id_producto'].toString();
                              return DropdownMenuItem<String>(
                                value: id,
                                child: Text(
                                  p['nombre_producto'] ?? 'Sin nombre',
                                ),
                              );
                            }).toList(),
                            onChanged: (val) {
                              setState(() {
                                _idProductoSeleccionado = val;
                                if (val != null) {
                                  final prod = _productos.firstWhere(
                                    (p) => p['id_producto'].toString() == val,
                                  );
                                  _precioController.text =
                                      prod['precio_producto'].toString();
                                }
                              });
                            },
                          ),
                    const SizedBox(height: 15),
                    TextField(
                      controller: _cantidadController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: "Cantidad",
                        prefixIcon: Icon(Icons.add),
                      ),
                    ),
                    const SizedBox(height: 15),
                    TextField(
                      controller: _precioController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: "Precio Unitario",
                        prefixIcon: Icon(Icons.attach_money),
                      ),
                    ),
                    const SizedBox(height: 15),
                    TextField(
                      controller: _totalController,
                      readOnly: true,
                      decoration: InputDecoration(
                        labelText: "Total",
                        prefixIcon: const Icon(Icons.calculate),
                        filled: true,
                        fillColor: Colors.grey[100],
                      ),
                    ),
                    const SizedBox(height: 25),
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _guardarVenta,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color.fromARGB(
                            255,
                            28,
                            153,
                            255,
                          ),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isSaving
                            ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                            : const Text(
                                "Guardar Venta",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
