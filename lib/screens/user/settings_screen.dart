import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:trackmate_app/controllers/profile_controller.dart';
import 'package:trackmate_app/controllers/language_controller.dart';
import 'package:trackmate_app/services/api_service.dart';
import 'package:trackmate_app/screens/auth/login_screen.dart';
import 'package:trackmate_app/screens/user/invite_friends_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ProfileController profileController = Get.find<ProfileController>();
    final LanguageController languageController = Get.put(LanguageController());

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Get.back(),
        ),
        title: const Text(
          'Settings',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 20),

            // ------------------ SHORTCUTS ------------------
            _buildSectionHeader('Shortcuts'),

            Obx(() => _buildSettingsTile(
              icon: Icons.language,
              title: 'Language',
              subtitle: languageController
                  .getLanguageByCode(languageController.getCurrentLanguage())
                  ?.name ??
                  'English',
              onTap: () => _showLanguageDialog(context, languageController),
            )),

            Obx(() => _buildSettingsTile(
              icon: Icons.home,
              title: 'Home',
              subtitle: profileController.homeLocation.value.isEmpty
                  ? 'Add Shortcut'
                  : profileController.homeLocation.value,
              onTap: () => _showAddLocationDialog(
                context,
                'Home',
                profileController.homeLocation.value,
                    (value) => profileController.updateProfile(newHomeLocation: value),
              ),
            )),

            Obx(() => _buildSettingsTile(
              icon: Icons.work,
              title: 'Work',
              subtitle: profileController.workLocation.value.isEmpty
                  ? 'Add Shortcut'
                  : profileController.workLocation.value,
              onTap: () => _showAddLocationDialog(
                context,
                'Work',
                profileController.workLocation.value,
                    (value) => profileController.updateProfile(newWorkLocation: value, newHomeLocation: ''),
              ),
            )),

            const SizedBox(height: 20),

            // ------------------ DOCUMENT ------------------
            _buildSectionHeader('Document'),

            _buildSettingsTile(
              icon: Icons.verified_user,
              title: 'Verification',
              onTap: () => Get.toNamed('/user-verification'),
            ),

            _buildSettingsTile(
              icon: Icons.shield_outlined,
              title: 'Status',
              onTap: () => Get.toNamed('/id-status'),
            ),

            _buildSettingsTile(
              icon: Icons.directions_car,
              title: 'Add a new vehicle',
              onTap: () => Get.toNamed('/vehicle-info'),
            ),

            Obx(() => _buildSettingsTile(
              icon: Icons.history,
              title: 'Saved vehicle data',
              subtitle: profileController.vehicleNumber.value.isNotEmpty
                  ? '${profileController.vehicleNumber.value} - ${profileController.vehicleModel.value}'
                  : 'No vehicle added',
              onTap: () => Get.toNamed('/vehicle-info'),
            )),

            const SizedBox(height: 20),

            // ------------------ SAFETY ------------------
            _buildSectionHeader('Safety'),

            _buildSettingsTile(
              icon: Icons.security,
              title: 'Safety-tools',
              onTap: () => Get.toNamed('/safety-tools'),
            ),

            _buildSettingsTile(
              icon: Icons.gavel,
              title: 'Legal',
              onTap: () => Get.toNamed('/terms'),
            ),
            _buildSettingsTile(
              icon: Icons.person_add,
              title: 'Invite Friends',
              onTap: () => Get.to(() => const InviteFriendsScreen()),
            ),
            const SizedBox(height: 20),

            // ------------------ LOGOUT ------------------
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Get.defaultDialog(
                    title: 'Logout',
                    titleStyle: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                    backgroundColor: const Color(0xFF2A2A3E),
                    middleText: 'Are you sure you want to logout?',
                    middleTextStyle: const TextStyle(color: Colors.white70),
                    textConfirm: 'Logout',
                    textCancel: 'Cancel',
                    confirmTextColor: Colors.white,
                    cancelTextColor: Colors.white,
                    buttonColor: Colors.red,
                    onConfirm: () {
                      _handleLogout(context);
                    },
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Log out',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // ------------------------------------------------------------ LOGOUT HANDLER

  void _handleLogout(BuildContext context) async {
    // Close confirmation dialog
    Get.back();

    // Show loading indicator
    Get.dialog(
      const Center(
        child: CircularProgressIndicator(
          color: Color(0xFF8B5CF6),
        ),
      ),
      barrierDismissible: false,
    );

    // Get ApiService from Provider
    final apiService = context.read<ApiService>();

    // Call logout API (always succeeds, clears tokens)
    await apiService.logout();

    // Close loading indicator
    Get.back();

    // Navigate to login screen and clear all routes
    Get.offAll(() => const LoginScreen());

    // Show success message
    Get.snackbar(
      'Logged Out',
      'You have been successfully logged out',
      backgroundColor: Colors.green,
      colorText: Colors.white,
      snackPosition: SnackPosition.BOTTOM,
      margin: const EdgeInsets.all(16),
      duration: const Duration(seconds: 2),
    );
  }

  // ------------------------------------------------------------ UI HELPERS

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.2,
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF2A2A3E),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF8B5CF6).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: const Color(0xFF8B5CF6), size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w500)),
                  if (subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style:
                      const TextStyle(color: Colors.white60, fontSize: 13),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    )
                  ],
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios,
                color: Colors.white54, size: 16),
          ],
        ),
      ),
    );
  }

  // ------------------------------------------------------------ LANGUAGE DIALOG
  void _showLanguageDialog(BuildContext context, LanguageController controller) {
    Get.dialog(
      AlertDialog(
        backgroundColor: const Color(0xFF2A2A3E),
        title: const Text('Select Language',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: controller.supportedLanguages.length,
            itemBuilder: (context, index) {
              final language = controller.supportedLanguages[index];
              return Obx(() => RadioListTile<String>(
                title: Text(language.name,
                    style: const TextStyle(color: Colors.white)),
                value: language.code,
                groupValue: controller.getCurrentLanguage(),
                activeColor: const Color(0xFF8B5CF6),
                onChanged: (value) {
                  if (value != null) {
                    controller.changeLanguage(value);
                    Get.back();
                  }
                },
              ));
            },
          ),
        ),
      ),
    );
  }

  // ------------------------------------------------------------ ADD LOCATION DIALOG
  void _showAddLocationDialog(
      BuildContext context,
      String type,
      String currentValue,
      Function(String) onSave,
      ) {
    final TextEditingController locationController =
    TextEditingController(text: currentValue);

    Get.dialog(
      AlertDialog(
        backgroundColor: const Color(0xFF2A2A3E),
        title: Text('Add $type',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: locationController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Enter $type location',
                hintStyle: const TextStyle(color: Colors.white38),
                filled: true,
                fillColor: const Color(0xFF1A1A2E),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                  const BorderSide(color: Color(0xFF8B5CF6), width: 1.5),
                ),
              ),
            ),
            const SizedBox(height: 16),

            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Get.back(),
                  child:
                  const Text('Cancel', style: TextStyle(color: Colors.white70)),
                ),
                const SizedBox(width: 8),

                ElevatedButton(
                  onPressed: () {
                    if (locationController.text.trim().isNotEmpty) {
                      onSave(locationController.text.trim());
                      Get.back();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF8B5CF6),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8))),
                  child:
                  const Text('Save', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}