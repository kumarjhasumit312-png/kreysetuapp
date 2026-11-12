import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ---------------- GLOBAL CONSTANTS ----------------
// Chrome: 127.0.0.1 | Android Emulator: 10.0.2.2 | Real Phone: laptop LAN IP
const String kBaseUrl = "http://127.0.0.1:5000/api";

const Color kPrimary = Color(0xFF00897B);
const Color kPrimaryLight = Color(0xFFE0F2F1);
const Color kAccent = Color(0xFFFF7043);

// Is email se login karne pe Admin Dashboard khulega
const String kAdminEmail = 'swapappskill@gmail.com';

// ---------------- THEME + DARK MODE ----------------
final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.light);

Future<void> loadTheme() async {
  final prefs = await SharedPreferences.getInstance();
  themeNotifier.value =
      (prefs.getBool('dark') ?? false) ? ThemeMode.dark : ThemeMode.light;
}

Future<void> setDarkMode(bool dark) async {
  themeNotifier.value = dark ? ThemeMode.dark : ThemeMode.light;
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool('dark', dark);
}

ThemeData buildTheme(Brightness b) {
  final dark = b == Brightness.dark;
  final scheme = ColorScheme.fromSeed(
    seedColor: kPrimary,
    brightness: b,
    primary: dark ? const Color(0xFF4DB6AC) : kPrimary,
    secondary: kAccent,
  );
  final bg = dark ? const Color(0xFF101414) : const Color(0xFFF5F7F8);
  final surface = dark ? const Color(0xFF1A2020) : Colors.white;
  final border = dark ? Colors.white12 : Colors.black12;

  OutlineInputBorder ob(Color c, [double w = 1]) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: c, width: w),
      );

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme.copyWith(surface: surface),
    scaffoldBackgroundColor: bg,
    textTheme: GoogleFonts.poppinsTextTheme(
      ThemeData(brightness: b).textTheme,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: surface,
      foregroundColor: dark ? Colors.white : const Color(0xFF1B2B2B),
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: GoogleFonts.poppins(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: dark ? Colors.white : const Color(0xFF1B2B2B),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: kPrimary,
        foregroundColor: Colors.white,
        disabledBackgroundColor: border,
        elevation: 0,
        textStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        side: BorderSide(color: border),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: surface,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: ob(border),
      enabledBorder: ob(border),
      focusedBorder: ob(kPrimary, 1.8),
    ),
    cardTheme: CardThemeData(
      color: surface,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: border),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: surface,
      indicatorColor: kPrimary.withValues(alpha: 0.15),
      elevation: 8,
      labelTextStyle: WidgetStatePropertyAll(
        GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w500),
      ),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: kAccent,
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    chipTheme: ChipThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      side: BorderSide(color: border),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
  );
}

// ---------------- SMALL HELPERS ----------------
// relative path (/api/upload/files/abc.jpg) ko poora URL banata hai
String imageUrl(String? path) {
  if (path == null || path.isEmpty) return '';
  if (path.startsWith('http')) return path;
  final origin = kBaseUrl.replaceFirst('/api', '');
  return '$origin$path';
}

void snack(BuildContext context, String text) {
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
}

// pull-to-refresh khali ya error list pe bhi chale, isliye ListView
Widget centerMessage(
  String text, {
  Color? color,
  IconData icon = Icons.inbox_outlined,
}) {
  return ListView(
    physics: const AlwaysScrollableScrollPhysics(),
    children: [
      SizedBox(
        height: 360,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: kPrimary.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 48, color: kPrimary),
                ),
                const SizedBox(height: 16),
                Text(
                  text,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: color ?? Colors.grey.shade600,
                    fontSize: 15,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ],
  );
}

// ---------------- SKELETON (SHIMMER) LOADING ----------------
class Skeleton extends StatefulWidget {
  final double? width;
  final double height;
  final double radius;

  const Skeleton({
    super.key,
    this.width,
    required this.height,
    this.radius = 10,
  });

  @override
  State<Skeleton> createState() => _SkeletonState();
}

class _SkeletonState extends State<Skeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final a = dark ? const Color(0xFF263030) : const Color(0xFFE6EBEB);
    final b = dark ? const Color(0xFF334040) : const Color(0xFFF3F6F6);
    return AnimatedBuilder(
      animation: _c,
      builder: (_, __) => Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: Color.lerp(a, b, _c.value),
          borderRadius: BorderRadius.circular(widget.radius),
        ),
      ),
    );
  }
}

// Home ke grid ke liye loading placeholder
Widget productGridSkeleton() {
  return GridView.builder(
    padding: const EdgeInsets.fromLTRB(12, 12, 12, 90),
    gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
      maxCrossAxisExtent: 220,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 0.62,
    ),
    itemCount: 6,
    itemBuilder: (_, __) => const Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: Skeleton(height: double.infinity, radius: 0)),
          Padding(
            padding: EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Skeleton(width: 110, height: 12),
                SizedBox(height: 8),
                Skeleton(width: 60, height: 14),
                SizedBox(height: 10),
                Skeleton(height: 32),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

// Orders / lists ke liye loading placeholder
Widget listSkeleton() {
  return ListView(
    physics: const NeverScrollableScrollPhysics(),
    padding: const EdgeInsets.all(12),
    children: List.generate(
      6,
      (_) => const Padding(
        padding: EdgeInsets.only(bottom: 10),
        child: Skeleton(height: 76, radius: 16),
      ),
    ),
  );
}

Color statusColor(String status) {
  switch (status.toLowerCase()) {
    case 'pending':
      return Colors.orange;
    case 'shipped':
      return Colors.blue;
    case 'delivered':
      return Colors.green;
    case 'cancelled':
      return Colors.red;
    default:
      return Colors.grey;
  }
}

class StatusChip extends StatelessWidget {
  final String status;
  const StatusChip({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final color = statusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }
}

Future<bool> confirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  String yes = 'Yes',
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: const Text('No'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, true),
          child: Text(yes),
        ),
      ],
    ),
  );
  return result == true;
}

class ProductImage extends StatelessWidget {
  final String? path;
  final double? width;
  final double height;
  final IconData fallback;
  final double radius;

  const ProductImage({
    super.key,
    required this.path,
    this.width,
    required this.height,
    this.fallback = Icons.shopping_bag,
    this.radius = 10,
  });

  @override
  Widget build(BuildContext context) {
    final url = imageUrl(path);

    final placeholder = Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: kPrimary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(radius),
      ),
      child: Icon(
        fallback,
        size: height.isFinite ? height * 0.45 : 48,
        color: kPrimary,
      ),
    );

    if (url.isEmpty) return placeholder;

    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: Image.network(
        url,
        width: width,
        height: height,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => placeholder,
        loadingBuilder: (context, child, progress) =>
            progress == null ? child : placeholder,
      ),
    );
  }
}

// ---------------- PHOTO PICK + UPLOAD ----------------
class PickedPhoto {
  final XFile file;
  final Uint8List bytes;
  PickedPhoto(this.file, this.bytes);
}

Future<String> uploadPhoto(PickedPhoto photo) async {
  final request = http.MultipartRequest(
    'POST',
    Uri.parse('$kBaseUrl/upload/image'),
  );

  var name = photo.file.name;
  if (!name.contains('.')) name = '$name.jpg';

  request.files.add(
    http.MultipartFile.fromBytes('image', photo.bytes, filename: name),
  );

  final streamed = await request.send();
  final body = await streamed.stream.bytesToString();

  if (streamed.statusCode == 201 || streamed.statusCode == 200) {
    return jsonDecode(body)['image_url'] as String;
  }

  String error = 'Upload failed (${streamed.statusCode})';
  try {
    error = jsonDecode(body)['error'] ?? error;
  } catch (_) {}
  throw Exception(error);
}

class PhotoPickerBox extends StatelessWidget {
  final PickedPhoto? photo;
  final ValueChanged<PickedPhoto?> onChanged;

  const PhotoPickerBox({
    super.key,
    required this.photo,
    required this.onChanged,
  });

  Future<void> _pick(BuildContext context, ImageSource source) async {
    try {
      final x = await ImagePicker().pickImage(
        source: source,
        maxWidth: 1280,
        imageQuality: 80,
      );
      if (x == null) return;
      final bytes = await x.readAsBytes();
      onChanged(PickedPhoto(x, bytes));
    } catch (e) {
      snack(context, 'Photo select nahi ho payi: $e');
    }
  }

  void _showSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Gallery se chuno'),
              onTap: () {
                Navigator.pop(sheetContext);
                _pick(context, ImageSource.gallery);
              },
            ),
            if (!kIsWeb)
              ListTile(
                leading: const Icon(Icons.photo_camera),
                title: const Text('Camera se kheencho'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _pick(context, ImageSource.camera);
                },
              ),
            if (photo != null)
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Photo hatao'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  onChanged(null);
                },
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showSheet(context),
      child: Container(
        height: 180,
        decoration: BoxDecoration(
          color: kPrimary.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: kPrimary.withValues(alpha: 0.35)),
        ),
        child: photo == null
            ? const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_a_photo, size: 40, color: kPrimary),
                  SizedBox(height: 8),
                  Text('Photo add karo'),
                ],
              )
            : ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.memory(
                  photo!.bytes,
                  fit: BoxFit.cover,
                  width: double.infinity,
                ),
              ),
      ),
    );
  }
}

// ---------------- SESSION HELPERS ----------------
Future<void> saveSession(Map user) async {
  final prefs = await SharedPreferences.getInstance();
  // password kabhi phone ki storage mein save nahi karna
  final safeUser = Map.of(user)
    ..remove('password')
    ..remove('password_hash');
  await prefs.setString('user', jsonEncode(safeUser));
}

Future<void> clearSession() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove('user');
}

bool isAdminUser(Map user) {
  final email = (user['email'] ?? '').toString().trim().toLowerCase();
  return email == kAdminEmail.toLowerCase() || user['role'] == 'admin';
}

Widget screenForUser(Map<String, dynamic> user) {
  if (isAdminUser(user)) {
    return AdminDashboard(user: user);
  } else if (user['role'] == 'seller') {
    return SellerDashboard(user: user);
  }
  return BuyerShell(user: user);
}

Future<void> logout(BuildContext context) async {
  await clearSession();
  if (!context.mounted) return;

  Navigator.pushAndRemoveUntil(
    context,
    MaterialPageRoute(builder: (_) => const LoginScreen()),
    (_) => false,
  );
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await loadTheme();
  runApp(const KreysetuApp());
}

