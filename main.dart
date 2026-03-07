import 'package:flutter/material.dart';

void main() {
  runApp(const B737ToolsApp());
}

class B737ToolsApp extends StatelessWidget {
  const B737ToolsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'B737 Tools',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0033A0)), // Azul Boeing
        useMaterial3: true,
      ),
      home: const DisclaimerScreen(),
    );
  }
}

// ==========================================
// 1. PANTALLA DE AVISO LEGAL (DISCLAIMER)
// ==========================================
class DisclaimerScreen extends StatelessWidget {
  const DisclaimerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.warning_amber_rounded, size: 80, color: Colors.orange),
              const SizedBox(height: 20),
              const Text(
                'Aviso Importante',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              const Text(
                'Esta aplicación es una guía de referencia rápida no oficial diseñada por y para TMAs.\n\n'
                'Bajo ninguna circunstancia sustituye a los manuales aprobados (AMM, FIM, IPC, WDM, etc.). '
                'Consulte siempre la documentación oficial y actualizada de su aerolínea.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 40),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0033A0),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                ),
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const MainNavigationScreen()),
                  );
                },
                child: const Text('ACEPTO Y COMPRENDO'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ==========================================
// 2. NAVEGACIÓN PRINCIPAL (MENÚ INFERIOR)
// ==========================================
class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _selectedIndex = 0;

  static const List<Widget> _screens = <Widget>[
    CbSearchScreen(),
    FimSearchScreen(),
    CommonPnScreen(),
    RevisionsScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed, // Muestra todos los iconos fijos
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.electrical_services), label: 'Breakers'),
          BottomNavigationBarItem(icon: Icon(Icons.menu_book), label: 'FIM / Fallos'),
          BottomNavigationBarItem(icon: Icon(Icons.build_circle), label: 'Common PN'),
          BottomNavigationBarItem(icon: Icon(Icons.checklist), label: 'Revisiones'),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: const Color(0xFF0033A0),
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
      ),
    );
  }
}

// ==========================================
// 3. PANTALLA: CIRCUIT BREAKERS (CB)
// ==========================================
class CbSearchScreen extends StatefulWidget {
  const CbSearchScreen({super.key});
  @override
  State<CbSearchScreen> createState() => _CbSearchScreenState();
}

class _CbSearchScreenState extends State<CbSearchScreen> {
  final List<Map<String, String>> cbDatabase = [
    {"system": "APU ECU", "panel": "P6-3", "grid": "C14", "amm": "AMM 28-22-00"},
    {"system": "Standby Power", "panel": "P6-1", "grid": "D10", "amm": "AMM 24-20-00"},
    {"system": "FMC Left", "panel": "P18-2", "grid": "E5", "amm": "AMM 34-61-00"},
    {"system": "Fuel Pump L FWD", "panel": "P6-4", "grid": "B2", "amm": "AMM 28-21-00"},
  ];

  List<Map<String, String>> _foundItems = [];

  @override
  void initState() {
    super.initState();
    _foundItems = cbDatabase;
  }

