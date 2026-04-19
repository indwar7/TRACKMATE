// 📌 lib/screens/user/edit_profile_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:trackmate_app/controllers/profile_controller.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final ProfileController profile = Get.find<ProfileController>();

  final ImagePicker _picker = ImagePicker();
  File? pickedImage;

  late TextEditingController name;
  late TextEditingController phone;
  late TextEditingController dob;
  late TextEditingController address;
  late TextEditingController emergency;

  String? gender;
  String? blood;

  final genderOptions = ['Male', 'Female', 'Other', 'Prefer not to say'];
  final bloodGroups = ['A+', 'A-', 'B+', 'B-', 'O+', 'O-', 'AB+', 'AB-'];

  @override
  void initState() {
    super.initState();

    name = TextEditingController(text: profile.name.value);
    phone = TextEditingController(text: profile.phone.value);
    dob = TextEditingController(text: profile.dateOfBirth.value);
    address = TextEditingController(text: profile.address.value);
    emergency = TextEditingController(text: profile.emergencyContact.value);

    gender = profile.gender.value.isNotEmpty ? profile.gender.value : null;
    blood = profile.bloodGroup.value.isNotEmpty ? profile.bloodGroup.value : null;
  }

  Future<void> pickImage() async {
    final XFile? img =
    await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);

    if (img != null) {
      pickedImage = File(img.path);
      await profile.updateProfileImage(img.path);
      setState(() {});
    }
  }

  Future<void> selectDOB() async {
    final DateTime? d = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 7000)),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
    );
    if (d != null) {
      dob.text = "${d.day}/${d.month}/${d.year}";
    }
  }

  Future<void> save() async {
    final ok = await profile.updateProfile(
      newName: name.text.trim(),
      newPhone: phone.text.trim(),
      newDateOfBirth: dob.text.trim(),
      newGender: gender,
      newAddress: address.text.trim(),
      newEmergencyContact: emergency.text.trim(),
      newBloodGroup: blood,
    );

    if (ok) Get.back();
  }

  Widget input(String label, TextEditingController c, IconData icon,
      {bool readOnly = false, VoidCallback? tap}) {
    return TextField(
      controller: c,
      readOnly: readOnly,
      onTap: tap,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFF8B5CF6)),
        filled: true,
        fillColor: const Color(0xFF2A2A3E),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        title: const Text("Edit Profile"),
        backgroundColor: Colors.transparent,
      ),
      body: Obx(() {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              // Profile Photo
              Center(
                child: GestureDetector(
                  onTap: pickImage,
                  child: CircleAvatar(
                    radius: 60,
                    backgroundColor: const Color(0xFF8B5CF6).withValues(alpha: 0.2),
                    backgroundImage: pickedImage != null
                        ? FileImage(pickedImage!)
                        : (profile.profileImage.value.isNotEmpty
                        ? NetworkImage(profile.profileImage.value)
                        : null) as ImageProvider?,
                    child: profile.profileImage.value.isEmpty &&
                        pickedImage == null
                        ? const Icon(Icons.person, size: 60)
                        : null,
                  ),
                ),
              ),

              const SizedBox(height: 30),

              input("Full Name", name, Icons.person),
              const SizedBox(height: 20),

              input("Phone", phone, Icons.phone),
              const SizedBox(height: 20),

              input("Date of Birth", dob, Icons.calendar_month,
                  readOnly: true, tap: selectDOB),
              const SizedBox(height: 20),

              input("Address", address, Icons.location_on),
              const SizedBox(height: 20),

              input("Emergency Contact", emergency, Icons.emergency),
              const SizedBox(height: 20),

              // Gender Dropdown
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  hintText: "Select Gender",
                  filled: true,
                  fillColor: Color(0xFF2A2A3E),
                ),
                value: gender,
                dropdownColor: const Color(0xFF2A2A3E),
                items: genderOptions
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (v) => setState(() => gender = v),
              ),

              const SizedBox(height: 20),

              // Blood Group
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  hintText: "Select Blood Group",
                  filled: true,
                  fillColor: Color(0xFF2A2A3E),
                ),
                value: blood,
                dropdownColor: const Color(0xFF2A2A3E),
                items: bloodGroups
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (v) => setState(() => blood = v),
              ),

              const SizedBox(height: 30),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8B5CF6),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text(
                    "Save Changes",
                    style: TextStyle(fontSize: 17),
                  ),
                ),
              )
            ],
          ),
        );
      }),
    );
  }
}
