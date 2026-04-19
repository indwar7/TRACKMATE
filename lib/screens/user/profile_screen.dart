import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:trackmate_app/controllers/profile_controller.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ProfileController controller = Get.find<ProfileController>();

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Profile',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white),
            onPressed: () => Get.toNamed('/settings'),
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(
            child: CircularProgressIndicator(
              color: Color(0xFF8B5CF6),
            ),
          );
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              // Profile Picture
              Center(
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 60,
                      backgroundColor: const Color(0xFF8B5CF6).withValues(alpha: 0.2),
                      backgroundImage: controller.profileImage.value.isNotEmpty
                          ? NetworkImage(controller.profileImage.value)
                          : null,
                      child: controller.profileImage.value.isEmpty
                          ? const Icon(
                        Icons.person,
                        size: 60,
                        color: Color(0xFF8B5CF6),
                      )
                          : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: () => Get.toNamed('/edit-profile'),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            color: Color(0xFF8B5CF6),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.edit,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Name
              Text(
                controller.name.value.isNotEmpty
                    ? controller.name.value
                    : 'No Name',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),

              // Email
              Text(
                controller.email.value.isNotEmpty
                    ? controller.email.value
                    : 'No Email',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 32),

              // Profile Info Cards
              _buildInfoCard(
                icon: Icons.phone,
                label: 'Phone',
                value: controller.phone.value.isNotEmpty
                    ? controller.phone.value
                    : 'Not set',
              ),
              _buildInfoCard(
                icon: Icons.cake,
                label: 'Date of Birth',
                value: controller.dateOfBirth.value.isNotEmpty
                    ? controller.dateOfBirth.value
                    : 'Not set',
              ),
              _buildInfoCard(
                icon: Icons.person_outline,
                label: 'Gender',
                value: controller.gender.value.isNotEmpty
                    ? controller.gender.value
                    : 'Not set',
              ),
              _buildInfoCard(
                icon: Icons.bloodtype,
                label: 'Blood Group',
                value: controller.bloodGroup.value.isNotEmpty
                    ? controller.bloodGroup.value
                    : 'Not set',
              ),
              _buildInfoCard(
                icon: Icons.location_on,
                label: 'Address',
                value: controller.address.value.isNotEmpty
                    ? controller.address.value
                    : 'Not set',
              ),
              _buildInfoCard(
                icon: Icons.emergency,
                label: 'Emergency Contact',
                value: controller.emergencyContact.value.isNotEmpty
                    ? controller.emergencyContact.value
                    : 'Not set',
              ),
              const SizedBox(height: 24),

              // Action Buttons
              _buildActionButton(
                icon: Icons.contacts,
                label: 'Trusted Contacts',
                onTap: () => Get.toNamed('/trusted-contacts'),
              ),
              _buildActionButton(
                icon: Icons.directions_car,
                label: 'Vehicle Information',
                onTap: () => Get.toNamed('/vehicle-info'),
              ),
              _buildActionButton(
                icon: Icons.verified_user,
                label: 'User Verification',
                onTap: () => Get.toNamed('/user-verification'),
              ),
              const SizedBox(height: 24),

              // Edit Profile Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () => Get.toNamed('/edit-profile'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8B5CF6),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'Edit Profile',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A3E),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF8B5CF6).withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: const Color(0xFF8B5CF6),
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: const Color(0xFF2A2A3E),
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: const Color(0xFF8B5CF6),
                  size: 24,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.white54,
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}


class UserProfileScreen extends StatelessWidget {
  const UserProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("User Profile"),
      ),
      body: const Center(
        child: Text(
          "This is the User Profile Screen",
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