class KreysetuApp extends StatelessWidget {
  const KreysetuApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (_, mode, __) => MaterialApp(
        title: 'Kreysetu',
        debugShowCheckedModeBanner: false,
        themeMode: mode,
        theme: buildTheme(Brightness.light),
        darkTheme: buildTheme(Brightness.dark),
        home: const SplashScreen(),
      ),
    );
  }
}

// ---------------- SPLASH SCREEN ----------------
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    checkSession();
  }

  Future<void> checkSession() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('user');

    await Future.delayed(const Duration(milliseconds: 800));

    if (!mounted) return;

    Widget next = const LoginScreen();

    if (saved != null) {
      try {
        next = screenForUser(jsonDecode(saved) as Map<String, dynamic>);
      } catch (_) {
        next = const LoginScreen();
      }
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => next),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF00695C), Color(0xFF26A69A)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.storefront, size: 84, color: Colors.white),
              SizedBox(height: 12),
              Text(
                'Kreysetu',
                style: TextStyle(
                  fontSize: 38,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 6),
              Text(
                'Bridging Buyers & Sellers',
                style: TextStyle(color: Colors.white70),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------- LOGIN SCREEN ----------------
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool isLoading = false;
  String message = '';

  Future<void> loginUser() async {
    setState(() {
      isLoading = true;
      message = '';
    });

    try {
      final response = await http.post(
        Uri.parse('$kBaseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': emailController.text.trim(),
          'password': passwordController.text,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final user = Map<String, dynamic>.from(data['user']);
        await saveSession(user);

        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => screenForUser(user)),
          );
        }
        return;
      } else {
        setState(() {
          message = data['error'] ?? 'Login failed';
        });
      }
    } catch (_) {
      setState(() {
        message = 'Error: Could not connect to server';
      });
    }

    if (mounted) {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(24, 90, 24, 50),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF00695C), kPrimary, Color(0xFF26A69A)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius:
                    BorderRadius.vertical(bottom: Radius.circular(36)),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.storefront,
                      size: 48,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Kreysetu',
                    style: GoogleFonts.poppins(
                      fontSize: 34,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const Text(
                    'Bridging Buyers & Sellers',
                    style: TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome back 👋',
                      style: GoogleFonts.poppins(
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Login to continue',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                    const SizedBox(height: 24),
                    TextField(
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: passwordController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Password',
                        prefixIcon: Icon(Icons.lock_outline),
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: isLoading ? null : loginUser,
                        child: isLoading
                            ? const SizedBox(
                                height: 22,
                                width: 22,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2.5,
                                ),
                              )
                            : const Text('Login'),
                      ),
                    ),
                    if (message.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Text(
                          message,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    Center(
                      child: TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const SignupScreen(),
                            ),
                          );
                        },
                        child: const Text("Don't have an account? Sign up"),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
// ---------------- SIGNUP SCREEN ----------------
class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  final passwordController = TextEditingController();

  String selectedRole = 'buyer';
  bool isLoading = false;
  String message = '';

  Future<void> registerUser() async {
    final name = nameController.text.trim();
    final email = emailController.text.trim();
    final phone = phoneController.text.trim();
    final password = passwordController.text;

    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      setState(() => message = 'Name, email aur password zaroori hain');
      return;
    }

    setState(() {
      isLoading = true;
      message = '';
    });

    try {
      final response = await http.post(
        Uri.parse('$kBaseUrl/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': name,
          'email': email,
          'phone': phone,
          'password': password,
          'role': selectedRole,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 201) {
        setState(() {
          message = 'Account created! You can now login.';
        });
      } else {
        setState(() {
          message = data['error'] ?? 'Registration failed';
        });
      }
    } catch (_) {
      setState(() {
        message = 'Error: Could not connect to server';
      });
    }

    if (mounted) {
      setState(() {
        isLoading = false;
      });
    }
  }

  Widget _roleCard(String value, String label, IconData icon) {
    final selected = selectedRole == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => selectedRole = value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: selected
                ? kPrimary.withValues(alpha: 0.12)
                : Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? kPrimary : Colors.grey.shade400,
              width: selected ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(icon, color: selected ? kPrimary : Colors.grey, size: 30),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: selected ? kPrimary : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Account')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Full Name',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Phone (optional)',
                    prefixIcon: Icon(Icons.phone_outlined),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Password',
                    prefixIcon: Icon(Icons.lock_outline),
                  ),
                ),
                const SizedBox(height: 20),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'I am a:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _roleCard('buyer', 'Buyer', Icons.shopping_bag_outlined),
                    const SizedBox(width: 12),
                    _roleCard('seller', 'Seller', Icons.storefront_outlined),
                  ],
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : registerUser,
                    child: isLoading
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          )
                        : const Text('Sign Up'),
                  ),
                ),
                if (message.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(
                      message,
                      style: TextStyle(
                        color: message.contains('created')
                            ? Colors.green
                            : Colors.red,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------- BUYER SHELL (BOTTOM NAVIGATION) ----------------
class BuyerShell extends StatefulWidget {
  final Map<String, dynamic> user;

  const BuyerShell({super.key, required this.user});

  @override
  State<BuyerShell> createState() => _BuyerShellState();
}

class _BuyerShellState extends State<BuyerShell> {
  int index = 0;
  int homeRefresh = 0;

  // user shell ki state mein hai, taaki profile edit ke baad cart na ude
  late Map<String, dynamic> user = widget.user;

  final Map<int, Map<String, dynamic>> cart = {};
  final Set<int> wishlist = {};

  String get wishlistKey => 'wishlist_${user['id']}';

  @override
  void initState() {
    super.initState();
    loadWishlist();
  }

  int get cartCount => cart.values.fold(
        0,
        (sum, item) => sum + (item['quantity'] as int),
      );

  void refresh() => setState(() {});

  Future<void> loadWishlist() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList(wishlistKey) ?? [];
    if (!mounted) return;
    setState(() {
      wishlist.addAll(saved.map((e) => int.tryParse(e)).whereType<int>());
    });
  }

  Future<void> saveWishlist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      wishlistKey,
      wishlist.map((e) => e.toString()).toList(),
    );
  }

  void toggleWishlist(int productId) {
    setState(() {
      if (wishlist.contains(productId)) {
        wishlist.remove(productId);
      } else {
        wishlist.add(productId);
      }
    });
    saveWishlist();
  }

  void onOrderPlaced() {
    setState(() {
      cart.clear();
      homeRefresh++; // Home dobara load hoga (stock update)
      index = 2; // Orders tab pe le jao
    });
  }

  void openWishlist() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => WishlistScreen(
          user: user,
          cart: cart,
          wishlist: wishlist,
          onCartChanged: refresh,
          onWishlistChanged: toggleWishlist,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: index,
        children: [
          HomeScreen(
            key: ValueKey(homeRefresh),
            user: user,
            cart: cart,
            wishlist: wishlist,
            onCartChanged: refresh,
            onWishlistChanged: toggleWishlist,
          ),
          CartScreen(
            cart: cart,
            buyerId: user['id'],
            defaultAddress: (user['address'] ?? '').toString(),
            onOrderPlaced: onOrderPlaced,
            onChanged: refresh,
          ),
          // Orders tab har baar fresh load hota hai
          index == 2
              ? OrderHistoryScreen(buyerId: user['id'])
              : const SizedBox.shrink(),
          ProfileScreen(
            user: user,
            onOpenOrders: () => setState(() => index = 2),
            onOpenWishlist: openWishlist,
            onUserUpdated: (u) => setState(() => user = u),
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (i) => setState(() => index = i),
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: cartCount > 0,
              label: Text('$cartCount'),
              child: const Icon(Icons.shopping_cart_outlined),
            ),
            selectedIcon: const Icon(Icons.shopping_cart),
            label: 'Cart',
          ),
          const NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long),
            label: 'Orders',
          ),
          const NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

// ---------------- HOME SCREEN ----------------
class HomeScreen extends StatefulWidget {
  final Map<String, dynamic> user;
  final Map<int, Map<String, dynamic>> cart;
  final Set<int> wishlist;
  final VoidCallback onCartChanged;
  final ValueChanged<int> onWishlistChanged;

  const HomeScreen({
    super.key,
    required this.user,
    required this.cart,
    required this.wishlist,
    required this.onCartChanged,
    required this.onWishlistChanged,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List products = [];
  List categories = [];

  bool isLoading = true;
  String errorMessage = '';

  String selectedType = 'new';
  String searchQuery = '';
  String selectedCategory = 'All';

  final searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchProducts();
  }

  Future<void> fetchProducts() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      final response = await http.get(
        Uri.parse('$kBaseUrl/products/?type=$selectedType'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List;

        final cats = <String>{'All'};
        for (final p in data) {
          final c = (p['category'] ?? '').toString().trim();
          if (c.isNotEmpty) cats.add(c);
        }

        setState(() {
          products = data;
          categories = cats.toList();
          if (!cats.contains(selectedCategory)) selectedCategory = 'All';
        });
      } else {
        setState(() {
          errorMessage = 'Failed to load products';
        });
      }
    } catch (_) {
      setState(() {
        errorMessage = 'Error: Could not connect to server';
      });
    }

    if (mounted) {
      setState(() {
        isLoading = false;
      });
    }
  }

  List get filteredProducts {
    final query = searchQuery.toLowerCase().trim();

    return products.where((p) {
      final name = (p['name'] ?? '').toString().toLowerCase();
      final desc = (p['description'] ?? '').toString().toLowerCase();
      final category = (p['category'] ?? '').toString();

      final matchesSearch =
          query.isEmpty || name.contains(query) || desc.contains(query);
      final matchesCategory =
          selectedCategory == 'All' || category == selectedCategory;

      return matchesSearch && matchesCategory;
    }).toList();
  }

  void addToCart(Map product) {
    final id = product['id'];

    if (widget.cart.containsKey(id)) {
      widget.cart[id]!['quantity'] += 1;
    } else {
      widget.cart[id] = {
        'product': product,
        'quantity': 1,
      };
    }

    widget.onCartChanged();
    snack(context, '${product['name']} added to cart');
  }

