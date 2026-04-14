import 'package:aplicacion_ventas/funciones_principales/categorias.dart';
import 'package:aplicacion_ventas/funciones_principales/producto.dart';
import 'package:aplicacion_ventas/funciones_principales/venta.dart';
import 'package:aplicacion_ventas/funciones_principales/inicio.dart';
import 'package:aplicacion_ventas/funciones_secundarias/ajustes_app.dart';
import 'package:aplicacion_ventas/modo_oscuro.dart';
import 'package:aplicacion_ventas/principal/login.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://rmriozsghjlupscqexuv.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJtcmlvenNnaGpsdXBzY3FleHV2Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzU4MzQ2MDUsImV4cCI6MjA5MTQxMDYwNX0.21AKYm0gyKCc65L8da9t6NTk5v0w5N0hL8lpo2cdAJ0',
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: temaNotifier,
      builder: (_, ThemeMode mode, __) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          themeMode: mode,
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color.fromARGB(255, 28, 153, 255),
              brightness: Brightness.light,
            ),
            appBarTheme: const AppBarTheme(
              backgroundColor: Color.fromARGB(255, 28, 153, 255),
              foregroundColor: Colors.white,
              surfaceTintColor: Colors.transparent,
              elevation: 0,
              scrolledUnderElevation: 0,
              centerTitle: true,
            ),
            inputDecorationTheme: InputDecorationTheme(
              isDense: false,
              filled: true,
              fillColor: Colors.grey[50],
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 18,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.grey),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: Color.fromARGB(255, 28, 153, 255),
                  width: 2,
                ),
              ),
            ),
            floatingActionButtonTheme: const FloatingActionButtonThemeData(
              backgroundColor: Color.fromARGB(255, 28, 153, 255),
              foregroundColor: Colors.white,
            ),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 28, 153, 255),
                foregroundColor: Colors.white,
              ),
            ),
            scaffoldBackgroundColor: Colors.grey[100],
            useMaterial3: true,
          ),
          darkTheme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color.fromARGB(255, 28, 153, 255),
              brightness: Brightness.dark,
            ),
            appBarTheme: const AppBarTheme(
              backgroundColor: Color.fromARGB(255, 28, 153, 255),
              foregroundColor: Colors.white,
              surfaceTintColor: Colors.transparent,
              elevation: 0,
              scrolledUnderElevation: 0,
              centerTitle: true,
            ),
            inputDecorationTheme: InputDecorationTheme(
              isDense: false,
              filled: true,
              fillColor: Colors.grey[900],
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 18,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.white24),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: Color.fromARGB(255, 28, 153, 255),
                  width: 2,
                ),
              ),
            ),
            floatingActionButtonTheme: const FloatingActionButtonThemeData(
              backgroundColor: Color.fromARGB(255, 28, 153, 255),
              foregroundColor: Colors.white,
            ),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 28, 153, 255),
                foregroundColor: Colors.white,
              ),
            ),
            scaffoldBackgroundColor: const Color.fromARGB(255, 30, 30, 30),
            useMaterial3: true,
          ),
          home: StreamBuilder<AuthState>(
            stream: Supabase.instance.client.auth.onAuthStateChange,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }
              final session = snapshot.data?.session;
              if (session != null) {
                return const MyHomePage(title: 'Control de ventas');
              }
              return const PantallaLogin();
            },
          ),
        );
      },
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: const Color.fromARGB(255, 28, 153, 255),
          foregroundColor: Colors.white,
          title: Text(widget.title),
          actions: [
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              itemBuilder: (BuildContext context) {
                return [
                  const PopupMenuItem<String>(
                    value: 'Ajustes',
                    child: Text('Ajustes del perfil'),
                  ),
                ];
              },
              onSelected: (String value) async {
                if (value == 'Ajustes') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const PantallaAjustesApp(),
                    ),
                  );
                } else if (value == 'Logout') {
                  await Supabase.instance.client.auth.signOut();
                }
              },
            ),
          ],
          bottom: const TabBar(
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            tabs: [
              Tab(icon: Icon(Icons.home), text: 'Inicio'),
              Tab(icon: Icon(Icons.shopping_cart), text: 'Ventas'),
              Tab(icon: Icon(Icons.inventory), text: 'Productos'),
              Tab(icon: Icon(Icons.category), text: 'Categorias'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            const PantallaInicio(),
            PantallaVentas(),
            const PantallaProductos(),
            const PantallaCategorias(),
          ],
        ),
      ),
    );
  }
}
