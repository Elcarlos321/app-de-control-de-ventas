import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PantallaAjustesNegocio extends StatefulWidget {
  const PantallaAjustesNegocio({super.key});

  @override
  State<PantallaAjustesNegocio> createState() => _PantallaAjustesNegocioState();
}

class _PantallaAjustesNegocioState extends State<PantallaAjustesNegocio> {
  final _nombreController = TextEditingController();
  final _sloganController = TextEditingController();
  bool _isLoading = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _cargarDatosNegocio();
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _sloganController.dispose();
    super.dispose();
  }

  Future<void> _cargarDatosNegocio() async {
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
          final intId = userData['id_usuario'];

          final data = await Supabase.instance.client
              .from('negocio')
              .select()
              .eq('id_usuario', intId)
              .maybeSingle();

          if (data != null && mounted) {
            setState(() {
              _nombreController.text = data['nombre_negocio'] ?? '';
              _sloganController.text = data['slogan'] ?? '';
            });
          }
        }
      }
    } catch (e) {
      debugPrint("Error al cargar negocio: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _guardarNegocio() async {
    final nombre = _nombreController.text.trim();
    final slogan = _sloganController.text.trim();

    if (nombre.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("El nombre del negocio es obligatorio")),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null || user.email == null) throw "No hay sesión activa";

      var userData = await Supabase.instance.client
          .from('usuario')
          .select('id_usuario')
          .eq('email', user.email!)
          .maybeSingle();

      if (userData == null) {
        debugPrint("Usuario no encontrado, creando registro automático...");
        await Supabase.instance.client.from('usuario').insert({
          'nombre': user.email!.split('@')[0],
          'email': user.email!,
        });

        userData = await Supabase.instance.client
            .from('usuario')
            .select('id_usuario')
            .eq('email', user.email!)
            .single();
      }

      final intId = userData['id_usuario'];

      await Supabase.instance.client.from('negocio').upsert({
        'id_usuario': intId,
        'nombre_negocio': nombre,
        'slogan': slogan,
      }, onConflict: 'id_usuario');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("¡Configuración guardada!"),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      debugPrint("Error detallado: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error al guardar: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Configuración del negocio"),
        backgroundColor: const Color.fromARGB(255, 28, 153, 255),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10.0,
                  vertical: 20.0,
                ),
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
                        children: [
                          const Icon(
                            Icons.business_center,
                            size: 80,
                            color: Color.fromARGB(255, 28, 153, 255),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            "Datos del negocio",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[800],
                            ),
                          ),
                          const SizedBox(height: 30),
                          TextField(
                            controller: _nombreController,
                            decoration: const InputDecoration(
                              labelText: "Nombre del negocio",
                              prefixIcon: Icon(Icons.business),
                            ),
                          ),
                          const SizedBox(height: 15),
                          TextField(
                            controller: _sloganController,
                            decoration: const InputDecoration(
                              labelText: "Slogan o Lema",
                              prefixIcon: Icon(Icons.auto_awesome),
                            ),
                          ),
                          const SizedBox(height: 30),
                          SizedBox(
                            width: double.infinity,
                            height: 55,
                            child: ElevatedButton(
                              onPressed: _isSaving ? null : _guardarNegocio,
                              style: ElevatedButton.styleFrom(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: _isSaving
                                  ? const CircularProgressIndicator(
                                      color: Colors.white,
                                    )
                                  : const Text(
                                      "Guardar Cambios",
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
