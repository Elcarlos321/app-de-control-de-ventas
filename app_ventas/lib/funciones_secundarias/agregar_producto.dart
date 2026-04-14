import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PantallaNuevoProducto extends StatefulWidget {
  final Map<String, dynamic>? producto; // Recibir producto para editar

  const PantallaNuevoProducto({super.key, this.producto});

  @override
  State<PantallaNuevoProducto> createState() => _PantallaNuevoProductoState();
}

class _PantallaNuevoProductoState extends State<PantallaNuevoProducto> {
  final _nombreController = TextEditingController();
  final _cantidadController = TextEditingController();
  final _precioController = TextEditingController();

  int? _idCategoriaSeleccionada;
  List<Map<String, dynamic>> _categoriasDisponibles = [];
  bool _isLoading = false;
  bool _loadingCategorias = true;

  @override
  void initState() {
    super.initState();
    _inicializarDatos();
  }

  Future<void> _inicializarDatos() async {
    await _cargarCategorias();

    if (widget.producto != null) {
      _nombreController.text = widget.producto!['nombre_producto'] ?? '';
      _cantidadController.text =
          widget.producto!['cantidad_producto']?.toString() ?? '';
      _precioController.text =
          widget.producto!['precio_producto']?.toString() ?? '';

      final idCat = widget.producto!['id_categoria'];
      if (idCat != null) {
        setState(() {
          _idCategoriaSeleccionada = idCat;
        });
      }
    }
  }

  Future<void> _cargarCategorias() async {
    setState(() => _loadingCategorias = true);
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

        final data = await Supabase.instance.client
            .from('categoria')
            .select('id_categoria, nombre_categoria')
            .eq('id_usuario', internalUserId)
            .order('nombre_categoria', ascending: true);

        setState(() {
          _categoriasDisponibles = List<Map<String, dynamic>>.from(data);
        });
      }
    } catch (e) {
      debugPrint("Error al cargar categorías: $e");
    } finally {
      if (mounted) setState(() => _loadingCategorias = false);
    }
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _cantidadController.dispose();
    _precioController.dispose();
    super.dispose();
  }

  Future<void> _guardarProducto() async {
    final nombre = _nombreController.text.trim();
    final cantidad = int.tryParse(_cantidadController.text.trim()) ?? 0;
    final precio = double.tryParse(_precioController.text.trim()) ?? 0.0;

    if (nombre.isEmpty ||
        _idCategoriaSeleccionada == null ||
        _cantidadController.text.isEmpty ||
        _precioController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Por favor, llena todos los campos")),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null || user.email == null) throw "No hay sesión activa";

      final userData = await Supabase.instance.client
          .from('usuario')
          .select('id_usuario')
          .eq('email', user.email!)
          .maybeSingle();

      if (userData == null)
        throw "Primero debes estar registrado en la tabla de usuarios.";
      final internalUserId = userData['id_usuario'];

      final negocioData = await Supabase.instance.client
          .from('negocio')
          .select('id_negocio')
          .eq('id_usuario', internalUserId)
          .maybeSingle();

      if (negocioData == null) {
        throw "Primero debes configurar tu negocio en Ajustes.";
      }
      final idNegocio = negocioData['id_negocio'];

      final Map<String, dynamic> datos = {
        'nombre_producto': nombre,
        'id_categoria': _idCategoriaSeleccionada,
        'cantidad_producto': cantidad,
        'precio_producto': precio,
        'id_usuario': internalUserId,
        'id_negocio': idNegocio,
      };

      if (widget.producto != null) {
        datos['id_producto'] = widget.producto!['id_producto'];
      }

      await Supabase.instance.client.from('producto').upsert(datos);

      if (mounted) {
        final mensaje = widget.producto == null
            ? "Producto guardado exitosamente"
            : "Producto actualizado exitosamente";
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(mensaje), backgroundColor: Colors.green),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      debugPrint("Error al guardar producto: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error al guardar: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Nuevo Producto"),
        backgroundColor: const Color.fromARGB(255, 28, 153, 255),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 16.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 550),
            child: Card(
              elevation: 6,
              shadowColor: Colors.black38,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    TextField(
                      controller: _nombreController,
                      decoration: const InputDecoration(
                        labelText: "Nombre del producto",
                        prefixIcon: Icon(Icons.inventory),
                      ),
                    ),
                    const SizedBox(height: 15),
                    _loadingCategorias
                        ? const LinearProgressIndicator()
                        : DropdownButtonFormField<int>(
                            value: _idCategoriaSeleccionada,
                            decoration: const InputDecoration(
                              labelText: "Categoría",
                              prefixIcon: Icon(Icons.category),
                            ),
                            items: _categoriasDisponibles.map((cat) {
                              return DropdownMenuItem<int>(
                                value: cat['id_categoria'] as int,
                                child: Text(cat['nombre_categoria'].toString()),
                              );
                            }).toList(),
                            onChanged: (val) {
                              setState(() => _idCategoriaSeleccionada = val);
                            },
                            hint: const Text("Selecciona una categoría"),
                            validator: (val) => val == null
                                ? "Debes elegir una categoría"
                                : null,
                          ),
                    if (!_loadingCategorias && _categoriasDisponibles.isEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          "Debes crear categorías primero en la pestaña de Categorías.",
                          style: TextStyle(
                            color: Colors.red[700],
                            fontSize: 12,
                          ),
                        ),
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
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: "Precio",
                        prefixIcon: Icon(Icons.attach_money),
                      ),
                    ),
                    const SizedBox(height: 25),
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _guardarProducto,
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
                        child: _isLoading
                            ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                            : const Text(
                                "Guardar producto",
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
