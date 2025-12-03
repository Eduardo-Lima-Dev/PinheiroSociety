import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/repositories/repositories.dart';
import 'verify_code_screen.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleForgotPassword() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      final email = _emailController.text.trim();
      print('🔵 [FORGOT PASSWORD] Iniciando solicitação para: $email');

      try {
        print('🔵 [FORGOT PASSWORD] Chamando AuthRepository.forgotPassword...');
        final result = await AuthRepository.forgotPassword(
          email: email,
        );

        print('🟢 [FORGOT PASSWORD] Resultado recebido:');
        print('   - success: ${result['success']}');
        print('   - error: ${result['error']}');
        print('   - data: ${result['data']}');
        print('   - Resultado completo: $result');

        setState(() {
          _isLoading = false;
        });

        if (result['success']) {
          print('✅ [FORGOT PASSWORD] Sucesso! Email enviado.');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Email enviado com sucesso! Verifique sua caixa de entrada.',
                ),
                backgroundColor: Colors.green,
              ),
            );
            // Navegar para tela de verificação de código
            Future.delayed(const Duration(seconds: 1), () {
              if (mounted) {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (context) => VerifyCodeScreen(
                      email: email,
                    ),
                  ),
                );
              }
            });
          }
        } else {
          print('❌ [FORGOT PASSWORD] Erro na resposta: ${result['error']}');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(result['error'] ?? 'Erro ao enviar email'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } catch (e, stackTrace) {
        print('🔴 [FORGOT PASSWORD] Exceção capturada:');
        print('   - Erro: $e');
        print('   - Tipo: ${e.runtimeType}');
        print('   - StackTrace: $stackTrace');

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
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final containerWidth = isMobile ? screenWidth - 40 : 400.0;

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
                // Header com logo e botão voltar
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      Expanded(
                        child: Center(
                          child: Image.asset(
                            'assets/images/Logo.png',
                            height: isMobile ? 50 : 60,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                      const SizedBox(width: 48), // Balancear o botão voltar
                    ],
                  ),
                ),

                const Spacer(),

                // Formulário de esqueci minha senha centralizado
                Center(
                  child: SingleChildScrollView(
                    child: Container(
                      width: containerWidth,
                      margin: const EdgeInsets.symmetric(horizontal: 20),
                      padding: EdgeInsets.all(isMobile ? 20 : 30),
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
                          // Título
                          Text(
                            'Esqueci minha senha',
                            style: GoogleFonts.poppins(
                              fontSize: isMobile ? 24 : 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 15),
                          Text(
                            'Digite seu email para receber o código de redefinição de senha',
                            style: GoogleFonts.poppins(
                              fontSize: isMobile ? 13 : 14,
                              color: Colors.grey[400],
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 30),

                          // Campo de Email
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Email',
                                style: GoogleFonts.poppins(
                                  fontSize: isMobile ? 14 : 16,
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
                                  if (!RegExp(
                                          r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                                      .hasMatch(value)) {
                                    return 'Por favor, insira um email válido';
                                  }
                                  return null;
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 25),

                          // Botão Enviar
                          SizedBox(
                            width: double.infinity,
                            height: isMobile ? 48 : 50,
                            child: ElevatedButton(
                              onPressed:
                                  _isLoading ? null : _handleForgotPassword,
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
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                          Colors.white,
                                        ),
                                      ),
                                    )
                                  : Text(
                                      'Enviar',
                                      style: GoogleFonts.poppins(
                                        fontSize: isMobile ? 14 : 16,
                                        fontWeight: FontWeight.w600,
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

                const Spacer(),

                // Footer
                Padding(
                  padding: EdgeInsets.all(isMobile ? 15 : 20.0),
                  child: Text(
                    'Arena Pinheiro Society All Rights Reserved. Privacy Policy | Terms of Service.',
                    style: GoogleFonts.poppins(
                      fontSize: isMobile ? 10 : 12,
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

