import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController emailC = TextEditingController();
  final TextEditingController passC = TextEditingController();

  bool loading = false;
  bool isPasswordHidden = true;

  @override
  void dispose() {
    emailC.dispose();
    passC.dispose();
    super.dispose();
  }

  //  Login Function
  Future<void> login() async {
    if (emailC.text.trim().isEmpty || passC.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(" Fill Email and Password ")),
      );
      return;
    }

    try {
      setState(() => loading = true);

      final userCred = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailC.text.trim(),
        password: passC.text.trim(),
      );

      //  Reload latest user data
      await userCred.user!.reload();
      final user = FirebaseAuth.instance.currentUser;

      //  Email verification check
      if (user != null && user.emailVerified == false) {
        setState(() => loading = false);

        //  Resend verification email (optional)
        await user.sendEmailVerification();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(" Email is not verify ! Please Gmail check  "),
          ),
        );

        await FirebaseAuth.instance.signOut();
        return;
      }

      setState(() => loading = false);

      //  Redirect Screen
      Navigator.pushReplacementNamed(context, "/redirect");
    } on FirebaseAuthException catch (e) {
      setState(() => loading = false);

      String msg = "Login Failed!";
      if (e.code == "user-not-found") {
        msg = " User-not-found! Please Signup ";
      } else if (e.code == "wrong-password") {
        msg = " Password is Wrong ";
      } else if (e.code == "invalid-email") {
        msg = " Invalid Email";
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg)),
      );
    } catch (e) {
      setState(() => loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(" Error: $e")),
      );
    }
  }

  //  Forgot Password
  Future<void> forgotPassword() async {
    if (emailC.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(" First Write Email ")),
      );
      return;
    }

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(
        email: emailC.text.trim(),
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(" Password reset email sent!")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(" Error: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Login"),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 20),

              const Icon(Icons.lock, size: 80),
              const SizedBox(height: 10),

              const Text(
                "Welcome Back 👋",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),

              //  Email
              TextField(
                controller: emailC,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: "Email",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email),
                ),
              ),
              const SizedBox(height: 15),

              //  Password
              TextField(
                controller: passC,
                obscureText: isPasswordHidden,
                decoration: InputDecoration(
                  labelText: "Password",
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.lock),
                  suffixIcon: IconButton(
                    icon: Icon(
                      isPasswordHidden
                          ? Icons.visibility_off
                          : Icons.visibility,
                    ),
                    onPressed: () {
                      setState(() => isPasswordHidden = !isPasswordHidden);
                    },
                  ),
                ),
              ),

              const SizedBox(height: 8),

              //  Forgot Password
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: forgotPassword,
                  child: const Text("Forgot Password?"),
                ),
              ),

              const SizedBox(height: 10),

              //  Login Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: loading ? null : login,
                  child: loading
                      ? const CircularProgressIndicator()
                      : const Text("Login"),
                ),
              ),

              const SizedBox(height: 15),

              //  Signup Redirect
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Don't have an account? "),
                  TextButton(
                    onPressed: () {
                      Navigator.pushReplacementNamed(context, "/signup");
                    },
                    child: const Text("Sign Up"),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
