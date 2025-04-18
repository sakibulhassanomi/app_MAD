import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:myapp/admin/admin_product_management.dart';
import 'package:myapp/models/transactions_model.dart';
import 'package:myapp/pages/auth/cart_page.dart';
import 'package:myapp/pages/auth/login_page.dart';
import 'package:myapp/pages/auth/signup_page.dart';
import 'package:myapp/pages/dashboard/admin_dashboard.dart';
import 'package:myapp/pages/dashboard/consumer_dashboard.dart';
import 'package:myapp/pages/product/product_list_page.dart';
import 'package:myapp/pages/profile/edit_profile_page.dart';
import 'package:myapp/pages/profile/view_profile_page.dart';
import 'package:myapp/pages/services/auth_service.dart';
import 'package:myapp/pages/services/cart_service.dart';
import 'package:myapp/pages/services/oder_service.dart';
import 'package:myapp/pages/services/product_service.dart';
import 'package:myapp/pages/services/user_service.dart';
import 'package:myapp/pages/transaction/bkash_payment.dart';
import 'package:myapp/pages/transaction/nagad_payment.dart';
import 'package:myapp/pages/transaction/payment_page.dart';
import 'package:myapp/pages/transaction/transaction_page.dart';
import 'package:provider/provider.dart';


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: "AIzaSyC2AZ6JrkUxk4dWyGuSpbpSDn_ieEVrZZU",
      authDomain: "e-commerce-web-64c97.firebaseapp.com",
      projectId: "e-commerce-web-64c97",
      storageBucket: "e-commerce-web-64c97.appspot.com",
      messagingSenderId: "748378438239",
      appId: "1:748378438239:web:9ce1dd9052baf4514af9ea",
      measurementId: "G-9QHC0W3DXM",
    ),
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        ChangeNotifierProvider(create: (_) => ProductService()),
        Provider(create: (_) => OrderService()),
        Provider(create: (_) => CartService()),
        Provider(create: (_) => UserService()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  Future<Widget> getStartScreen() async {
    final auth = FirebaseAuth.instance;
    final user = auth.currentUser;

    if (user == null) {
      return const LoginPage();
    }

    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    final role = userDoc.data()?['role'] ?? 'consumer';

    return role == 'admin'
        ? const AdminDashboard()
        : const ConsumerDashboard();
  }

  @override
  Widget build(BuildContext context) {
    const defaultProductCategories = [
      'Vegetables',
      'Fruits',
      'Grains',
      'Dairy',
      'Meat',
      'Poultry',
      'Seafood',
      'Herbs',
      'Spices',
      'Processed Foods'
    ];

    return MaterialApp(
      title: 'AGRO SHEBA',
      theme: ThemeData(
        primarySwatch: Colors.green,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        appBarTheme: const AppBarTheme(
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
      ),
      debugShowCheckedModeBanner: false,
      home: FutureBuilder<Widget>(
        future: getStartScreen(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            );
          }
          return snapshot.data ?? const LoginPage();
        },
      ),
      routes: {
        '/login': (context) => const LoginPage(),
        '/signup': (context) => const SignupPage(),
        '/adminDashboard': (context) => const AdminDashboard(),
        '/consumerDashboard': (context) => const ConsumerDashboard(),
        '/profile': (context) => const ViewProfilePage(),
        '/editProfile': (context) => const EditProfilePage(initialData: {}),
        '/productList': (context) => ProductListPage(
          productCategories: defaultProductCategories,
          isAdminView: false,
        ),
        '/cart': (context) => const CartPage(),
        '/adminProducts': (context) => const AdminProductManagement(),
        
      },
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/payment':
            final transaction = settings.arguments as TransactionModel;
            return MaterialPageRoute(
              builder: (_) => PaymentPage(transaction: transaction),
            );
          case '/bkash':
            final transaction = settings.arguments as TransactionModel;
            return MaterialPageRoute(
              builder: (_) => BkashPaymentPage(transaction: transaction),
            );
          case '/nagad':
            final transaction = settings.arguments as TransactionModel;
            return MaterialPageRoute(
              builder: (_) => NagadPaymentPage(transaction: transaction),
            );
          case '/transactions':
            final args = settings.arguments as Map<String, String>;
            return MaterialPageRoute(
              builder: (_) => TransactionPage(
                userId: args['userId']!,
                userType: args['userType']!,
              ),
            );
          case '/productList':
            final args = settings.arguments as Map<String, dynamic>? ?? {};
            return MaterialPageRoute(
              builder: (_) => ProductListPage(
                productCategories:
                    args['categories'] ?? defaultProductCategories,
                isAdminView: args['isAdminView'] ?? false,
              ),
            );
          default:
            return MaterialPageRoute(
              builder: (_) => const LoginPage(),
            );
        }
      },
      onUnknownRoute: (settings) => MaterialPageRoute(
        builder: (context) => const LoginPage(),
      ),
    );
  }
}