  void openSellItem() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SellItemScreen(sellerId: widget.user['id']),
      ),
    ).then((posted) {
      if (posted == true) {
        setState(() => selectedType = 'used');
        fetchProducts();
      }
    });
  }

  void openProductDetails(Map product) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProductDetailsScreen(
          product: product,
          user: widget.user,
          cart: widget.cart,
          wishlist: widget.wishlist,
          onCartChanged: widget.onCartChanged,
          onWishlistChanged: widget.onWishlistChanged,
        ),
      ),
    ).then((_) {
      // detail screen se wapas aane pe heart/cart state refresh
      if (mounted) setState(() {});
    });
  }

  Widget _badge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildProductCard(Map product) {
    final inStock = (product['stock'] ?? 0) > 0;
    final isUsed = product['listing_type'] == 'used';
    final isMine = product['seller_id'] == widget.user['id'];
    final isWishlisted = widget.wishlist.contains(product['id']);
    final hasOffer = !isUsed && product['discount_price'] != null;
    final cond = (product['item_condition'] ?? '').toString();
    final city = (product['city'] ?? '').toString();

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => openProductDetails(product),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ProductImage(
                    path: product['image_url'],
                    height: double.infinity,
                    radius: 0,
                    fallback: isUsed ? Icons.recycling : Icons.shopping_bag,
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: () =>
                          widget.onWishlistChanged(product['id'] as int),
                      child: CircleAvatar(
                        radius: 16,
                        backgroundColor: Colors.white,
                        child: Icon(
                          isWishlisted
                              ? Icons.favorite
                              : Icons.favorite_border,
                          size: 18,
                          color: isWishlisted ? Colors.red : Colors.grey,
                        ),
                      ),
                    ),
                  ),
                  if (isUsed && cond.isNotEmpty)
                    Positioned(top: 8, left: 8, child: _badge(cond, kPrimary)),
                  if (hasOffer)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: _badge('OFFER', kAccent),
                    ),
                  if (!isUsed && !inStock)
                    Container(
                      color: Colors.black45,
                      alignment: Alignment.center,
                      child: const Text(
                        'OUT OF STOCK',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product['name'] ?? '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isUsed && city.isNotEmpty
                        ? '📍 $city'
                        : (product['category'] ?? '').toString(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '₹${hasOffer ? product['discount_price'] : product['price']}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          color: kPrimary,
                        ),
                      ),
                      if (hasOffer) ...[
                        const SizedBox(width: 6),
                        Text(
                          '₹${product['price']}',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade500,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (hasOffer)
                    const Text(
                      'with voucher',
                      style: TextStyle(fontSize: 10, color: Colors.deepOrange),
                    ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    height: 34,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.zero,
                      ),
                      onPressed: (inStock && !isMine)
                          ? () => addToCart(product)
                          : null,
                      child: Text(
                        isMine
                            ? 'Yours'
                            : (inStock ? 'Add to Cart' : 'Sold out'),
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final items = filteredProducts;

    return Scaffold(
      appBar: AppBar(title: const Text('Kreysetu')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: openSellItem,
        icon: const Icon(Icons.sell),
        label: const Text('Sell Item'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
            child: TextField(
              controller: searchController,
              onChanged: (v) => setState(() => searchQuery = v),
              decoration: InputDecoration(
                hintText: 'Search products...',
                prefixIcon: const Icon(Icons.search),
                isDense: true,
                suffixIcon: searchQuery.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          searchController.clear();
                          setState(() => searchQuery = '');
                        },
                      ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
            child: SizedBox(
              width: double.infinity,
              child: SegmentedButton<String>(
                segments: const [
                  ButtonSegment(
                    value: 'new',
                    label: Text('New'),
                    icon: Icon(Icons.storefront),
                  ),
                  ButtonSegment(
                    value: 'used',
                    label: Text('Used'),
                    icon: Icon(Icons.recycling),
                  ),
                ],
                selected: {selectedType},
                onSelectionChanged: (s) {
                  setState(() {
                    selectedType = s.first;
                    selectedCategory = 'All';
                  });
                  fetchProducts();
                },
              ),
            ),
          ),
          if (categories.length > 1)
            SizedBox(
              height: 56,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.all(12),
                children: categories
                    .map(
                      (c) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(c),
                          selected: selectedCategory == c,
                          onSelected: (_) =>
                              setState(() => selectedCategory = c),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: fetchProducts,
              child: isLoading
                  ? productGridSkeleton()
                  : errorMessage.isNotEmpty
                      ? centerMessage(errorMessage, icon: Icons.wifi_off)
                      : items.isEmpty
                          ? centerMessage(
                              selectedType == 'used'
                                  ? 'No used items found.\nTap "Sell Item" to list one!'
                                  : 'No products found.',
                              icon: Icons.search_off,
                            )
                          : GridView.builder(
                              padding:
                                  const EdgeInsets.fromLTRB(12, 12, 12, 90),
                              gridDelegate:
                                  const SliverGridDelegateWithMaxCrossAxisExtent(
                                maxCrossAxisExtent: 220,
                                mainAxisSpacing: 12,
                                crossAxisSpacing: 12,
                                childAspectRatio: 0.62,
                              ),
                              itemCount: items.length,
                              itemBuilder: (_, i) =>
                                  _buildProductCard(items[i]),
                            ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------- PRODUCT DETAILS ----------------
class ProductDetailsScreen extends StatefulWidget {
  final Map product;
  final Map<String, dynamic> user;
  final Map<int, Map<String, dynamic>> cart;
  final Set<int> wishlist;
  final VoidCallback onCartChanged;
  final ValueChanged<int> onWishlistChanged;

  const ProductDetailsScreen({
    super.key,
    required this.product,
    required this.user,
    required this.cart,
    required this.wishlist,
    required this.onCartChanged,
    required this.onWishlistChanged,
  });

  @override
  State<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen> {
  void addToCart() {
    final id = widget.product['id'];

    if (widget.cart.containsKey(id)) {
      widget.cart[id]!['quantity'] += 1;
    } else {
      widget.cart[id] = {
        'product': widget.product,
        'quantity': 1,
      };
    }

    widget.onCartChanged();
    snack(context, '${widget.product['name']} added to cart');
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.product;
    final isUsed = p['listing_type'] == 'used';
    final isMine = p['seller_id'] == widget.user['id'];
    final inStock = (p['stock'] ?? 0) > 0;
    final isWishlisted = widget.wishlist.contains(p['id']);
    final hasOffer = !isUsed && p['discount_price'] != null;
    final sellerName = (p['seller_name'] ?? '').toString();
    final sellerPhone = (p['seller_phone'] ?? '').toString();

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 300,
            flexibleSpace: FlexibleSpaceBar(
              background: ProductImage(
                path: p['image_url'],
                width: double.infinity,
                height: 300,
                radius: 0,
                fallback: isUsed ? Icons.recycling : Icons.shopping_bag,
              ),
            ),
            actions: [
              IconButton(
                icon: Icon(
                  isWishlisted ? Icons.favorite : Icons.favorite_border,
                  color: isWishlisted ? Colors.red : null,
                ),
                onPressed: () {
                  widget.onWishlistChanged(p['id'] as int);
                  setState(() {}); // detail screen turant refresh
                },
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    p['name'] ?? '',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '₹${hasOffer ? p['discount_price'] : p['price']}',
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w700,
                          color: kPrimary,
                        ),
                      ),
                      if (hasOffer) ...[
                        const SizedBox(width: 10),
                        Text(
                          '₹${p['price']}',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey.shade500,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (hasOffer)
                    const Padding(
                      padding: EdgeInsets.only(top: 4),
                      child: Text(
                        '🎁 Voucher ke saath yeh price milega',
                        style: TextStyle(
                          color: Colors.deepOrange,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  const SizedBox(height: 14),
                  Text(
                    (p['description'] ?? '').toString().isEmpty
                        ? 'No description available.'
                        : p['description'],
                    style: const TextStyle(height: 1.5),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    child: Column(
                      children: [
                        ListTile(
                          leading: const Icon(Icons.category, color: kPrimary),
                          title: const Text('Category'),
                          trailing: Text(
                            (p['category'] ?? '').toString().isEmpty
                                ? 'N/A'
                                : p['category'],
                          ),
                        ),
                        ListTile(
                          leading:
                              const Icon(Icons.inventory, color: kPrimary),
                          title: const Text('Type'),
                          trailing: Text(isUsed ? 'Used' : 'New'),
                        ),
                        if (isUsed)
                          ListTile(
                            leading: const Icon(Icons.grade, color: kPrimary),
                            title: const Text('Condition'),
                            trailing: Text(p['item_condition'] ?? 'N/A'),
                          ),
                        if (isUsed)
                          ListTile(
                            leading: const Icon(
                              Icons.location_on,
                              color: kPrimary,
                            ),
                            title: const Text('City'),
                            trailing: Text(p['city'] ?? 'N/A'),
                          ),
                        if (!isUsed)
                          ListTile(
                            leading:
                                const Icon(Icons.inventory_2, color: kPrimary),
                            title: const Text('Stock'),
                            trailing: Text('${p['stock']}'),
                          ),
                        if (sellerName.isNotEmpty)
                          ListTile(
                            leading: const Icon(Icons.store, color: kPrimary),
                            title: const Text('Seller'),
                            trailing: Text(sellerName),
                          ),
                        if (sellerPhone.isNotEmpty)
                          ListTile(
                            leading: const Icon(Icons.phone, color: kPrimary),
                            title: const Text('Contact Seller'),
                            subtitle: Text(sellerPhone),
                            trailing: IconButton(
                              icon: const Icon(Icons.copy),
                              tooltip: 'Copy number',
                              onPressed: () async {
                                await Clipboard.setData(
                                  ClipboardData(text: sellerPhone),
                                );
                                if (!context.mounted) return;
                                snack(context, 'Number copy ho gaya');
                              },
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: (inStock && !isMine) ? addToCart : null,
                      icon: const Icon(Icons.add_shopping_cart),
                      label: Text(
                        isMine
                            ? 'Your Listing'
                            : (inStock ? 'Add to Cart' : 'Out of Stock'),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
// ---------------- WISHLIST ----------------
class WishlistScreen extends StatefulWidget {
  final Map<String, dynamic> user;
  final Map<int, Map<String, dynamic>> cart;
  final Set<int> wishlist;
  final VoidCallback onCartChanged;
  final ValueChanged<int> onWishlistChanged;

  const WishlistScreen({
    super.key,
    required this.user,
    required this.cart,
    required this.wishlist,
    required this.onCartChanged,
    required this.onWishlistChanged,
  });

  @override
  State<WishlistScreen> createState() => _WishlistScreenState();
}

class _WishlistScreenState extends State<WishlistScreen> {
  List products = [];
  bool isLoading = true;
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    fetchProducts();
  }

  Future<void> fetchProducts() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      final response = await http.get(Uri.parse('$kBaseUrl/products/'));

      if (response.statusCode == 200) {
        setState(() => products = jsonDecode(response.body));
      } else {
        setState(() => errorMessage = 'Failed to load products');
      }
    } catch (_) {
      setState(() => errorMessage = 'Error: Could not connect to server');
    }

    if (mounted) setState(() => isLoading = false);
  }

  void addToCart(Map product) {
    final id = product['id'];

    if (widget.cart.containsKey(id)) {
      widget.cart[id]!['quantity'] += 1;
    } else {
      widget.cart[id] = {'product': product, 'quantity': 1};
    }

    widget.onCartChanged();
    snack(context, '${product['name']} added to cart');
  }

  @override
  Widget build(BuildContext context) {
    final saved =
        products.where((p) => widget.wishlist.contains(p['id'])).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('My Wishlist')),
      body: RefreshIndicator(
        onRefresh: fetchProducts,
        child: isLoading
            ? listSkeleton()
            : errorMessage.isNotEmpty
                ? centerMessage(errorMessage, icon: Icons.wifi_off)
                : saved.isEmpty
                    ? centerMessage(
                        'Wishlist khali hai.\nProduct pe heart dabake save karo.',
                        icon: Icons.favorite_border,
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: saved.length,
                        itemBuilder: (_, i) {
                          final p = saved[i];
                          final inStock = (p['stock'] ?? 0) > 0;
                          final isMine = p['seller_id'] == widget.user['id'];

                          return Card(
                            margin: const EdgeInsets.only(bottom: 10),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              leading: ProductImage(
                                path: p['image_url'],
                                width: 52,
                                height: 52,
                              ),
                              title: Text(
                                p['name'] ?? '',
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              subtitle: Text(
                                '₹${p['price']}',
                                style: const TextStyle(
                                  color: kPrimary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(
                                      Icons.favorite,
                                      color: Colors.red,
                                    ),
                                    onPressed: () {
                                      widget.onWishlistChanged(p['id'] as int);
                                      setState(() {});
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.add_shopping_cart),
                                    color: kPrimary,
                                    onPressed: (inStock && !isMine)
                                        ? () => addToCart(p)
                                        : null,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
      ),
    );
  }
}

// ---------------- ORDER HISTORY ----------------
class OrderHistoryScreen extends StatefulWidget {
  final int buyerId;

  const OrderHistoryScreen({super.key, required this.buyerId});

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
  List orders = [];
  bool isLoading = true;
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    fetchOrders();
  }

  Future<void> fetchOrders() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      final response = await http.get(
        Uri.parse('$kBaseUrl/orders/buyer/${widget.buyerId}'),
      );

      if (response.statusCode == 200) {
        setState(() => orders = jsonDecode(response.body));
      } else {
        setState(() => errorMessage = 'Failed to load orders');
      }
    } catch (_) {
      setState(() => errorMessage = 'Error: Could not connect to server');
    }

    if (mounted) setState(() => isLoading = false);
  }

  Future<void> cancelOrder(int orderId) async {
    final ok = await confirmDialog(
      context,
      title: 'Cancel Order?',
      message: 'Order #$orderId cancel karna hai?',
      yes: 'Yes, Cancel',
    );
    if (!ok) return;

    try {
      final response = await http.post(
        Uri.parse('$kBaseUrl/orders/$orderId/cancel'),
        headers: {'Content-Type': 'application/json'},
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        snack(context, 'Order cancelled');
        fetchOrders();
      } else {
        String err = 'Cancel failed';
        try {
          err = jsonDecode(response.body)['error'] ?? err;
        } catch (_) {}
        snack(context, err);
      }
    } catch (_) {
      snack(context, 'Could not connect to server');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Orders')),
      body: RefreshIndicator(
        onRefresh: fetchOrders,
        child: isLoading
            ? listSkeleton()
            : errorMessage.isNotEmpty
                ? centerMessage(errorMessage, icon: Icons.wifi_off)
                : orders.isEmpty
                    ? centerMessage(
                        'You have no orders yet.',
                        icon: Icons.receipt_long_outlined,
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: orders.length,
                        itemBuilder: (_, i) {
                          final order = orders[i];
                          final status = (order['status'] ?? '').toString();
                          final canCancel = status.toLowerCase() == 'pending';

                          return Card(
                            margin: const EdgeInsets.only(bottom: 10),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 8,
                              ),
                              leading: CircleAvatar(
                                backgroundColor:
                                    kPrimary.withValues(alpha: 0.12),
                                child: const Icon(
                                  Icons.receipt,
                                  color: kPrimary,
                                ),
                              ),
                              title: Text(
                                'Order #${order['id']}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    StatusChip(status: status),
                                    const SizedBox(height: 4),
                                    Text('${order['order_date']}'),
                                    if (canCancel)
                                      const Text(
                                        'Cancel karne ke liye long-press karo',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.grey,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              trailing: Text(
                                '₹${order['total_amount']}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                              isThreeLine: true,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        OrderDetailsScreen(order: order),
                                  ),
                                );
                              },
                              onLongPress: canCancel
                                  ? () => cancelOrder(order['id'])
                                  : null,
                            ),
                          );
                        },
                      ),
      ),
    );
  }
}

// ---------------- ORDER DETAILS ----------------
class OrderDetailsScreen extends StatelessWidget {
  final Map order;

  const OrderDetailsScreen({super.key, required this.order});

  // Pending -> Shipped -> Delivered timeline
  Widget _timeline(String status) {
    final s = status.toLowerCase();

    if (s == 'cancelled') {
      return const Row(
        children: [
          Icon(Icons.cancel, color: Colors.red),
          SizedBox(width: 8),
          Text(
            'Order cancelled',
            style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600),
          ),
        ],
      );
    }

    final steps = ['Pending', 'Shipped', 'Delivered'];
    final current = steps.indexWhere((e) => e.toLowerCase() == s);

    final children = <Widget>[];
    for (int i = 0; i < steps.length; i++) {
      final done = i <= current;
      children.add(
        Column(
          children: [
            CircleAvatar(
              radius: 14,
              backgroundColor: done ? kPrimary : Colors.grey.shade300,
              child: Icon(
                done ? Icons.check : Icons.circle,
                size: done ? 16 : 8,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              steps[i],
              style: TextStyle(
                fontSize: 12,
                fontWeight: done ? FontWeight.w600 : FontWeight.normal,
                color: done ? kPrimary : Colors.grey,
              ),
            ),
          ],
        ),
      );
      if (i < steps.length - 1) {
        children.add(
          Expanded(
            child: Container(
              height: 3,
              margin: const EdgeInsets.only(bottom: 22),
              color: i < current ? kPrimary : Colors.grey.shade300,
            ),
          ),
        );
      }
    }
    return Row(children: children);
  }

  @override
  Widget build(BuildContext context) {
    final items = (order['items'] ?? []) as List;
    final status = (order['status'] ?? '').toString();

    return Scaffold(
      appBar: AppBar(title: Text('Order #${order['id']}')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: _timeline(status),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  StatusChip(status: status),
                  const SizedBox(height: 10),
                  Text('Date: ${order['order_date']}'),
                  const SizedBox(height: 6),
                  Text('Address: ${order['address'] ?? 'N/A'}'),
                  const SizedBox(height: 6),
                  Text(
                    'Total: ₹${order['total_amount']}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: kPrimary,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Items',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          if (items.isEmpty)
            const Text('Item details abhi available nahi hain.')
          else
            ...items.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Card(
                  child: ListTile(
                    title: Text(item['product_name'] ?? 'Product'),
                    subtitle: Text(
                      'Qty: ${item['quantity']} × ₹${item['price']}',
                    ),
                    trailing: Text(
                      '₹${item['total_price'] ?? ''}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ---------------- CART SCREEN ----------------
class CartScreen extends StatefulWidget {
  final Map<int, Map<String, dynamic>> cart;
  final int buyerId;
  final String defaultAddress;
  final VoidCallback onOrderPlaced;
  final VoidCallback onChanged;

  const CartScreen({
    super.key,
    required this.cart,
    required this.buyerId,
    this.defaultAddress = '',
    required this.onOrderPlaced,
    required this.onChanged,
  });

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  late final addressController =
      TextEditingController(text: widget.defaultAddress);
  final voucherController = TextEditingController();

  bool isPlacingOrder = false;
  bool isCheckingVoucher = false;

  String message = '';
  String voucherMessage = '';

  Map<String, dynamic>? appliedVoucher;

  double get subtotal {
    double sum = 0;

    widget.cart.forEach((_, item) {
      sum += (item['product']['price'] as num) * (item['quantity'] as int);
    });

    return sum;
  }

  double get discountAmount {
    if (appliedVoucher == null) return 0;

    final type = appliedVoucher!['discount_type'];
    final value = (appliedVoucher!['discount_value'] as num).toDouble();

    final d = type == 'percent' ? subtotal * (value / 100) : value;
    return d > subtotal ? subtotal : d;
  }

  double get total {
    final t = subtotal - discountAmount;
    return t < 0 ? 0 : t;
  }

  void increaseQty(int id) {
    setState(() => widget.cart[id]!['quantity'] += 1);
    widget.onChanged();
  }

  void decreaseQty(int id) {
    setState(() {
      if (widget.cart[id]!['quantity'] > 1) {
        widget.cart[id]!['quantity'] -= 1;
      } else {
        widget.cart.remove(id);
      }
    });

    widget.onChanged();
  }

  Future<void> applyVoucher() async {
    final code = voucherController.text.trim();
    if (code.isEmpty) return;

    setState(() {
      isCheckingVoucher = true;
      voucherMessage = '';
    });

    try {
      final response = await http.post(
        Uri.parse('$kBaseUrl/vouchers/validate'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'code': code}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        setState(() {
          appliedVoucher = data['voucher'];
          voucherMessage = 'Voucher applied! 🎉';
        });
      } else {
        setState(() {
          appliedVoucher = null;
          voucherMessage = data['error'] ?? 'Invalid voucher';
        });
      }
    } catch (_) {
      setState(() {
        voucherMessage = 'Error: Could not connect to server';
      });
    }

    if (mounted) setState(() => isCheckingVoucher = false);
  }

  void removeVoucher() {
    setState(() {
      appliedVoucher = null;
      voucherMessage = '';
      voucherController.clear();
    });
  }

  Future<void> placeOrder() async {
    if (widget.cart.isEmpty) return;

    if (addressController.text.trim().isEmpty) {
      setState(() => message = 'Please enter a delivery address');
      return;
    }

    setState(() {
      isPlacingOrder = true;
      message = '';
    });

    try {
      final items = widget.cart.values
          .map(
            (item) => {
              'product_id': item['product']['id'],
              'quantity': item['quantity'],
            },
          )
          .toList();

      final response = await http.post(
        Uri.parse('$kBaseUrl/orders/place'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'buyer_id': widget.buyerId,
          'address': addressController.text.trim(),
          'items': items,
          'voucher_code':
              appliedVoucher != null ? appliedVoucher!['code'] : null,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 201) {
        removeVoucher();
        widget.onOrderPlaced();

        if (mounted) {
          showDialog(
            context: context,
            builder: (dialogContext) => AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              icon: const Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 56,
              ),
              title: const Text('Order Placed!'),
              content: Text(
                'Your order (#${data['order_id']}) worth ₹${data['total']} has been placed successfully.',
                textAlign: TextAlign.center,
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        }
      } else {
        setState(() => message = data['error'] ?? 'Failed to place order');
      }
    } catch (_) {
      setState(() => message = 'Error: Could not connect to server');
    }

    if (mounted) setState(() => isPlacingOrder = false);
  }

  @override
  Widget build(BuildContext context) {
    final items = widget.cart.entries.toList();

    return Scaffold(
      appBar: AppBar(title: const Text('My Cart')),
      body: items.isEmpty
          ? ListView(
              children: [
                SizedBox(
                  height: 420,
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(22),
                          decoration: BoxDecoration(
                            color: kPrimary.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.shopping_cart_outlined,
                            size: 48,
                            color: kPrimary,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Your cart is empty.',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            )
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: items.length,
                    itemBuilder: (_, i) {
                      final id = items[i].key;
                      final item = items[i].value;
                      final product = item['product'];
                      final qty = item['quantity'];

                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          leading: ProductImage(
                            path: product['image_url'],
                            width: 52,
                            height: 52,
                          ),
                          title: Text(
                            product['name'] ?? '',
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          subtitle: Text('₹${product['price']} each'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove_circle_outline),
                                onPressed: () => decreaseQty(id),
                              ),
                              Text(
                                '$qty',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.add_circle_outline),
                                onPressed: () => increaseQty(id),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(24),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 12,
                        offset: const Offset(0, -4),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(16),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.of(context).size.height * 0.5,
                    ),
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: voucherController,
                                  enabled: appliedVoucher == null,
                                  textCapitalization:
                                      TextCapitalization.characters,
                                  decoration: const InputDecoration(
                                    labelText: 'Voucher Code',
                                    prefixIcon: Icon(Icons.local_offer_outlined),
                                    isDense: true,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton(
                                onPressed: appliedVoucher != null
                                    ? removeVoucher
                                    : (isCheckingVoucher
                                        ? null
                                        : applyVoucher),
                                child: Text(
                                  appliedVoucher != null ? 'Remove' : 'Apply',
                                ),
                              ),
                            ],
                          ),
                          if (voucherMessage.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  voucherMessage,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: appliedVoucher != null
                                        ? Colors.green
                                        : Colors.red,
                                  ),
                                ),
                              ),
                            ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Subtotal'),
                              Text('₹${subtotal.toStringAsFixed(2)}'),
                            ],
                          ),
                          if (appliedVoucher != null)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Discount',
                                  style: TextStyle(color: Colors.green),
                                ),
                                Text(
                                  '- ₹${discountAmount.toStringAsFixed(2)}',
                                  style: const TextStyle(color: Colors.green),
                                ),
                              ],
                            ),
                          const Divider(),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Total',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                '₹${total.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: kPrimary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: addressController,
                            maxLines: 2,
                            decoration: const InputDecoration(
                              labelText: 'Delivery Address',
                              prefixIcon: Icon(Icons.location_on_outlined),
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              onPressed: isPlacingOrder ? null : placeOrder,
                              child: isPlacingOrder
                                  ? const SizedBox(
                                      height: 22,
                                      width: 22,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2.5,
                                      ),
                                    )
                                  : const Text('Place Order'),
                            ),
                          ),
                          if (message.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                message,
                                style: const TextStyle(color: Colors.red),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

// ---------------- PROFILE SCREEN ----------------
class ProfileScreen extends StatelessWidget {
  final Map<String, dynamic> user;
  final VoidCallback onOpenOrders;
  final VoidCallback? onOpenWishlist;
  final ValueChanged<Map<String, dynamic>> onUserUpdated;
  final bool showSellOption;

  const ProfileScreen({
    super.key,
    required this.user,
    required this.onOpenOrders,
    required this.onUserUpdated,
    this.onOpenWishlist,
    this.showSellOption = true,
  });

  @override
  Widget build(BuildContext context) {
    final name = (user['name'] ?? '').toString();
    final phone = (user['phone'] ?? '').toString();
    final address = (user['address'] ?? '').toString();

    return Scaffold(
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 70, 20, 30),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF00695C), kPrimary, Color(0xFF26A69A)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.vertical(
                bottom: Radius.circular(32),
              ),
            ),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 42,
                  backgroundColor: Colors.white,
                  child: Text(
                    name.isNotEmpty ? name[0].toUpperCase() : '?',
                    style: const TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.bold,
                      color: kPrimary,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  user['email'] ?? '',
                  style: const TextStyle(color: Colors.white70),
                ),
                if (phone.isNotEmpty)
                  Text(phone, style: const TextStyle(color: Colors.white70)),
                if (address.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      '📍 $address',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.edit, color: kPrimary),
                    title: const Text('Edit Profile'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () async {
                      final updated =
                          await Navigator.push<Map<String, dynamic>>(
                        context,
                        MaterialPageRoute(
                          builder: (_) => EditProfileScreen(user: user),
                        ),
                      );
                      if (updated != null) onUserUpdated(updated);
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.receipt_long, color: kPrimary),
                    title: const Text('My Orders'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: onOpenOrders,
                  ),
                  if (onOpenWishlist != null)
                    ListTile(
                      leading: const Icon(Icons.favorite, color: kPrimary),
                      title: const Text('My Wishlist'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: onOpenWishlist,
                    ),
                  if (showSellOption)
                    ListTile(
                      leading: const Icon(Icons.sell, color: kPrimary),
                      title: const Text('Sell an Item'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                SellItemScreen(sellerId: user['id']),
                          ),
                        );
                      },
                    ),
                  ValueListenableBuilder<ThemeMode>(
                    valueListenable: themeNotifier,
                    builder: (_, mode, __) => SwitchListTile(
                      secondary: const Icon(Icons.dark_mode, color: kPrimary),
                      title: const Text('Dark Mode'),
                      value: mode == ThemeMode.dark,
                      onChanged: setDarkMode,
                    ),
                  ),
                  ListTile(
                    leading: const Icon(Icons.logout, color: Colors.red),
                    title: const Text(
                      'Logout',
                      style: TextStyle(color: Colors.red),
                    ),
                    onTap: () => logout(context),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------- EDIT PROFILE ----------------
class EditProfileScreen extends StatefulWidget {
  final Map<String, dynamic> user;

  const EditProfileScreen({super.key, required this.user});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late final nameController =
      TextEditingController(text: (widget.user['name'] ?? '').toString());
  late final phoneController =
      TextEditingController(text: (widget.user['phone'] ?? '').toString());
  late final addressController =
      TextEditingController(text: (widget.user['address'] ?? '').toString());

  bool isLoading = false;
  String message = '';

  Future<void> updateProfile() async {
    if (nameController.text.trim().isEmpty) {
      setState(() => message = 'Name khali nahi ho sakta');
      return;
    }

    setState(() {
      isLoading = true;
      message = '';
    });

    try {
      final response = await http.put(
        Uri.parse('$kBaseUrl/users/${widget.user['id']}/profile'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': nameController.text.trim(),
          'phone': phoneController.text.trim(),
          'address': addressController.text.trim(),
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final updatedUser = Map<String, dynamic>.from(data['user']);
        await saveSession(updatedUser);

        if (mounted) {
          // sirf wapas jao aur naya user bhejo, cart/shell bacha rahega
          Navigator.pop(context, updatedUser);
        }
        return;
      } else {
        setState(() {
          message = data['error'] ?? 'Update failed';
        });
      }
    } catch (_) {
      setState(() {
        message = 'Error: Could not connect to server';
      });
    }

    if (mounted) setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Profile')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: ListView(
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Full Name',
                prefixIcon: Icon(Icons.person_outline),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Phone',
                prefixIcon: Icon(Icons.phone_outlined),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: addressController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Default Address',
                prefixIcon: Icon(Icons.location_on_outlined),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: isLoading ? null : updateProfile,
                child: isLoading
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      )
                    : const Text('Save Changes'),
              ),
            ),
            if (message.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  message,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ---------------- SELL ITEM SCREEN (USED / OLX-STYLE) ----------------
class SellItemScreen extends StatefulWidget {
  final int sellerId;

  const SellItemScreen({super.key, required this.sellerId});

  @override
  State<SellItemScreen> createState() => _SellItemScreenState();
}

class _SellItemScreenState extends State<SellItemScreen> {
  final nameController = TextEditingController();
  final descController = TextEditingController();
  final priceController = TextEditingController();
  final categoryController = TextEditingController();
  final cityController = TextEditingController();

  String condition = 'Good';
  bool isLoading = false;
  String message = '';
  PickedPhoto? photo;

  final List<String> conditions = ['Like New', 'Good', 'Fair'];

  Future<void> postItem() async {
    final name = nameController.text.trim();
    final price = double.tryParse(priceController.text.trim());
    final city = cityController.text.trim();

    if (name.isEmpty || price == null || price <= 0 || city.isEmpty) {
      setState(() {
        message = 'Name, price aur city zaroori hain';
      });
      return;
    }

    setState(() {
      isLoading = true;
      message = '';
    });

    // pehle photo upload karo (agar chuni hai)
    String imagePath = '';
    if (photo != null) {
      try {
        imagePath = await uploadPhoto(photo!);
      } catch (e) {
        if (!mounted) return;
        setState(() {
          message = 'Photo upload nahi hui: $e';
          isLoading = false;
        });
        return;
      }
    }

    try {
      final response = await http.post(
        Uri.parse('$kBaseUrl/products/add'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'seller_id': widget.sellerId,
          'name': name,
          'description': descController.text.trim(),
          'price': price,
          'stock': 1,
          'category': categoryController.text.trim(),
          'image_url': imagePath,
          'listing_type': 'used',
          'item_condition': condition,
          'city': city,
        }),
      );

      if (response.statusCode == 201) {
        if (mounted) Navigator.pop(context, true);
        return;
      } else {
        final data = jsonDecode(response.body);
        setState(() {
          message = data['error'] ?? 'Failed to post item';
        });
      }
    } catch (_) {
      setState(() {
        message = 'Error: Could not connect to server';
      });
    }

    if (mounted) setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sell an Item')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: ListView(
          children: [
            PhotoPickerBox(
              photo: photo,
              onChanged: (p) => setState(() => photo = p),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Item Name'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descController,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Description'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: priceController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Price (₹)'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: categoryController,
              decoration: const InputDecoration(
                labelText: 'Category',
                hintText: 'Mobile, Laptop, Books...',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: cityController,
              decoration: const InputDecoration(labelText: 'City'),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: condition,
              items: conditions
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (v) => setState(() => condition = v!),
              decoration: const InputDecoration(labelText: 'Condition'),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: isLoading ? null : postItem,
                child: isLoading
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      )
                    : const Text('Post Item'),
              ),
            ),
            if (message.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  message,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ---------------- ADD PRODUCT SCREEN (SELLER - NEW ITEMS) ----------------
class AddProductScreen extends StatefulWidget {
  final int sellerId;

  const AddProductScreen({super.key, required this.sellerId});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final nameController = TextEditingController();
  final descController = TextEditingController();
  final priceController = TextEditingController();
  final stockController = TextEditingController();
  final categoryController = TextEditingController();
  final discountPriceController = TextEditingController();

  DateTime? expiryDate;
  PickedPhoto? photo;
  bool isLoading = false;
  String message = '';

  String _formatDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> pickExpiryDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => expiryDate = picked);
    }
  }

  Future<void> addProduct() async {
    final name = nameController.text.trim();
    final price = double.tryParse(priceController.text.trim());
    final stock = int.tryParse(stockController.text.trim()) ?? 0;
    final discountText = discountPriceController.text.trim();
    final discount =
        discountText.isNotEmpty ? double.tryParse(discountText) : null;

    if (name.isEmpty || price == null || price <= 0) {
      setState(() => message = 'Name aur valid price zaroori hain');
      return;
    }
    if (stock <= 0) {
      setState(() => message = 'Stock kam se kam 1 hona chahiye');
      return;
    }
    if (discountText.isNotEmpty && (discount == null || discount >= price)) {
      setState(
        () => message = 'Discounted price, asli price se kam honi chahiye',
      );
      return;
    }

    setState(() {
      isLoading = true;
      message = '';
    });

    String imagePath = '';
    if (photo != null) {
      try {
        imagePath = await uploadPhoto(photo!);
      } catch (e) {
        if (!mounted) return;
        setState(() {
          message = 'Photo upload nahi hui: $e';
          isLoading = false;
        });
        return;
      }
    }

    try {
      final response = await http.post(
        Uri.parse('$kBaseUrl/products/add'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'seller_id': widget.sellerId,
          'name': name,
          'description': descController.text.trim(),
          'price': price,
          'stock': stock,
          'category': categoryController.text.trim(),
          'image_url': imagePath,
          'listing_type': 'new',
          'expiry_date': expiryDate != null ? _formatDate(expiryDate!) : null,
          'discount_price': discount,
        }),
      );

      if (response.statusCode == 201) {
        if (mounted) Navigator.pop(context, true);
        return;
      } else {
        final data = jsonDecode(response.body);
        setState(() => message = data['error'] ?? 'Failed to add product');
      }
    } catch (_) {
      setState(() => message = 'Error: Could not connect to server');
    }

    if (mounted) setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Product')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: ListView(
          children: [
            PhotoPickerBox(
              photo: photo,
              onChanged: (p) => setState(() => photo = p),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Product Name'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descController,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Description'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: priceController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Price (₹)'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: stockController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Stock Quantity'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: categoryController,
              decoration: const InputDecoration(labelText: 'Category'),
            ),
            const SizedBox(height: 24),
            const Divider(),
            const Text(
              'Optional: Expiring Item / Voucher Discount',
              style: TextStyle(fontWeight: FontWeight.bold, color: kPrimary),
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: pickExpiryDate,
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Expiry Date',
                  suffixIcon: Icon(Icons.calendar_today),
                ),
                child: Text(
                  expiryDate == null
                      ? 'Select expiry date (optional)'
                      : _formatDate(expiryDate!),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: discountPriceController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Discounted Price (₹), for expiring items',
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: isLoading ? null : addProduct,
                child: isLoading
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      )
                    : const Text('Add Product'),
              ),
            ),
            if (message.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(message, style: const TextStyle(color: Colors.red)),
              ),
          ],
        ),
      ),
    );
  }
}
// ---------------- SELLER DASHBOARD (BOTTOM NAVIGATION) ----------------
class SellerDashboard extends StatefulWidget {
  final Map<String, dynamic> user;

  const SellerDashboard({super.key, required this.user});

  @override
  State<SellerDashboard> createState() => _SellerDashboardState();
}

class _SellerDashboardState extends State<SellerDashboard> {
  int index = 0;
  late Map<String, dynamic> user = widget.user;

  @override
  Widget build(BuildContext context) {
    final sellerId = user['id'] as int;

    return Scaffold(
      body: IndexedStack(
        index: index,
        children: [
          // Earnings aur Orders tab har baar fresh load hote hain
          index == 0
              ? SellerEarningsScreen(sellerId: sellerId)
              : const SizedBox.shrink(),
          SellerProductsScreen(sellerId: sellerId),
          index == 2
              ? SellerOrdersScreen(sellerId: sellerId)
              : const SizedBox.shrink(),
          ProfileScreen(
            user: user,
            showSellOption: false,
            onOpenOrders: () => setState(() => index = 2),
            onUserUpdated: (u) => setState(() => user = u),
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (i) => setState(() => index = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.currency_rupee_outlined),
            selectedIcon: Icon(Icons.currency_rupee),
            label: 'Earnings',
          ),
          NavigationDestination(
            icon: Icon(Icons.inventory_2_outlined),
            selectedIcon: Icon(Icons.inventory_2),
            label: 'Products',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long),
            label: 'Orders',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

// ---------------- STAT CARD (shared) ----------------
Widget statCard(String title, String value, IconData icon, Color color) {
  return Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: color.withValues(alpha: 0.15),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(color: Colors.grey, fontSize: 13),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

// ---------------- SELLER EARNINGS ----------------
class SellerEarningsScreen extends StatefulWidget {
  final int sellerId;

  const SellerEarningsScreen({super.key, required this.sellerId});

  @override
  State<SellerEarningsScreen> createState() => _SellerEarningsScreenState();
}

class _SellerEarningsScreenState extends State<SellerEarningsScreen> {
  List orders = [];
  bool isLoading = true;
  String errorMessage = '';

  double totalEarning = 0;
  int itemsSold = 0;
  int deliveredOrders = 0;
  int openOrders = 0;

  @override
  void initState() {
    super.initState();
    fetchEarnings();
  }

  Future<void> fetchEarnings() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      final results = await Future.wait([
        http.get(
          Uri.parse('$kBaseUrl/orders/seller/${widget.sellerId}/earnings'),
        ),
        http.get(
          Uri.parse('$kBaseUrl/orders/seller/${widget.sellerId}/orders'),
        ),
      ]);

      final earningsRes = results[0];
      final ordersRes = results[1];

      if (earningsRes.statusCode == 200 && ordersRes.statusCode == 200) {
        final e = jsonDecode(earningsRes.body);
        final list = jsonDecode(ordersRes.body) as List;

        int delivered = 0;
        int open = 0;
        for (final o in list) {
          final s = (o['status'] ?? '').toString().toLowerCase();
          if (s == 'delivered') {
            delivered++;
          } else if (s != 'cancelled') {
            open++;
          }
        }

        setState(() {
          totalEarning = ((e['total_earning'] ?? 0) as num).toDouble();
          itemsSold = (e['total_orders'] ?? 0) as int;
          orders = list;
          deliveredOrders = delivered;
          openOrders = open;
        });
      } else {
        setState(() => errorMessage = 'Failed to load earnings');
      }
    } catch (_) {
      setState(() => errorMessage = 'Error: Could not connect to server');
    }

    if (mounted) setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Seller Earnings')),
      body: RefreshIndicator(
        onRefresh: fetchEarnings,
        child: isLoading
            ? listSkeleton()
            : errorMessage.isNotEmpty
                ? centerMessage(
                    errorMessage,
                    color: Colors.red,
                    icon: Icons.wifi_off,
                  )
                : ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // Total earnings hero card
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF00695C), Color(0xFF26A69A)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Total Earnings',
                              style: TextStyle(color: Colors.white70),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '₹${totalEarning.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 34,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      statCard(
                        'Items Sold',
                        '$itemsSold',
                        Icons.shopping_bag,
                        kPrimary,
                      ),
                      const SizedBox(height: 10),
                      statCard(
                        'Open Orders',
                        '$openOrders',
                        Icons.hourglass_top,
                        Colors.orange,
                      ),
                      const SizedBox(height: 10),
                      statCard(
                        'Delivered Orders',
                        '$deliveredOrders',
                        Icons.local_shipping,
                        Colors.blue,
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Recent Orders',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      if (orders.isEmpty) const Text('No orders yet.'),
                      ...orders.take(10).map(
                            (o) => Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: Card(
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor:
                                        kPrimary.withValues(alpha: 0.12),
                                    child: const Icon(
                                      Icons.receipt,
                                      color: kPrimary,
                                    ),
                                  ),
                                  title: Text('Order #${o['id']}'),
                                  subtitle: Align(
                                    alignment: Alignment.centerLeft,
                                    child: StatusChip(
                                      status: (o['status'] ?? '').toString(),
                                    ),
                                  ),
                                  trailing: Text(
                                    '₹${o['total_amount']}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
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

// ---------------- SELLER PRODUCTS ----------------
class SellerProductsScreen extends StatefulWidget {
  final int sellerId;

  const SellerProductsScreen({super.key, required this.sellerId});

  @override
  State<SellerProductsScreen> createState() => _SellerProductsScreenState();
}

class _SellerProductsScreenState extends State<SellerProductsScreen> {
  List products = [];
  bool isLoading = true;
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    fetchMyProducts();
  }

  Future<void> fetchMyProducts() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      final response = await http.get(
        Uri.parse('$kBaseUrl/products/seller/${widget.sellerId}'),
      );

      if (response.statusCode == 200) {
        setState(() => products = jsonDecode(response.body));
      } else {
        setState(() => errorMessage = 'Failed to load products');
      }
    } catch (_) {
      setState(() => errorMessage = 'Error: Could not connect to server');
    }

    if (mounted) setState(() => isLoading = false);
  }

  Future<void> deleteProduct(int productId) async {
    final ok = await confirmDialog(
      context,
      title: 'Delete Product?',
      message: 'Ye product delete karna hai?',
      yes: 'Delete',
    );
    if (!ok) return;

    try {
      final response = await http.delete(
        Uri.parse('$kBaseUrl/products/$productId?seller_id=${widget.sellerId}'),
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        snack(context, 'Product deleted');
        fetchMyProducts();
      } else {
        String err = 'Delete failed';
        try {
          err = jsonDecode(response.body)['error'] ?? err;
        } catch (_) {}
        snack(context, err);
      }
    } catch (_) {
      snack(context, 'Could not connect to server');
    }
  }

  void chooseAddType() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Kya add karna hai?',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.storefront, color: kPrimary),
              title: const Text('New product'),
              subtitle: const Text('Stock, discount aur expiry ke saath'),
              onTap: () {
                Navigator.pop(sheetContext);
                _open(AddProductScreen(sellerId: widget.sellerId));
              },
            ),
            ListTile(
              leading: const Icon(Icons.recycling, color: kPrimary),
              title: const Text('Used item'),
              subtitle: const Text('Purani cheez bechni hai'),
              onTap: () {
                Navigator.pop(sheetContext);
                _open(SellItemScreen(sellerId: widget.sellerId));
              },
            ),
          ],
        ),
      ),
    );
  }

  void _open(Widget screen) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => screen),
    ).then((value) {
      if (value == true) fetchMyProducts();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Products')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: chooseAddType,
        icon: const Icon(Icons.add),
        label: const Text('Add'),
      ),
      body: RefreshIndicator(
        onRefresh: fetchMyProducts,
        child: isLoading
            ? listSkeleton()
            : errorMessage.isNotEmpty
                ? centerMessage(errorMessage, icon: Icons.wifi_off)
                : products.isEmpty
                    ? centerMessage(
                        'No products listed yet.\nTap "Add" to list your first one!',
                        icon: Icons.inventory_2_outlined,
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(12, 12, 12, 90),
                        itemCount: products.length,
                        itemBuilder: (context, index) {
                          final product = products[index];
                          final isUsed = product['listing_type'] == 'used';

                          return Card(
                            margin: const EdgeInsets.only(bottom: 10),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              leading: ProductImage(
                                path: product['image_url'],
                                width: 52,
                                height: 52,
                                fallback:
                                    isUsed ? Icons.recycling : Icons.inventory,
                              ),
                              title: Text(
                                product['name'] ?? '',
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              subtitle: Text(
                                '₹${product['price']} • Stock: ${product['stock']}${isUsed ? ' • Used' : ''}',
                              ),
                              trailing: IconButton(
                                icon: const Icon(
                                  Icons.delete_outline,
                                  color: Colors.red,
                                ),
                                onPressed: () => deleteProduct(product['id']),
                              ),
                            ),
                          );
                        },
                      ),
      ),
    );
  }
}

// ---------------- SELLER ORDERS ----------------
class SellerOrdersScreen extends StatefulWidget {
  final int sellerId;

  const SellerOrdersScreen({super.key, required this.sellerId});

  @override
  State<SellerOrdersScreen> createState() => _SellerOrdersScreenState();
}

class _SellerOrdersScreenState extends State<SellerOrdersScreen> {
  List orders = [];
  bool isLoading = true;
  String errorMessage = '';

  // backend sirf yehi status maanta hai
  final List<Map<String, dynamic>> statusOptions = const [
    {'label': 'Pending', 'icon': Icons.hourglass_top},
    {'label': 'Shipped', 'icon': Icons.local_shipping},
    {'label': 'Delivered', 'icon': Icons.check_circle},
    {'label': 'Cancelled', 'icon': Icons.cancel},
  ];

  @override
  void initState() {
    super.initState();
    fetchOrders();
  }

  Future<void> fetchOrders() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      final response = await http.get(
        Uri.parse('$kBaseUrl/orders/seller/${widget.sellerId}/orders'),
      );

      if (response.statusCode == 200) {
        setState(() => orders = jsonDecode(response.body));
      } else {
        setState(() => errorMessage = 'Failed to load orders');
      }
    } catch (_) {
      setState(() => errorMessage = 'Error: Could not connect to server');
    }

    if (mounted) setState(() => isLoading = false);
  }

  Future<void> updateStatus(int orderId, String status) async {
    try {
      final response = await http.put(
        Uri.parse('$kBaseUrl/orders/$orderId/status'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'status': status}),
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        snack(context, 'Order #$orderId marked $status');
        fetchOrders();
      } else {
        String err = 'Status update failed';
        try {
          err = jsonDecode(response.body)['error'] ?? err;
        } catch (_) {}
        snack(context, err);
      }
    } catch (_) {
      snack(context, 'Could not connect to server');
    }
  }

  void showStatusSheet(Map order) {
    final current = (order['status'] ?? '').toString();

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Update Order Status',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              ...statusOptions.map((o) {
                final label = o['label'] as String;
                final isCurrent = label.toLowerCase() == current.toLowerCase();
                return ListTile(
                  leading:
                      Icon(o['icon'] as IconData, color: statusColor(label)),
                  title: Text(label),
                  trailing: isCurrent
                      ? const Icon(Icons.check, color: kPrimary)
                      : null,
                  onTap: isCurrent
                      ? null
                      : () {
                          Navigator.pop(sheetContext);
                          updateStatus(order['id'], label);
                        },
                );
              }),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Received Orders')),
      body: RefreshIndicator(
        onRefresh: fetchOrders,
        child: isLoading
            ? listSkeleton()
            : errorMessage.isNotEmpty
                ? centerMessage(errorMessage, icon: Icons.wifi_off)
                : orders.isEmpty
                    ? centerMessage(
                        'No orders received yet.',
                        icon: Icons.receipt_long_outlined,
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: orders.length,
                        itemBuilder: (context, index) {
                          final order = orders[index];
                          final status = (order['status'] ?? '').toString();

                          return Card(
                            margin: const EdgeInsets.only(bottom: 10),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 8,
                              ),
                              leading: CircleAvatar(
                                backgroundColor:
                                    kPrimary.withValues(alpha: 0.12),
                                child: const Icon(
                                  Icons.receipt,
                                  color: kPrimary,
                                ),
                              ),
                              title: Text(
                                'Order #${order['id']}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    StatusChip(status: status),
                                    const SizedBox(height: 4),
                                    Text('${order['address'] ?? ''}'),
                                    Text('${order['order_date']}'),
                                    const Text(
                                      'Status badalne ke liye tap karo',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              trailing: Text(
                                '₹${order['total_amount']}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                              isThreeLine: true,
                              onTap: () => showStatusSheet(order),
                            ),
                          );
                        },
                      ),
      ),
    );
  }
}

// ---------------- ADMIN DASHBOARD (BOTTOM NAVIGATION) ----------------
class AdminDashboard extends StatefulWidget {
  final Map<String, dynamic> user;

  const AdminDashboard({super.key, required this.user});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int index = 0;
  late Map<String, dynamic> user = widget.user;

  @override
  Widget build(BuildContext context) {
    // screens aur destinations ki order bilkul same honi chahiye
    final screens = [
      const AdminEarningsScreen(),
      const AdminUsersScreen(),
      const AdminProductsScreen(),
      const AdminOrdersScreen(),
      const AdminVouchersScreen(),
      ProfileScreen(
        user: user,
        showSellOption: false,
        onOpenOrders: () => setState(() => index = 3),
        onUserUpdated: (u) => setState(() => user = u),
      ),
    ];

    return Scaffold(
      body: screens[index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
        onDestinationSelected: (i) => setState(() => index = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.account_balance_wallet_outlined),
            selectedIcon: Icon(Icons.account_balance_wallet),
            label: 'Earnings',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outline),
            selectedIcon: Icon(Icons.people),
            label: 'Users',
          ),
          NavigationDestination(
            icon: Icon(Icons.inventory_2_outlined),
            selectedIcon: Icon(Icons.inventory_2),
            label: 'Products',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long),
            label: 'Orders',
          ),
          NavigationDestination(
            icon: Icon(Icons.local_offer_outlined),
            selectedIcon: Icon(Icons.local_offer),
            label: 'Vouchers',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

// ---------------- ADMIN EARNINGS ----------------
class AdminEarningsScreen extends StatefulWidget {
  const AdminEarningsScreen({super.key});

  @override
  State<AdminEarningsScreen> createState() => _AdminEarningsScreenState();
}

class _AdminEarningsScreenState extends State<AdminEarningsScreen> {
  Map<String, dynamic> data = {};
  bool isLoading = true;
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    fetchEarnings();
  }

  Future<void> fetchEarnings() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      final response = await http.get(Uri.parse('$kBaseUrl/admin/earnings'));

      if (response.statusCode == 200) {
        setState(() => data = jsonDecode(response.body));
      } else {
        setState(() => errorMessage =
            'Server error ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      setState(() => errorMessage = 'Connection error: $e');
    }

    if (mounted) setState(() => isLoading = false);
  }

  String money(dynamic v) => '₹${((v ?? 0) as num).toStringAsFixed(2)}';

  @override
  Widget build(BuildContext context) {
    final recent = (data['recent'] ?? []) as List;

    return Scaffold(
      appBar: AppBar(title: const Text('Platform Earnings')),
      body: RefreshIndicator(
        onRefresh: fetchEarnings,
        child: isLoading
            ? listSkeleton()
            : errorMessage.isNotEmpty
                ? centerMessage(
                    errorMessage,
                    color: Colors.red,
                    icon: Icons.wifi_off,
                  )
                : ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF00695C), Color(0xFF26A69A)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Total Commission (Admin)',
                              style: TextStyle(color: Colors.white70),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              money(data['platform_earning']),
                              style: const TextStyle(
                                fontSize: 34,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      statCard(
                        'Commission on Delivered',
                        money(data['platform_delivered']),
                        Icons.check_circle,
                        Colors.blue,
                      ),
                      const SizedBox(height: 10),
                      statCard(
                        'Commission Pending',
                        money(data['platform_pending']),
                        Icons.hourglass_top,
                        Colors.orange,
                      ),
                      const SizedBox(height: 10),
                      statCard(
                        'Total Sales Volume',
                        money(data['total_sales']),
                        Icons.shopping_bag,
                        kPrimary,
                      ),
                      const SizedBox(height: 10),
                      statCard(
                        'Paid to Sellers',
                        money(data['seller_earning']),
                        Icons.store,
                        Colors.purple,
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Commission per Order',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      if (recent.isEmpty) const Text('No orders yet.'),
                      ...recent.map(
                        (o) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Card(
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor:
                                    kPrimary.withValues(alpha: 0.12),
                                child: const Icon(
                                  Icons.receipt,
                                  color: kPrimary,
                                ),
                              ),
                              title: Text('Order #${o['id']}'),
                              subtitle: Text(
                                'Status: ${o['status']} • Sale: ${money(o['sale'])}',
                              ),
                              trailing: Text(
                                '+${money(o['platform'])}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              ),
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

// ---------------- ADMIN USERS ----------------
class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  List users = [];
  bool isLoading = true;
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    fetchUsers();
  }

  Future<void> fetchUsers() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      final response = await http.get(Uri.parse('$kBaseUrl/admin/users'));

      if (response.statusCode == 200) {
        setState(() => users = jsonDecode(response.body));
      } else {
        setState(() => errorMessage =
            'Server error ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      setState(() => errorMessage = 'Connection error: $e');
    }

    if (mounted) setState(() => isLoading = false);
  }

  Color _roleColor(String role) {
    switch (role) {
      case 'admin':
        return Colors.purple;
      case 'seller':
        return kAccent;
      default:
        return kPrimary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('All Users')),
      body: RefreshIndicator(
        onRefresh: fetchUsers,
        child: isLoading
            ? listSkeleton()
            : errorMessage.isNotEmpty
                ? centerMessage(
                    errorMessage,
                    color: Colors.red,
                    icon: Icons.wifi_off,
                  )
                : users.isEmpty
                    ? centerMessage('No users found.', icon: Icons.people_outline)
                    : ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: users.length,
                        itemBuilder: (_, i) {
                          final u = users[i];
                          final phone = (u['phone'] ?? '').toString();
                          final name = (u['name'] ?? '').toString();
                          final role = (u['role'] ?? '').toString();
                          final color = _roleColor(role);

                          return Card(
                            margin: const EdgeInsets.only(bottom: 10),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 6,
                              ),
                              leading: CircleAvatar(
                                backgroundColor: color.withValues(alpha: 0.15),
                                child: Text(
                                  name.isNotEmpty ? name[0].toUpperCase() : '?',
                                  style: TextStyle(
                                    color: color,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              title: Text(
                                name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              subtitle: Text(
                                '${u['email']}${phone.isNotEmpty ? '\n$phone' : ''}',
                              ),
                              trailing: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: color.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  role,
                                  style: TextStyle(
                                    color: color,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              isThreeLine: phone.isNotEmpty,
                            ),
                          );
                        },
                      ),
      ),
    );
  }
}

// ---------------- ADMIN PRODUCTS ----------------
class AdminProductsScreen extends StatefulWidget {
  const AdminProductsScreen({super.key});

  @override
  State<AdminProductsScreen> createState() => _AdminProductsScreenState();
}

class _AdminProductsScreenState extends State<AdminProductsScreen> {
  List products = [];
  bool isLoading = true;
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    fetchProducts();
  }

  Future<void> fetchProducts() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      final response = await http.get(Uri.parse('$kBaseUrl/admin/products'));

      if (response.statusCode == 200) {
        setState(() => products = jsonDecode(response.body));
      } else {
        setState(() => errorMessage =
            'Server error ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      setState(() => errorMessage = 'Connection error: $e');
    }

    if (mounted) setState(() => isLoading = false);
  }

  Future<void> deleteProduct(int id) async {
    final ok = await confirmDialog(
      context,
      title: 'Delete Product?',
      message: 'Ye product hamesha ke liye hat jayega.',
      yes: 'Delete',
    );
    if (!ok) return;

    try {
      final response = await http.delete(
        Uri.parse('$kBaseUrl/admin/products/$id'),
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        snack(context, 'Product deleted');
        fetchProducts();
      } else {
        String err = 'Delete failed';
        try {
          err = jsonDecode(response.body)['error'] ?? err;
        } catch (_) {}
        snack(context, err);
      }
    } catch (_) {
      snack(context, 'Could not connect to server');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('All Products')),
      body: RefreshIndicator(
        onRefresh: fetchProducts,
        child: isLoading
            ? listSkeleton()
            : errorMessage.isNotEmpty
                ? centerMessage(
                    errorMessage,
                    color: Colors.red,
                    icon: Icons.wifi_off,
                  )
                : products.isEmpty
                    ? centerMessage(
                        'No products found.',
                        icon: Icons.inventory_2_outlined,
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: products.length,
                        itemBuilder: (_, i) {
                          final p = products[i];

                          return Card(
                            margin: const EdgeInsets.only(bottom: 10),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              leading: ProductImage(
                                path: p['image_url'],
                                width: 52,
                                height: 52,
                                fallback: Icons.inventory,
                              ),
                              title: Text(
                                p['name'] ?? '',
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              subtitle: Text(
                                '₹${p['price']} • ${p['listing_type'] ?? 'new'}',
                              ),
                              trailing: IconButton(
                                icon: const Icon(
                                  Icons.delete_outline,
                                  color: Colors.red,
                                ),
                                onPressed: () => deleteProduct(p['id']),
                              ),
                            ),
                          );
                        },
                      ),
      ),
    );
  }
}

// ---------------- ADMIN ORDERS ----------------
class AdminOrdersScreen extends StatefulWidget {
  const AdminOrdersScreen({super.key});

  @override
  State<AdminOrdersScreen> createState() => _AdminOrdersScreenState();
}

class _AdminOrdersScreenState extends State<AdminOrdersScreen> {
  List orders = [];
  bool isLoading = true;
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    fetchOrders();
  }

  Future<void> fetchOrders() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      final response = await http.get(Uri.parse('$kBaseUrl/admin/orders'));

      if (response.statusCode == 200) {
        setState(() => orders = jsonDecode(response.body));
      } else {
        setState(() => errorMessage =
            'Server error ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      setState(() => errorMessage = 'Connection error: $e');
    }

    if (mounted) setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('All Orders')),
      body: RefreshIndicator(
        onRefresh: fetchOrders,
        child: isLoading
            ? listSkeleton()
            : errorMessage.isNotEmpty
                ? centerMessage(
                    errorMessage,
                    color: Colors.red,
                    icon: Icons.wifi_off,
                  )
                : orders.isEmpty
                    ? centerMessage(
                        'No orders found.',
                        icon: Icons.receipt_long_outlined,
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: orders.length,
                        itemBuilder: (_, i) {
                          final o = orders[i];

                          return Card(
                            margin: const EdgeInsets.only(bottom: 10),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 8,
                              ),
                              leading: CircleAvatar(
                                backgroundColor:
                                    kPrimary.withValues(alpha: 0.12),
                                child: const Icon(
                                  Icons.receipt,
                                  color: kPrimary,
                                ),
                              ),
                              title: Text(
                                'Order #${o['id']}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    StatusChip(
                                      status: (o['status'] ?? '').toString(),
                                    ),
                                    const SizedBox(height: 4),
                                    Text('Total: ₹${o['total_amount']}'),
                                  ],
                                ),
                              ),
                              isThreeLine: true,
                            ),
                          );
                        },
                      ),
      ),
    );
  }
}

// ---------------- ADMIN VOUCHERS ----------------
class AdminVouchersScreen extends StatefulWidget {
  const AdminVouchersScreen({super.key});

  @override
  State<AdminVouchersScreen> createState() => _AdminVouchersScreenState();
}

class _AdminVouchersScreenState extends State<AdminVouchersScreen> {
  final codeController = TextEditingController();
  final valueController = TextEditingController();

  String discountType = 'percent';
  DateTime? expiry;
  bool isLoading = false;
  String message = '';
  String listError = '';

  List vouchers = [];

  @override
  void initState() {
    super.initState();
    fetchVouchers();
  }

  String _formatDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> pickExpiry() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now().add(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 730)),
    );
    if (picked != null) setState(() => expiry = picked);
  }

  Future<void> fetchVouchers() async {
    try {
      final response = await http.get(Uri.parse('$kBaseUrl/admin/vouchers'));

      if (!mounted) return;

      if (response.statusCode == 200) {
        setState(() {
          vouchers = jsonDecode(response.body);
          listError = '';
        });
      } else {
        setState(() => listError =
            'Vouchers load nahi hue (server error ${response.statusCode})');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => listError = 'Connection error: $e');
    }
  }

  Future<void> createVoucher() async {
    final code = codeController.text.trim().toUpperCase();
    final value = double.tryParse(valueController.text.trim());

    if (code.isEmpty || value == null || value <= 0) {
      setState(() {
        message = 'Valid code aur discount value daalo';
      });
      return;
    }
    if (discountType == 'percent' && value > 100) {
      setState(() {
        message = 'Percentage 100 se zyada nahi ho sakta';
      });
      return;
    }

    setState(() {
      isLoading = true;
      message = '';
    });

    String result;

    try {
      final body = <String, dynamic>{
        'code': code,
        'discount_type': discountType,
        'discount_value': value,
      };
      if (expiry != null) body['expiry_date'] = _formatDate(expiry!);

      final response = await http.post(
        Uri.parse('$kBaseUrl/admin/vouchers'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 201) {
        codeController.clear();
        valueController.clear();
        expiry = null;
        result = 'Voucher created!';
        fetchVouchers();
      } else {
        result = data['error'] ?? 'Failed to create voucher';
      }
    } catch (_) {
      result = 'Could not connect to server';
    }

    if (!mounted) return;
    setState(() {
      message = result;
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Vouchers')),
      body: RefreshIndicator(
        onRefresh: fetchVouchers,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    TextField(
                      controller: codeController,
                      textCapitalization: TextCapitalization.characters,
                      decoration: const InputDecoration(
                        labelText: 'Voucher Code',
                        prefixIcon: Icon(Icons.local_offer_outlined),
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: discountType,
                      items: const [
                        DropdownMenuItem(
                          value: 'percent',
                          child: Text('Percentage Discount'),
                        ),
                        DropdownMenuItem(
                          value: 'flat',
                          child: Text('Flat Discount'),
                        ),
                      ],
                      onChanged: (v) => setState(() => discountType = v!),
                      decoration: const InputDecoration(
                        labelText: 'Discount Type',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: valueController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: discountType == 'percent'
                            ? 'Discount %'
                            : 'Discount ₹',
                      ),
                    ),
                    const SizedBox(height: 12),
                    InkWell(
                      onTap: pickExpiry,
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Expiry Date (optional)',
                          suffixIcon: Icon(Icons.calendar_today),
                        ),
                        child: Text(
                          expiry == null
                              ? 'Default: 1 saal'
                              : _formatDate(expiry!),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: isLoading ? null : createVoucher,
                        child: isLoading
                            ? const SizedBox(
                                height: 22,
                                width: 22,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2.5,
                                ),
                              )
                            : const Text('Create Voucher'),
                      ),
                    ),
                    if (message.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: Text(
                          message,
                          style: TextStyle(
                            color: message.contains('created')
                                ? Colors.green
                                : Colors.red,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Existing Vouchers',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            if (listError.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  listError,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            const SizedBox(height: 8),
            ...vouchers.map(
              (v) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: kAccent.withValues(alpha: 0.15),
                      child: const Icon(Icons.local_offer, color: kAccent),
                    ),
                    title: Text(
                      v['code'] ?? '',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      '${v['discount_type']} • ${v['discount_value']}'
                      '${v['expiry_date'] != null ? ' • till ${v['expiry_date']}' : ''}',
                    ),
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