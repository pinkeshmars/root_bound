import 'package:flutter/material.dart';
import 'package:rootbound/auth/supabase_auth_manager.dart';
import 'package:rootbound/screens/auth/login_page.dart';
import 'package:rootbound/screens/home_page.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: SupabaseAuthManager().authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        
        if (snapshot.hasData && snapshot.data != null) {
          return const HomePage();
        }
        
        return const LoginPage();
      },
    );
  }
}
