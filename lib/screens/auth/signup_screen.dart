import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/loading_button.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _acceptTerms = false;

  // Constantes pour éviter les magic numbers
  static const double _horizontalPadding = 24.0;
  static const double _fieldSpacing = 20.0;
  static const double _sectionSpacing = 32.0;
  static const double _buttonSpacing = 24.0;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (!_acceptTerms) {
      _showTermsError();
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    final success = await authProvider.signUpWithEmail(
      email: _emailController.text.trim(),
      password: _passwordController.text,
      name: _nameController.text.trim(),
    );

    if (success && mounted) {
      Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => route.isFirst);
    }
  }

  Future<void> _signUpWithGoogle() async {
    if (!_acceptTerms) {
      _showTermsError();
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.signInWithGoogle();
    
    if (success && mounted) {
      Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => route.isFirst);
    }
  }

  void _showTermsError() {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Veuillez accepter les conditions d\'utilisation'),
        backgroundColor: Theme.of(context).colorScheme.error.withAlpha(26),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  void _togglePasswordVisibility() {
    setState(() => _obscurePassword = !_obscurePassword);
  }

  void _toggleConfirmPasswordVisibility() {
    setState(() => _obscureConfirmPassword = !_obscureConfirmPassword);
  }

  void _toggleTermsAcceptance() {
    setState(() => _acceptTerms = !_acceptTerms);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(_horizontalPadding),
          child: Consumer<AuthProvider>(
            builder: (context, authProvider, child) {
              return Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildBackButton(),
                    SizedBox(height: screenHeight * 0.03),
                    _buildHeader(theme),
                    SizedBox(height: screenHeight * 0.04),
                    _buildFormFields(),
                    const SizedBox(height: _fieldSpacing),
                    _buildTermsCheckbox(theme),
                    const SizedBox(height: _sectionSpacing),
                    _buildErrorMessage(authProvider, theme),
                    _buildSignUpButton(authProvider),
                    const SizedBox(height: _buttonSpacing),
                    _buildDivider(theme),
                    const SizedBox(height: _buttonSpacing),
                    _buildGoogleButton(authProvider),
                    SizedBox(height: screenHeight * 0.05),
                    _buildLoginLink(theme),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildBackButton() {
    return IconButton(
      onPressed: () => Navigator.pop(context),
      icon: const Icon(Icons.arrow_back_ios),
      padding: EdgeInsets.zero,
      tooltip: 'Retour',
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Créer un compte',
          style: theme.textTheme.displayMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Rejoignez Skillex et commencez votre parcours d\'apprentissage',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurface.withAlpha(179),
          ),
        ),
      ],
    );
  }

  Widget _buildFormFields() {
    return Column(
      children: [
        CustomTextField(
          controller: _nameController,
          label: 'Nom complet',
          keyboardType: TextInputType.name,
          prefixIcon: Icons.person_outline,
          validator: _validateName,
        ),
        const SizedBox(height: _fieldSpacing),
        CustomTextField(
          controller: _emailController,
          label: 'Adresse email',
          keyboardType: TextInputType.emailAddress,
          prefixIcon: Icons.email_outlined,
          validator: _validateEmail,
        ),
        const SizedBox(height: _fieldSpacing),
        CustomTextField(
          controller: _passwordController,
          label: 'Mot de passe',
          obscureText: _obscurePassword,
          prefixIcon: Icons.lock_outline,
          suffixIcon: IconButton(
            icon: Icon(
              _obscurePassword ? Icons.visibility_off : Icons.visibility,
            ),
            onPressed: _togglePasswordVisibility,
            tooltip: _obscurePassword ? 'Afficher le mot de passe' : 'Masquer le mot de passe',
          ),
          validator: _validatePassword,
        ),
        const SizedBox(height: _fieldSpacing),
        CustomTextField(
          controller: _confirmPasswordController,
          label: 'Confirmer le mot de passe',
          obscureText: _obscureConfirmPassword,
          prefixIcon: Icons.lock_outline,
          suffixIcon: IconButton(
            icon: Icon(
              _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
            ),
            onPressed: _toggleConfirmPasswordVisibility,
            tooltip: _obscureConfirmPassword ? 'Afficher le mot de passe' : 'Masquer le mot de passe',
          ),
          validator: _validateConfirmPassword,
        ),
      ],
    );
  }

  Widget _buildTermsCheckbox(ThemeData theme) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Checkbox(
          value: _acceptTerms,
          onChanged: (value) => _toggleTermsAcceptance(),
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        Expanded(
          child: GestureDetector(
            onTap: _toggleTermsAcceptance,
            child: Padding(
              padding: const EdgeInsets.only(top: 12),
              child: RichText(
                text: TextSpan(
                  style: theme.textTheme.bodyMedium,
                  children: [
                    const TextSpan(text: 'J\'accepte les '),
                    _buildLinkText(theme, 'conditions d\'utilisation'),
                    const TextSpan(text: ' et la '),
                    _buildLinkText(theme, 'politique de confidentialité'),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  TextSpan _buildLinkText(ThemeData theme, String text) {
    return TextSpan(
      text: text,
      style: TextStyle(
        color: theme.colorScheme.primary,
        fontWeight: FontWeight.w500,
        decoration: TextDecoration.underline,
      ),
    );
  }

  Widget _buildErrorMessage(AuthProvider authProvider, ThemeData theme) {
    if (authProvider.errorMessage == null) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: theme.colorScheme.error.withAlpha(26),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.error.withAlpha(77),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.error_outline,
            color: theme.colorScheme.error,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              authProvider.errorMessage!,
              style: TextStyle(
                color: theme.colorScheme.error,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSignUpButton(AuthProvider authProvider) {
    return LoadingButton(
      onPressed: _signUp,
      isLoading: authProvider.isLoading,
      text: 'Créer un compte',
    );
  }

  Widget _buildDivider(ThemeData theme) {
    return Row(
      children: [
        Expanded(child: Divider(color: Colors.grey.shade300)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'ou',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.grey.shade600,
            ),
          ),
        ),
        Expanded(child: Divider(color: Colors.grey.shade300)),
      ],
    );
  }

  Widget _buildGoogleButton(AuthProvider authProvider) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: authProvider.isLoading ? null : _signUpWithGoogle,
        icon: Image.asset(
          'assets/images/google_logo.png',
          height: 20,
          errorBuilder: (context, error, stackTrace) => const Icon(Icons.g_mobiledata),
        ),
        label: Text(
          'Continuer avec Google',
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          side: BorderSide(color: Colors.grey.shade300),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Widget _buildLoginLink(ThemeData theme) {
    return Center(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Déjà un compte ? ',
            style: theme.textTheme.bodyMedium,
          ),
          TextButton(
            onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
            child: Text(
              'Se connecter',
              style: TextStyle(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Validators séparés pour une meilleure lisibilité
  String? _validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Veuillez entrer votre nom';
    }
    if (!AuthProvider.isNameValid(value)) {
      return 'Le nom doit contenir au moins 2 caractères';
    }
    return null;
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Veuillez entrer votre email';
    }
    if (!AuthProvider.isEmailValid(value)) {
      return 'Adresse email invalide';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Veuillez entrer un mot de passe';
    }
    if (!AuthProvider.isPasswordValid(value)) {
      return 'Le mot de passe doit contenir au moins 6 caractères';
    }
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Veuillez confirmer votre mot de passe';
    }
    if (value != _passwordController.text) {
      return 'Les mots de passe ne correspondent pas';
    }
    return null;
  }
}