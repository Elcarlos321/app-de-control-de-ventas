import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PantallaNuevaCategoria extends StatefulWidget {
  final Map<String, dynamic>? categoria; // Recibir categoría para editar

  const PantallaNuevaCategoria({super.key, this.categoria});

  @override
  State<PantallaNuevaCategoria> createState() => _PantallaNuevaCategoriaState();
}

class _PantallaNuevaCategoriaState extends State<PantallaNuevaCategoria> {
  final _nombreController = TextEditingController();
  final _descripcionController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();

    if (widget.categoria != null) {
      _nombreController.text = widget.categoria!['nombre_categoria'] ?? '';
      _descripcionController.text = widget.categoria!['descripcion'] ?? '';
    }
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _descripcionController.dispose();
    super.dispose();
  }

  Future<void> _guardarCategoria() async {
    final nombre = _nombreController.text.trim();
    final descripcion = _descripcionController.text.trim();

    if (nombre.isEmpty || descripcion.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Debes llenar todos los campos")),
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
        'nombre_categoria': nombre,
        'descripcion': descripcion,
        'id_usuario': internalUserId,
        'id_negocio': idNegocio,
      };

      if (widget.categoria != null) {
        datos['id_categoria'] = widget.categoria!['id_categoria'];
      }

      await Supabase.instance.client.from('categoria').upsert(datos);

      if (mounted) {
        final mensaje = widget.categoria == null
            ? "Categoría agregada con éxito"
            : "Categoría actualizada con éxito";
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(mensaje), backgroundColor: Colors.green),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      debugPrint("Error al guardar categoría: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
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
        title: const Text("Nueva Categoría"),
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
                        labelText: "Nombre de la categoría",
                        prefixIcon: Icon(Icons.category),
                      ),
                    ),
                    const SizedBox(height: 15),
                    TextField(
                      controller: _descripcionController,
                      decoration: const InputDecoration(
                        labelText: "Descripción",
                        prefixIcon: Icon(Icons.description),
                      ),
                    ),
                    const SizedBox(height: 25),
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _guardarCategoria,
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
                                "Guardar categoría",
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
