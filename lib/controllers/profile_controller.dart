// 📌 lib/controllers/profile_controller.dart

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:trackmate_app/services/auth_service.dart';

class ProfileController extends GetxController {
  final _storage = GetStorage();

  // Basic profile values
  var name = ''.obs;
  var fullName = ''.obs;
  var email = ''.obs;
  var phone = ''.obs;
  var profileImage = ''.obs;

  // Extra profile fields
  var dateOfBirth = ''.obs;
  var gender = ''.obs;
  var address = ''.obs;
  var emergencyContact = ''.obs;
  var bloodGroup = ''.obs;
  var bio = ''.obs;

  // Locations
  var homeLocation = ''.obs;
  var workLocation = ''.obs;

  // Vehicle details (RESTORED)
  var vehicleNumber = ''.obs;
  var vehicleModel = ''.obs;
  var isVehicleVerified = false.obs;

  // Aadhaar (RESTORED)
  var aadhaarFrontImage = ''.obs;
  var aadhaarBackImage = ''.obs;
  var isAadhaarVerified = false.obs;

  // Trusted contacts list (RESTORED)
  final trustedContacts = <Map<String, dynamic>>[].obs;

  // UI flags
  var isLoading = false.obs;
  var isUpdating = false.obs;

// ------------------------------------------------
// FETCH PROFILE (SAFE FALLBACK)
// ------------------------------------------------
  Future<void> fetchProfile() async {
    try {
      // You can extend this later with API calls
      // For now just reload local storage.
      loadProfileFromStorage();
    } catch (e) {
      debugPrint("❌ fetchProfile error: $e");
    }
  }

  // ------------------------------------------------
  // INIT
  // ------------------------------------------------
  @override
  void onInit() {
    super.onInit();
    loadProfileFromStorage();
    fetchProfile();
  }


  // ------------------------------------------------
  // LOAD FROM LOCAL STORAGE
  // ------------------------------------------------
  void loadProfileFromStorage() {
    try {
      final auth = Get.find<AuthService>();

      name.value = _storage.read('username') ?? auth.username;
      fullName.value = _storage.read('fullName') ?? name.value;
      email.value = _storage.read('email') ?? auth.email;
      phone.value = _storage.read('phone') ?? '';
      profileImage.value = _storage.read('profileImage') ?? '';

      dateOfBirth.value = _storage.read('dateOfBirth') ?? '';
      gender.value = _storage.read('gender') ?? '';
      address.value = _storage.read('address') ?? '';
      emergencyContact.value = _storage.read('emergencyContact') ?? '';
      bloodGroup.value = _storage.read('bloodGroup') ?? '';
      bio.value = _storage.read('bio') ?? '';
      homeLocation.value = _storage.read('homeLocation') ?? '';
      workLocation.value = _storage.read('workLocation') ?? '';

      // 🚗 Vehicle
      vehicleNumber.value = _storage.read('vehicleNumber') ?? '';
      vehicleModel.value = _storage.read('vehicleModel') ?? '';
      isVehicleVerified.value = _storage.read('isVehicleVerified') ?? false;

      // 🪪 Aadhaar
      aadhaarFrontImage.value = _storage.read('aadhaarFrontImage') ?? '';
      aadhaarBackImage.value = _storage.read('aadhaarBackImage') ?? '';
      isAadhaarVerified.value = _storage.read('isAadhaarVerified') ?? false;

      // 👥 Trusted contacts
      final contacts = _storage.read<List>('trusted_contacts');
      if (contacts != null) {
        trustedContacts.value =
            contacts.map((e) => Map<String, dynamic>.from(e)).toList();
      }
    } catch (e) {
      debugPrint("❌ Load profile error: $e");
    }
  }


  // ------------------------------------------------
  // SAVE TO LOCAL STORAGE
  // ------------------------------------------------
  void saveStorage() {
    _storage.write('username', name.value);
    _storage.write('fullName', fullName.value);
    _storage.write('email', email.value);
    _storage.write('phone', phone.value);
    _storage.write('profileImage', profileImage.value);

    _storage.write('dateOfBirth', dateOfBirth.value);
    _storage.write('gender', gender.value);
    _storage.write('address', address.value);
    _storage.write('emergencyContact', emergencyContact.value);
    _storage.write('bloodGroup', bloodGroup.value);
    _storage.write('bio', bio.value);

    _storage.write('homeLocation', homeLocation.value);
    _storage.write('workLocation', workLocation.value);

    // 🚗 Vehicle
    _storage.write('vehicleNumber', vehicleNumber.value);
    _storage.write('vehicleModel', vehicleModel.value);
    _storage.write('isVehicleVerified', isVehicleVerified.value);

    // 🪪 Aadhaar
    _storage.write('aadhaarFrontImage', aadhaarFrontImage.value);
    _storage.write('aadhaarBackImage', aadhaarBackImage.value);
    _storage.write('isAadhaarVerified', isAadhaarVerified.value);

    // 👥 Contacts
    _storage.write('trusted_contacts', trustedContacts.toList());
  }


  // ------------------------------------------------
  // UPDATE PROFILE (UI & LOCAL ONLY)
  // ------------------------------------------------
  Future<bool> updateProfile({
    String? newName,
    String? newPhone,
    String? newDateOfBirth,
    String? newGender,
    String? newAddress,
    String? newEmergencyContact,
    String? newBloodGroup,
    String? newBio,
    String? newHomeLocation,
    String? newWorkLocation,
  }) async {
    try {
      isUpdating.value = true;

      if (newName != null) name.value = newName;
      if (newPhone != null) phone.value = newPhone;
      if (newDateOfBirth != null) dateOfBirth.value = newDateOfBirth;
      if (newGender != null) gender.value = newGender;
      if (newAddress != null) address.value = newAddress;
      if (newEmergencyContact != null) emergencyContact.value = newEmergencyContact;
      if (newBloodGroup != null) bloodGroup.value = newBloodGroup;
      if (newBio != null) bio.value = newBio;
      if (newHomeLocation != null) homeLocation.value = newHomeLocation;
      if (newWorkLocation != null) workLocation.value = newWorkLocation;

      saveStorage();
      return true;
    } finally {
      isUpdating.value = false;
    }
  }


  // ------------------------------------------------
  // PROFILE IMAGE
  // ------------------------------------------------
  Future<bool> updateProfileImage(String path) async {
    profileImage.value = path;
    saveStorage();
    return true;
  }


  // ------------------------------------------------
  // TRUSTED CONTACTS (RESTORED)
  // ------------------------------------------------
  void addTrustedContact(String name, String phone) {
    trustedContacts.add({
      "id": DateTime.now().millisecondsSinceEpoch.toString(),
      "name": name,
      "phone": phone,
    });
    saveStorage();
  }

  void removeTrustedContact(int index) {
    trustedContacts.removeAt(index);
    saveStorage();
  }
}