  void _runFilter(String keyword) {
    setState(() {
      if (keyword.isEmpty) {
        _foundItems = cbDatabase;
      } else {
        _foundItems = cbDatabase
            // FIX 4: use ?? "" instead of ! to avoid crash on missing keys
            .where((item) => (item["system"] ?? "").toLowerCase().contains(keyword.toLowerCase()))
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Circuit Breakers', style: TextStyle(color: Colors.white)), backgroundColor: const Color(0xFF0033A0)),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              onChanged: _runFilter,
              decoration: const InputDecoration(labelText: 'Buscar sistema (ej. APU)', suffixIcon: Icon(Icons.search), border: OutlineInputBorder()),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: ListView.builder(
                itemCount: _foundItems.length,
                itemBuilder: (context, index) => Card(
                  child: ListTile(
                    leading: const Icon(Icons.bolt, color: Colors.blueGrey),
                    title: Text(_foundItems[index]['system']!, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('Panel: ${_foundItems[index]['panel']} | Grid: ${_foundItems[index]['grid']}'),
                    trailing: Text(_foundItems[index]['amm']!),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// 4. PANTALLA: FIM / CÓDIGOS DE FALLO
// ==========================================
class FimSearchScreen extends StatefulWidget {
  const FimSearchScreen({super.key});
  @override
  State<FimSearchScreen> createState() => _FimSearchScreenState();
}

class _FimSearchScreenState extends State<FimSearchScreen> {
  final List<Map<String, String>> fimDatabase = [
    {"fault": "21-21134", "desc": "Pack 1 Temp Control Fault", "fix": "Revisar sensor de ram air door"},
    {"fault": "PSEU LIGHT", "desc": "Proximity Switch Electronic Unit", "fix": "Hacer BITE test en panel trasero"},
    {"fault": "APU FAULT", "desc": "APU Auto Shutdown", "fix": "Revisar nivel de aceite antes de reset"},
  ];

  List<Map<String, String>> _foundItems = [];

  @override
  void initState() {
    super.initState();
    _foundItems = fimDatabase;
  }

  void _runFilter(String keyword) {
    setState(() {
      if (keyword.isEmpty) {
        _foundItems = fimDatabase;
      } else {
        _foundItems = fimDatabase
            // FIX 4: use ?? "" instead of ! to avoid crash on missing keys
            .where((item) => (item["fault"] ?? "").toLowerCase().contains(keyword.toLowerCase()) ||
                             (item["desc"] ?? "").toLowerCase().contains(keyword.toLowerCase()))
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Buscador FIM', style: TextStyle(color: Colors.white)), backgroundColor: const Color(0xFF0033A0)),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              onChanged: _runFilter,
              decoration: const InputDecoration(labelText: 'Buscar fallo o código (ej. PSEU)', suffixIcon: Icon(Icons.search), border: OutlineInputBorder()),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: ListView.builder(
                itemCount: _foundItems.length,
                itemBuilder: (context, index) => Card(
                  child: ListTile(
                    leading: const Icon(Icons.warning, color: Colors.orange),
                    title: Text(_foundItems[index]['fault']!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                    subtitle: Text('${_foundItems[index]['desc']!}\nAcción TMA: ${_foundItems[index]['fix']!}'),
                    isThreeLine: true,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// 5. PANTALLA: COMMON PN (CON FOTOS)
// ==========================================
class CommonPnScreen extends StatefulWidget {
  const CommonPnScreen({super.key});
  @override
  State<CommonPnScreen> createState() => _CommonPnScreenState();
}

class _CommonPnScreenState extends State<CommonPnScreen> {
  final List<Map<String, String>> pnDatabase = [
    {"desc": "Engine Oil O-Ring", "pn": "J221P014", "ata": "79", "qty": "2 (1 per engine)", "image": "assets/oring.jpg"},
    {"desc": "Nav Light Bulb (Wingtip)", "pn": "6832", "ata": "33", "qty": "2", "image": "assets/bulb.jpg"},
    {"desc": "MLG Tire", "pn": "200-247-XX", "ata": "32", "qty": "4", "image": "assets/tire.jpg"},
  ];

  List<Map<String, String>> _foundItems = [];

  @override
  void initState() {
    super.initState();
    _foundItems = pnDatabase;
  }

  void _runFilter(String keyword) {
    setState(() {
      if (keyword.isEmpty) {
        _foundItems = pnDatabase;
      } else {
        _foundItems = pnDatabase
            // FIX 4: use ?? "" instead of ! to avoid crash on missing keys
            .where((item) => (item["desc"] ?? "").toLowerCase().contains(keyword.toLowerCase()) ||
                             (item["pn"] ?? "").toLowerCase().contains(keyword.toLowerCase()) ||
                             (item["ata"] ?? "").contains(keyword))
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Common PNs', style: TextStyle(color: Colors.white)), backgroundColor: const Color(0xFF0033A0)),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              onChanged: _runFilter,
              decoration: const InputDecoration(labelText: 'Buscar por Nombre, PN o ATA', suffixIcon: Icon(Icons.search), border: OutlineInputBorder()),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: ListView.builder(
                itemCount: _foundItems.length,
                itemBuilder: (context, index) => Card(
                  child: ExpansionTile(
                    leading: const Icon(Icons.settings),
                    title: Text(_foundItems[index]['desc']!, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('PN: ${_foundItems[index]['pn']!} | ATA: ${_foundItems[index]['ata']!}'),
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            // AQUÍ IRÁ LA FOTO REAL.
                            // Cuando tengas las fotos en tu carpeta assets, cambia este Container por:
                            // Image.asset(_foundItems[index]['image']!, height: 200),
                            Container(
                              height: 150,
                              width: double.infinity,
                              color: Colors.grey[300],
                              child: const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.image, size: 50, color: Colors.grey),
                                  Text("Espacio para fotografía", style: TextStyle(color: Colors.black54))
                                ],
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text('Cantidad en avión: ${_foundItems[index]['qty']!}', style: const TextStyle(fontSize: 16)),
                          ],
                        ),
                      )
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// 6. PANTALLA: REVISIONES (CHECKLISTS)
// ==========================================
class RevisionsScreen extends StatefulWidget {
  const RevisionsScreen({super.key});
  @override
  State<RevisionsScreen> createState() => _RevisionsScreenState();
}

class _RevisionsScreenState extends State<RevisionsScreen> {
  // Lista de tareas (Transit)
  List<Map<String, dynamic>> transitTasks = [
    {"task": "Walkaround visual (Daños externos, fugas)", "isDone": false},
    {"task": "Revisar desgaste de frenos (Brake wear pins)", "isDone": false},
    {"task": "Comprobar nivel de aceite del motor (MCDU / FWD Panel)", "isDone": false},
  ];

  // Controlador de texto para añadir nuevas tareas
  final TextEditingController _taskController = TextEditingController();

  // FIX 1: Dispose the controller to prevent memory leak
  @override
  void dispose() {
    _taskController.dispose();
    super.dispose();
  }

  // Función para desmarcar todas las tareas (Reset para el siguiente avión)
  void _resetTasks() {
    setState(() {
      for (var item in transitTasks) {
        item["isDone"] = false;
      }
    });
    // FIX 3: Guard with mounted before using context after setState
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Checklist reseteada para el siguiente avión.")),
      );
    }
  }

  // Cuadro de diálogo para añadir tarea
  void _showAddTaskDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Añadir nueva tarea'),
        content: TextField(
          controller: _taskController,
          decoration: const InputDecoration(hintText: "Ej. Revisar luces NAV"),
        ),
        actions: [
          // FIX 2: Clear the controller on cancel so old text doesn't persist
          TextButton(
            onPressed: () {
              _taskController.clear();
              Navigator.pop(context);
            },
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              if (_taskController.text.isNotEmpty) {
                setState(() {
                  transitTasks.add({"task": _taskController.text, "isDone": false});
                });
                _taskController.clear();
                Navigator.pop(context);
              }
            },
            child: const Text('Añadir'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2, // Dos pestañas: Transit y Daily
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Revisiones B737', style: TextStyle(color: Colors.white)),
          backgroundColor: const Color(0xFF0033A0),
          actions: [
            IconButton(
              icon: const Icon(Icons.cleaning_services, color: Colors.white),
              tooltip: 'Resetear Checklist',
              onPressed: _resetTasks,
            ),
          ],
          bottom: const TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white60,
            indicatorColor: Colors.white,
            tabs: [
              Tab(text: "TRANSIT CHECK"),
              Tab(text: "DAILY CHECK"),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // PESTAÑA 1: TRANSIT
            ListView.builder(
              itemCount: transitTasks.length,
              itemBuilder: (context, index) {
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  child: CheckboxListTile(
                    title: Text(
                      transitTasks[index]["task"],
                      style: TextStyle(
                        decoration: transitTasks[index]["isDone"] ? TextDecoration.lineThrough : null,
                        color: transitTasks[index]["isDone"] ? Colors.grey : Colors.black,
                        fontSize: 16,
                      ),
                    ),
                    value: transitTasks[index]["isDone"],
                    activeColor: Colors.green,
                    onChanged: (bool? newValue) {
                      setState(() {
                        transitTasks[index]["isDone"] = newValue!;
                      });
                    },
                  ),
                );
              },
            ),
            // PESTAÑA 2: DAILY (En construcción para este ejemplo)
            const Center(child: Text("Lista de Daily Check (Añade tus tareas aquí)")),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          backgroundColor: const Color(0xFF0033A0),
          foregroundColor: Colors.white,
          onPressed: _showAddTaskDialog,
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}
