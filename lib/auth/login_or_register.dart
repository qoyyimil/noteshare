import 'package:flutter/material.dart';
import 'package:noteshare/screens/login_screen.dart';
import 'package:noteshare/screens/register_screen.dart';

class LoginOrRegister extends StatefulWidget {
  final bool initialIsLogin;

  const LoginOrRegister({
    super.key,
    this.initialIsLogin = true, 
  });

  @override
  _LoginOrRegisterState createState() => _LoginOrRegisterState();
}

class _LoginOrRegisterState extends State<LoginOrRegister> {
  late bool showLoginPage;

  @override
  void initState() {
    super.initState();
    showLoginPage = widget.initialIsLogin;
  }


  void togglePages() {
    setState(() {
      showLoginPage = !showLoginPage;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (showLoginPage) {
      return LoginScreen(onTap: togglePages);
    } else {
      return RegisterScreen(onTap: togglePages);
    }
  }
}