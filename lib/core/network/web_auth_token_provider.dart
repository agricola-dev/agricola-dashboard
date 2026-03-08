import 'package:agricola_core/agricola_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Web-specific [AuthTokenProvider] implementation.
/// Reads Firebase JWT from the currently signed-in user.
class WebAuthTokenProvider implements AuthTokenProvider {
  @override
  Future<String?> getToken() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;
    return user.getIdToken();
  }
}
