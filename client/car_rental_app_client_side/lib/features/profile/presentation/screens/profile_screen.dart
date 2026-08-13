import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/screens/auth_screen.dart';
import '../../../auth/services/auth_service.dart';
import '../../data/models/user_profile_model.dart';
import '../../data/services/profile_api_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ProfileApiService _apiService = ProfileApiService();
  final ImagePicker _imagePicker = ImagePicker();

  UserProfileModel? _profile;
  bool _isLoading = true;
  bool _isUploadingImage = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    if (!AuthService.isAuthenticated) {
      setState(() {
        _isLoading = false;
        _profile = null;
      });
      return;
    }

    final cachedProfile = _apiService.getCachedProfile();
    if (cachedProfile != null) {
      setState(() {
        _profile = cachedProfile;
        _isLoading = false;
        _errorMessage = null;
      });
      // Silently fetch update in background without triggering _isLoading
      _apiService.getProfile().then((freshProfile) {
        if (mounted && _profile != freshProfile) {
          setState(() {
            _profile = freshProfile;
          });
        }
      }).catchError((_) {});
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final profile = await _apiService.getProfile();
      if (mounted) {
        setState(() {
          _profile = profile;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleImagePick() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Change Profile Photo',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFEAF2FF),
                  child: Icon(Icons.camera_alt_rounded, color: AppColors.primary),
                ),
                title: const Text('Take a Photo'),
                onTap: () => Navigator.pop(ctx, ImageSource.camera),
              ),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFEAF2FF),
                  child: Icon(Icons.photo_library_rounded, color: AppColors.primary),
                ),
                title: const Text('Choose from Gallery'),
                onTap: () => Navigator.pop(ctx, ImageSource.gallery),
              ),
            ],
          ),
        ),
      ),
    );

    if (source == null || !mounted) return;

    try {
      final pickedFile = await _imagePicker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (pickedFile == null || !mounted) return;

      setState(() {
        _isUploadingImage = true;
      });

      final updatedProfile = await _apiService.uploadProfileImage(pickedFile);

      if (mounted) {
        setState(() {
          _profile = updatedProfile;
          _isUploadingImage = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile picture updated successfully!'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isUploadingImage = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Upload failed: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _editField({
    required String title,
    required String initialValue,
    required String fieldKey,
    TextInputType keyboardType = TextInputType.text,
  }) async {
    final controller = TextEditingController(text: initialValue);
    final formKey = GlobalKey<FormState>();

    final updated = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Edit $title', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            autofocus: true,
            decoration: InputDecoration(
              labelText: title,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.primary, width: 2),
              ),
            ),
            validator: (val) {
              if (val == null || val.trim().isEmpty) {
                return 'Please enter $title';
              }
              if (fieldKey == 'phoneNumber' && val.trim().length < 8) {
                return 'Please enter a valid phone number';
              }
              return null;
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState?.validate() == true) {
                Navigator.pop(ctx, controller.text.trim());
              }
            },
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (updated == null || updated == initialValue || !mounted) return;

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final updatedProfile = await _apiService.updateProfile(
        fullName: fieldKey == 'fullName' ? updated : null,
        phoneNumber: fieldKey == 'phoneNumber' ? updated : null,
      );

      if (mounted) {
        Navigator.pop(context); // Pop loading
        setState(() {
          _profile = updatedProfile;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$title updated successfully!'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Pop loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Update failed: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _handleLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Log Out'),
        content: const Text('Are you sure you want to log out of your account?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Log Out'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await AuthService.logout();
      if (mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => const AuthScreen(initialMode: AuthMode.login),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!AuthService.isAuthenticated) {
      return Scaffold(
        backgroundColor: const Color(0xFFF7F8FA),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, size: 20, color: AppColors.textPrimary),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text('Profile', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
          centerTitle: true,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.account_circle_outlined, size: 72, color: AppColors.primary),
                const SizedBox(height: 16),
                const Text('Sign in to view your profile', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                const Text(
                  'Manage your account details, trips, listings, and preferences.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: () async {
                    final loggedIn = await Navigator.of(context).push<bool>(
                      MaterialPageRoute(builder: (_) => const AuthScreen()),
                    );
                    if (loggedIn == true && mounted) {
                      _loadProfile();
                    }
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    minimumSize: const Size(200, 50),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('Log In / Register', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF7F8FA),
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF7F8FA),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, size: 20, color: AppColors.textPrimary),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text('Profile', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
          centerTitle: true,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 54, color: Colors.redAccent),
                const SizedBox(height: 14),
                Text(_errorMessage!, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textSecondary)),
                const SizedBox(height: 18),
                FilledButton.icon(
                  onPressed: _loadProfile,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                  style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final profile = _profile ??
        UserProfileModel(
          id: '',
          fullName: 'User',
          phoneNumber: '',
        );

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Profile',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // 1. Avatar & User Name
            _buildUserHero(profile),
            const SizedBox(height: 24),

            // 2. Personal Info Card
            _buildPersonalInfoCard(profile),
            const SizedBox(height: 24),

            // 3. Account Type Section
            _buildAccountTypeSection(profile),
            const SizedBox(height: 24),

            // 4. My Activity Section
            _buildMyActivitySection(profile),
            const SizedBox(height: 28),

            // 5. Logout Button
            FilledButton.icon(
              onPressed: _handleLogout,
              icon: const Icon(Icons.logout_rounded, size: 20, color: Colors.white),
              label: const Text(
                'Logout',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                minimumSize: const Size(double.infinity, 54),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildUserHero(UserProfileModel profile) {
    return Column(
      children: [
        Stack(
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFEAF2FF),
                border: Border.all(color: Colors.white, width: 3),
                boxShadow: const [
                  BoxShadow(color: Color.fromRGBO(0, 0, 0, 0.06), blurRadius: 12, offset: Offset(0, 4)),
                ],
              ),
              child: ClipOval(
                child: _isUploadingImage
                    ? const Center(child: CircularProgressIndicator(strokeWidth: 2.5))
                    : profile.profileImageUrl.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: profile.profileImageUrl,
                            fit: BoxFit.cover,
                            errorWidget: (context, url, error) => Center(
                              child: Text(
                                profile.fullName.isNotEmpty ? profile.fullName[0].toUpperCase() : 'U',
                                style: const TextStyle(fontSize: 38, fontWeight: FontWeight.bold, color: AppColors.primary),
                              ),
                            ),
                          )
                        : Center(
                            child: Text(
                              profile.fullName.isNotEmpty ? profile.fullName[0].toUpperCase() : 'U',
                              style: const TextStyle(fontSize: 38, fontWeight: FontWeight.bold, color: AppColors.primary),
                            ),
                          ),
              ),
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: GestureDetector(
                onTap: _handleImagePick,
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: const [
                      BoxShadow(color: Color.fromRGBO(0, 0, 0, 0.1), blurRadius: 6, offset: Offset(0, 2)),
                    ],
                  ),
                  child: const Icon(Icons.edit, size: 16, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          profile.fullName,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
        ),
      ],
    );
  }

  Widget _buildPersonalInfoCard(UserProfileModel profile) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(color: Color.fromRGBO(0, 0, 0, 0.02), blurRadius: 10, offset: Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          // Full Name Row
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: const BoxDecoration(
                    color: Color(0xFFEAF2FF),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.person_rounded, color: AppColors.primary, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Full Name', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                      const SizedBox(height: 2),
                      Text(
                        profile.fullName,
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                      ),
                    ],
                  ),
                ),
                InkWell(
                  onTap: () => _editField(
                    title: 'Full Name',
                    initialValue: profile.fullName,
                    fieldKey: 'fullName',
                  ),
                  borderRadius: BorderRadius.circular(8),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Edit', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600, fontSize: 13)),
                        SizedBox(width: 2),
                        Icon(Icons.chevron_right_rounded, size: 18, color: AppColors.primary),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, indent: 70, endIndent: 16, color: Color(0xFFF1F3F5)),

          // Phone Number Row
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: const BoxDecoration(
                    color: Color(0xFFEAF2FF),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.phone_rounded, color: AppColors.primary, size: 20),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Phone Number', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                      const SizedBox(height: 2),
                      Text(
                        profile.phoneNumber.isNotEmpty ? profile.phoneNumber : 'Not set',
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                      ),
                    ],
                  ),
                ),
                InkWell(
                  onTap: () => _editField(
                    title: 'Phone Number',
                    initialValue: profile.phoneNumber,
                    fieldKey: 'phoneNumber',
                    keyboardType: TextInputType.phone,
                  ),
                  borderRadius: BorderRadius.circular(8),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Edit', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600, fontSize: 13)),
                        SizedBox(width: 2),
                        Icon(Icons.chevron_right_rounded, size: 18, color: AppColors.primary),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountTypeSection(UserProfileModel profile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Account Type',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            // Renter Card
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: const [
                    BoxShadow(color: Color.fromRGBO(0, 0, 0, 0.02), blurRadius: 10, offset: Offset(0, 4)),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: const BoxDecoration(
                            color: Color(0xFF1A73E8),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.directions_car_rounded, color: Colors.white, size: 22),
                        ),
                        Container(
                          padding: const EdgeInsets.all(3),
                          decoration: const BoxDecoration(
                            color: Color(0xFF1A73E8),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.check, size: 12, color: Colors.white),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Renter',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1A73E8)),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'You have booked\n${profile.bookedCarsCount} cars',
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.3),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 14),

            // Owner Card
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: const [
                    BoxShadow(color: Color.fromRGBO(0, 0, 0, 0.02), blurRadius: 10, offset: Offset(0, 4)),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: const BoxDecoration(
                            color: Color(0xFF1A73E8),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.key_rounded, color: Colors.white, size: 22),
                        ),
                        if (profile.isOwner)
                          Container(
                            padding: const EdgeInsets.all(3),
                            decoration: const BoxDecoration(
                              color: Color(0xFF1A73E8),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.check, size: 12, color: Colors.white),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Owner',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1A73E8)),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'You have listed\n${profile.listedCarsCount} cars',
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.3),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMyActivitySection(UserProfileModel profile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'My Activity',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: const [
              BoxShadow(color: Color.fromRGBO(0, 0, 0, 0.02), blurRadius: 10, offset: Offset(0, 4)),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildActivityColumn(
                icon: Icons.assignment_outlined,
                count: '${profile.totalBookings}',
                label: 'Total Bookings',
              ),
              _buildActivityDivider(),
              _buildActivityColumn(
                icon: Icons.calendar_today_outlined,
                count: '${profile.activeBookings}',
                label: 'Active Bookings',
              ),
              _buildActivityDivider(),
              _buildActivityColumn(
                icon: Icons.check_circle_outline_rounded,
                count: '${profile.completedTrips}',
                label: 'Completed Trips',
              ),
              _buildActivityDivider(),
              _buildActivityColumn(
                icon: Icons.directions_car_outlined,
                count: '${profile.carsListed}',
                label: 'Cars Listed',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActivityColumn({
    required IconData icon,
    required String count,
    required String label,
  }) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: Color(0xFFEAF2FF),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.primary, size: 20),
          ),
          const SizedBox(height: 8),
          Text(
            count,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 10.5, color: AppColors.textSecondary, height: 1.2),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityDivider() {
    return Container(
      height: 45,
      width: 1,
      color: const Color(0xFFF1F3F5),
    );
  }
}
