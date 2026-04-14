import 'package:aplicacion_ventas/funciones_principales/ajustes.dart';
import 'package:aplicacion_ventas/funciones_principales/perfil.dart';
import 'package:flutter/material.dart';

import 'package:aplicacion_ventas/modo_oscuro.dart';

class PantallaAjustesApp extends StatelessWidget {
  const PantallaAjustesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Ajustes"),
        backgroundColor: const Color.fromARGB(255, 28, 153, 255),
        foregroundColor: Colors.white,
      ),
      body: ListView(
        children: [
          const SizedBox(height: 15),
          ListTile(
            title: const Text("Informacion sobre tu negocio"),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const PantallaAjustesNegocio(),
                ),
              );
            },
          ),
          const SizedBox(height: 15),
          ListTile(
            title: const Text("Datos del dueño del negocio"),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const PantallaPerfil()),
              );
            },
          ),
          const SizedBox(height: 15),
          ValueListenableBuilder<ThemeMode>(
            valueListenable: temaNotifier,
            builder: (context, currentMode, _) {
              return SwitchListTile(
                title: const Text("Modo oscuro"),
                secondary: const Icon(Icons.dark_mode),
                value: currentMode == ThemeMode.dark,
                onChanged: (bool isDark) {
                  temaNotifier.value = isDark
                      ? ThemeMode.dark
                      : ThemeMode.light;
                },
              );
            },
          ),
        ],
      ),
    );
  }
}
