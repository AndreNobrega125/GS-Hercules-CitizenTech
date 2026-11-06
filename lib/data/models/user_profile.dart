import '../../core/territory.dart';

/// Perfil de um gestor. Dados públicos de demonstração, sem informação pessoal real.
class UserProfile {
  const UserProfile({
    required this.id,
    required this.name,
    required this.role,
    required this.email,
    required this.home,
    required this.defaultFavorites,
  });

  final String id;
  final String name;
  final String role;
  final String email;

  /// Município que o perfil abre no primeiro acesso.
  final Territory home;

  /// Favoritos iniciais (o usuário pode alterá-los depois).
  final List<Territory> defaultFavorites;
}
