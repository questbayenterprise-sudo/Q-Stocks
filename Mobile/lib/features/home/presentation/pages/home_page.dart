import 'package:flutter/material.dart';
import '../../../auth/Session/user_session.dart';
import 'admin_home_page.dart';
import 'owner_home_page.dart';
import 'user_home_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final userType = UserSession().userType;

    // Admin: full access — all data, all turfs, all bookings
    if (userType == UserType.admin) {
      return AdminHomePage();
    }

    // Owner/Vendor/Manager: own turfs, own bookings, own analytics
    if (userType == UserType.owner ||
        userType == UserType.vendor ||
        userType == UserType.manager) {
      return const OwnerHomePage();
    }

    // User/Guest: browse venues, make bookings
    return const UserHomePage();
  }
}
