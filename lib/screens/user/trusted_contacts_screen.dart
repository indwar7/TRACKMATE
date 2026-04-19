import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:trackmate_app/controllers/profile_controller.dart';

class TrustedContactsScreen extends StatelessWidget {
  TrustedContactsScreen({super.key});

  // 🚨 Emergency contacts (static)
  final List<Map<String, String>> emergencyContacts = const [
    {
      "title": "Tourist Helpline",
      "phone": "1363 / 1800-111-363",
      "desc": "24x7 assistance for travellers in India"
    },
    {
      "title": "Women's Helpline",
      "phone": "1091 / 181",
      "desc": "Emergency support for women in distress"
    },
    {
      "title": "Child Helpline",
      "phone": "1098",
      "desc": "Help for children in need or danger"
    },
    {
      "title": "Highway Accident",
      "phone": "1073 / 1033",
      "desc": "Road accident & emergency help"
    },
    {
      "title": "Disaster Management (NDMA)",
      "phone": "1078",
      "desc": "National disaster response helpline"
    },
    {
      "title": "Railway Security",
      "phone": "1322",
      "desc": "Emergency help on railway stations"
    },
    {
      "title": "Railway Enquiry",
      "phone": "139",
      "desc": "Train schedule, booking & status"
    },
  ];

  @override
  Widget build(BuildContext context) {
    final ProfileController controller = Get.find<ProfileController>();

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),

      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          "Trusted Contacts",
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),

      body: Obx(() {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              /// =====================
              ///  EMERGENCY CONTACTS
              /// =====================
              const Text(
                "Emergency Helplines",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 12),

              Column(
                children: emergencyContacts.map((e) {
                  return _emergencyCard(
                    title: e["title"]!,
                    desc: e["desc"]!,
                    phone: e["phone"]!,
                  );
                }).toList(),
              ),

              const SizedBox(height: 30),

              /// =====================
              ///  USER TRUSTED CONTACTS
              /// =====================
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Your Trusted Contacts",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  TextButton(
                    onPressed: () => _showAddDialog(context, controller),
                    child: const Text(
                      "+ Add",
                      style: TextStyle(
                        color: Color(0xFF8B5CF6),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),

              controller.trustedContacts.isEmpty
                  ? _emptyState()
                  : _trustedContactsList(controller),
            ],
          ),
        );
      }),
    );
  }

  /// ===============================
  /// EMERGENCY CONTACT CARD
  /// ===============================
  Widget _emergencyCard({
    required String title,
    required String desc,
    required String phone,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF292D3E),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Icon(Icons.local_phone, color: Color(0xFF8B5CF6)),
          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  desc,
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),

          Text(
            phone,
            style: const TextStyle(
              color: Colors.greenAccent,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  /// ===============================
  /// EMPTY STATE
  /// ===============================
  Widget _emptyState() {
    return Container(
      padding: const EdgeInsets.all(40),
      alignment: Alignment.center,
      child: const Column(
        children: [
          Icon(Icons.people_outline, size: 70, color: Colors.white24),
          SizedBox(height: 12),
          Text(
            "No trusted contacts added",
            style: TextStyle(color: Colors.white54),
          ),
        ],
      ),
    );
  }

  /// ===============================
  /// TRUSTED CONTACT LIST
  /// ===============================
  Widget _trustedContactsList(ProfileController controller) {
    return Column(
      children: List.generate(controller.trustedContacts.length, (index) {
        final contact = controller.trustedContacts[index];

        final String name = (contact["name"] ?? "").toString();
        final String phone = (contact["phone"] ?? "").toString();

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF292D3E),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: const Color(0xFF8B5CF6).withValues(alpha: .3),
                child: Text(
                  name.isNotEmpty ? name[0].toUpperCase() : "?",
                  style: const TextStyle(color: Colors.white),
                ),
              ),

              const SizedBox(width: 14),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name.isEmpty ? "Unknown" : name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      phone.isEmpty ? "No number" : phone,
                      style: const TextStyle(
                        color: Colors.white60,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),

              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                onPressed: () => controller.removeTrustedContact(index),
              ),
            ],
          ),
        );
      }),
    );
  }

  /// ===============================
  /// ADD CONTACT DIALOG
  /// ===============================
  void _showAddDialog(
      BuildContext context, ProfileController controller) {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();

    Get.defaultDialog(
      title: "Add Trusted Contact",
      backgroundColor: const Color(0xFF292D3E),
      titleStyle: const TextStyle(color: Colors.white),
      content: Column(
        children: [
          _input(nameCtrl, "Enter name"),
          const SizedBox(height: 12),
          _input(phoneCtrl, "Enter phone number"),
        ],
      ),

      textConfirm: "Save",
      textCancel: "Cancel",
      buttonColor: const Color(0xFF8B5CF6),
      confirmTextColor: Colors.white,
      cancelTextColor: Colors.white70,

      onConfirm: () {
        final name = nameCtrl.text.trim();
        final phone = phoneCtrl.text.trim();

        if (name.isEmpty || phone.isEmpty) {
          Get.snackbar("Error", "Please fill all fields",
              backgroundColor: Colors.redAccent,
              colorText: Colors.white);
          return;
        }

        controller.addTrustedContact(name, phone);
        Get.back();
      },
    );
  }

  InputDecoration _inputDeco(String hint) => InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(color: Colors.white38),
    filled: true,
    fillColor: const Color(0xFF1B1E2D),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide.none,
    ),
  );

  Widget _input(TextEditingController ctrl, String hint) {
    return TextField(
      controller: ctrl,
      style: const TextStyle(color: Colors.white),
      decoration: _inputDeco(hint),
      keyboardType: hint.contains("phone")
          ? TextInputType.phone
          : TextInputType.text,
    );
  }
}
