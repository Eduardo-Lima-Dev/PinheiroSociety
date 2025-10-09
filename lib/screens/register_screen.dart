import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        // Fazer cadastro via API
        final result = await ApiService.register(
          name: _nameController.text.trim(),
          email: _emailController.text.trim(),
          password: _passwordController.text,
          role: 'ADMIN',
        );

        setState(() {
          _isLoading = false;
        });

        if (result['success']) {
          // Cadastro bem-sucedido - mostrar mensagem e voltar ao login
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Cadastro realizado com sucesso!'),
                backgroundColor: Colors.green,
              ),
            );
            Navigator.of(context).pop(); // Volta para a tela anterior (login)
          }
        } else {
          // Erro no cadastro
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(result['error'] ?? 'Erro no cadastro'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } catch (e) {
        setState(() {
          _isLoading = false;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erro inesperado: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background do campo de futebol
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/Fundo_Login.png'),
                fit: BoxFit.cover,
              ),
            ),
          ),

          // Conteúdo principal
          SafeArea(
            child: Column(
              children: [
                // Header com botão voltar e logo
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Botão voltar
                      IconButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        icon: const Icon(
                          Icons.arrow_back,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      
                      // Logo ARENA PINHEIRO SOCIETY
                      Image.asset(
                        'assets/images/Logo.png',
                        height: 60,
                        fit: BoxFit.contain,
                      ),
                    ],
                  ),
                ),

                const Spacer(),

                // Formulário de cadastro centralizado
                Center(
                  child: Container(
                    width: 400,
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    padding: const EdgeInsets.all(30),
                    decoration: BoxDecoration(
                      color: Colors.grey[900]!.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Título Cadastro
                          Text(
                            'Cadastro',
                            style: GoogleFonts.poppins(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 30),

                          // Campo de Nome
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Nome',
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _nameController,
                                keyboardType: TextInputType.name,
                                style: const TextStyle(color: Colors.white),
                                decoration: InputDecoration(
                                  hintText: 'João da Silva',
                                  hintStyle: TextStyle(color: Colors.grey[400]),
                                  filled: true,
                                  fillColor: Colors.grey[800],
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide.none,
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 16,
                                  ),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Por favor, insira seu nome';
                                  }
                                  if (value.length < 2) {
                                    return 'O nome deve ter pelo menos 2 caracteres';
                                  }
                                  return null;
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // Campo de Email
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Email',
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                style: const TextStyle(color: Colors.white),
                                decoration: InputDecoration(
                                  hintText: 'exemplo@exemplo.com',
                                  hintStyle: TextStyle(color: Colors.grey[400]),
                                  filled: true,
                                  fillColor: Colors.grey[800],
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide.none,
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 16,
                                  ),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Por favor, insira seu email';
                                  }
                                  if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                                      .hasMatch(value)) {
                                    return 'Por favor, insira um email válido';
                                  }
                                  return null;
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // Campo de Senha
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Senha',
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _passwordController,
                                obscureText: !_isPasswordVisible,
                                style: const TextStyle(color: Colors.white),
                                decoration: InputDecoration(
                                  hintText: 'Senha123',
                                  hintStyle: TextStyle(color: Colors.grey[400]),
                                  filled: true,
                                  fillColor: Colors.grey[800],
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide.none,
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 16,
                                  ),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _isPasswordVisible
                                          ? Icons.visibility_off
                                          : Icons.visibility,
                                      color: Colors.grey[400],
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _isPasswordVisible = !_isPasswordVisible;
                                      });
                                    },
                                  ),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Por favor, insira sua senha';
                                  }
                                  if (value.length < 6) {
                                    return 'A senha deve ter pelo menos 6 caracteres';
                                  }
                                  return null;
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 25),

                          // Botão Cadastrar
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _handleRegister,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                elevation: 0,
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(
                                          Colors.white,
                                        ),
                                      ),
                                    )
                                  : Text(
                                      'Cadastrar',
                                      style: GoogleFonts.poppins(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Link para fazer login
                          Text(
                            'Já tem uma conta?',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 8),
                          GestureDetector(
                            onTap: () {
                              Navigator.of(context).pop(); // Volta para login
                            },
                            child: Text(
                              'Fazer login',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: Colors.green,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const Spacer(),

                // Footer
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Text(
                    'Arena Pinheiro Society All Rights Reserved. Privacy Policy | Terms of Service.',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.white70,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
