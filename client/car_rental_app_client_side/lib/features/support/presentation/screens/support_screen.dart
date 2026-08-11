import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/app_colors.dart';
import 'ai_assistant_screen.dart';

enum SupportSection {
  support,
  faq,
  policies,
}

class SupportScreen extends StatefulWidget {
  final SupportSection initialSection;
  final VoidCallback onGoToBookings;
  final VoidCallback onGoToMyCar;
  final VoidCallback onGoToProfile;

  const SupportScreen({
    super.key,
    this.initialSection = SupportSection.support,
    required this.onGoToBookings,
    required this.onGoToMyCar,
    required this.onGoToProfile,
  });

  @override
  State<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen> {
  static const String _supportWhatsAppNumber = '+91 98765 43210';
  static const String _sosEmergencyNumber = '911';

  final ScrollController _scrollController = ScrollController();
  final GlobalKey _faqKey = GlobalKey();
  final GlobalKey _policiesKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToInitialSection();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToInitialSection() {
    if (widget.initialSection == SupportSection.faq) {
      _scrollToKey(_faqKey);
    } else if (widget.initialSection == SupportSection.policies) {
      _scrollToKey(_policiesKey);
    }
  }

  void _scrollToKey(GlobalKey key) {
    final context = key.currentContext;
    if (context != null) {
      Scrollable.ensureVisible(
        context,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _openWhatsApp({String message = "Hi, I need help with my car rental."}) async {
    final cleanNumber = _supportWhatsAppNumber.replaceAll(RegExp(r'[^\d]'), '');
    final url = Uri.https('wa.me', '/$cleanNumber/', {'text': message});
    
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open WhatsApp.')),
        );
      }
    }
  }

  Future<void> _callEmergency() async {
    final url = Uri.parse('tel:$_sosEmergencyNumber');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open dialer.')),
        );
      }
    }
  }

  void _goToAiAssistant() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const AiAssistantScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Support',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.textPrimary),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(
            color: const Color(0xFFF3F4F6),
            height: 1.0,
          ),
        ),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            controller: _scrollController,
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 24),
                _buildMainSupportCard(),
                const SizedBox(height: 32),
                _buildQuickHelp(),
                const SizedBox(height: 32),
                _buildStillNeedHelpCard(),
                const SizedBox(height: 32),
                _buildFAQSection(),
                const SizedBox(height: 32),
                _buildEmergencySection(),
                const SizedBox(height: 32),
                _buildPoliciesSection(),
                const SizedBox(height: 100), // Padding for floating button
              ],
            ),
          ),
          Positioned(
            bottom: 24,
            right: 24,
            child: FloatingActionButton(
              onPressed: _goToAiAssistant,
              backgroundColor: AppColors.primary,
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              child: const Icon(Icons.smart_toy, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        Text(
          'Hi, Guest 👋',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        SizedBox(height: 4),
        Text(
          'How can we help you today?',
          style: TextStyle(
            fontSize: 15,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildMainSupportCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F8FF), // Soft light blue
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      "We're here to help you!",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      "Our support team is available 24/7 to assist you with anything you need.",
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              const Icon(Icons.headset_mic_rounded, size: 64, color: AppColors.primary),
            ],
          ),
          const SizedBox(height: 20),
          InkWell(
            onTap: () => _openWhatsApp(message: "Hi, I need help with my car rental."),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.chat_bubble_outline, color: Color(0xFF25D366)),
                  SizedBox(width: 12),
                  Text(
                    "Chat on WhatsApp", 
                    style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF25D366))
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickHelp() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Help',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          "Select a topic and we'll guide you in the right place.",
          style: TextStyle(
            fontSize: 14,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 16),
        _buildQuickHelpCard(
          title: 'Booking Issues',
          subtitle: 'Get help with your bookings',
          icon: Icons.calendar_today_outlined,
          iconColor: AppColors.primary,
          iconBgColor: const Color(0xFFEAF2FF),
          expandedContent: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Manage all your booking related issues from here.", style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
              const SizedBox(height: 16),
              _buildCheckItem("Cancel a booking", AppColors.primary),
              _buildCheckItem("Modify a booking", AppColors.primary),
              _buildCheckItem("Check booking status", AppColors.primary),
              _buildCheckItem("Booking not showing", AppColors.primary),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop();
                    widget.onGoToBookings();
                  },
                  icon: const Icon(Icons.calendar_today_outlined, size: 18),
                  label: const Text('Go to My Bookings', style: TextStyle(fontWeight: FontWeight.w600)),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _buildQuickHelpCard(
          title: 'Payments & Methods',
          subtitle: 'Help with payments and methods',
          icon: Icons.payment_outlined,
          iconColor: const Color(0xFF10B981),
          iconBgColor: const Color(0xFFE8F5E9),
          expandedContent: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("View your payments, transactions and refund details.", style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
              const SizedBox(height: 16),
              _buildCheckItem("Payment history", const Color(0xFF10B981)),
              _buildCheckItem("Refund status", const Color(0xFF10B981)),
              _buildCheckItem("Failed payment help", const Color(0xFF10B981)),
              _buildCheckItem("Payment methods", const Color(0xFF10B981)),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop();
                    widget.onGoToBookings();
                  },
                  icon: const Icon(Icons.calendar_today_outlined, size: 18),
                  label: const Text('Go to My Bookings', style: TextStyle(fontWeight: FontWeight.w600)),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _buildQuickHelpCard(
          title: 'Vehicle Help',
          subtitle: 'Problems with your vehicle',
          icon: Icons.directions_car_outlined,
          iconColor: const Color(0xFFFF8C00),
          iconBgColor: const Color(0xFFFFF3E0),
          expandedContent: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Get help with vehicle related issues.", style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
              const SizedBox(height: 16),
              _buildCheckItem("Vehicle not available", const Color(0xFFFF8C00)),
              _buildCheckItem("Vehicle condition", const Color(0xFFFF8C00)),
              _buildCheckItem("Breakdown assistance", const Color(0xFFFF8C00)),
              _buildCheckItem("Other vehicle issues", const Color(0xFFFF8C00)),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    widget.onGoToMyCar();
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFFF8C00),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Go to My Car', style: TextStyle(fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _buildQuickHelpCard(
          title: 'Account Issues',
          subtitle: 'Account, profile and login help',
          icon: Icons.person_outline,
          iconColor: Colors.purple,
          iconBgColor: const Color(0xFFF3E5F5),
          expandedContent: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Manage your account, profile and login issues.", style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
              const SizedBox(height: 16),
              _buildCheckItem("Login problems", Colors.purple),
              _buildCheckItem("Update profile", Colors.purple),
              _buildCheckItem("Change password", Colors.purple),
              _buildCheckItem("Account verification", Colors.purple),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    widget.onGoToProfile();
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.purple,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Go to Profile', style: TextStyle(fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _buildQuickHelpCard(
          title: 'General Inquiries',
          subtitle: 'Other questions? We\'re here.',
          icon: Icons.chat_bubble_outline,
          iconColor: AppColors.primary,
          iconBgColor: const Color(0xFFEAF2FF),
          expandedContent: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Have any other questions? We're here to help.", style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
              const SizedBox(height: 16),
              _buildCheckItem("How it works", AppColors.primary),
              _buildCheckItem("Pricing & Charges", AppColors.primary),
              _buildCheckItem("Offers & Promotions", AppColors.primary),
              _buildCheckItem("Other inquiries", AppColors.primary),
              const SizedBox(height: 20),
              InkWell(
                onTap: () => _openWhatsApp(message: "Hi, I need help with my car rental."),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF25D366)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.chat_bubble_outline, color: Color(0xFF25D366)),
                      SizedBox(width: 12),
                      Text("Chat on WhatsApp", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF25D366))),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQuickHelpCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    required Widget expandedContent,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF3F4F6)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconBgColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          title: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4.0),
            child: Text(
              subtitle,
              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
          ),
          childrenPadding: const EdgeInsets.only(left: 20, right: 20, bottom: 20),
          expandedCrossAxisAlignment: CrossAxisAlignment.start,
          children: [expandedContent],
        ),
      ),
    );
  }

  Widget _buildCheckItem(String text, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0),
      child: Row(
        children: [
          Icon(Icons.check, color: color, size: 18),
          const SizedBox(width: 10),
          Text(text, style: const TextStyle(fontSize: 14, color: AppColors.textPrimary)),
        ],
      ),
    );
  }

  Widget _buildStillNeedHelpCard() {
    return InkWell(
      onTap: _goToAiAssistant,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xFFF3F8FF),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.primary.withOpacity(0.1)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.chat_bubble_outline, color: AppColors.primary, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    "Still need help?",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary),
                  ),
                  SizedBox(height: 4),
                  Text(
                    "Chat with our AI Assistant for instant support.",
                    style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 16, color: AppColors.primary),
          ],
        ),
      ),
    );
  }

  Widget _buildFAQSection() {
    return Column(
      key: _faqKey,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Frequently Asked Questions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            TextButton(
              onPressed: () {},
              child: const Text(
                "See all",
                style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600, fontSize: 14),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _buildFAQItem('How do I cancel a booking?', 'You can cancel a booking by navigating to "My Bookings", selecting your trip, and tapping "Cancel". Cancellation policies apply.'),
        const Divider(height: 1, color: Color(0xFFF3F4F6)),
        _buildFAQItem('When will I receive my refund?', 'Refunds are typically processed within 5-7 business days depending on your payment method and bank.'),
        const Divider(height: 1, color: Color(0xFFF3F4F6)),
        _buildFAQItem('What documents are required?', "You need a valid driver's license, a credit card in your name, and a government-issued ID."),
        const Divider(height: 1, color: Color(0xFFF3F4F6)),
        _buildFAQItem('How do I extend my trip?', 'To extend your trip, go to "My Bookings", select the active trip, and choose "Extend Trip". Extensions are subject to vehicle availability.'),
        const Divider(height: 1, color: Color(0xFFF3F4F6)),
        _buildFAQItem('Can someone else drive the car?', 'Only registered and approved drivers are allowed to drive the vehicle. You can add additional drivers during the booking process.'),
      ],
    );
  }

  Widget _buildFAQItem(String question, String answer) {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(vertical: 4),
        iconColor: AppColors.textPrimary,
        collapsedIconColor: AppColors.textPrimary,
        title: Text(
          question,
          style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary, fontSize: 14),
        ),
        childrenPadding: const EdgeInsets.only(bottom: 16),
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              answer, 
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.4)
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmergencySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Emergency Assistance',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildEmergencyCard(
                'Vehicle\nBreakdown', 
                'Get roadside help', 
                Icons.warning_amber_rounded, 
                () => _openWhatsApp(message: "EMERGENCY: Vehicle Breakdown. I need immediate assistance.")
              )
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildEmergencyCard(
                'Accident\nSupport', 
                'Report an accident', 
                Icons.car_crash_outlined, 
                () => _openWhatsApp(message: "EMERGENCY: Accident Support. I need immediate assistance.")
              )
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildEmergencyCard(
                'SOS\nAssistance', 
                'Call emergency', 
                Icons.sos, 
                _callEmergency
              )
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEmergencyCard(String title, String subtitle, IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 4),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF0F0),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.red.withOpacity(0.1)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Colors.white, size: 20),
            ),
            const SizedBox(height: 12),
            Text(
              title, 
              textAlign: TextAlign.center, 
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.textPrimary, height: 1.2)
            ),
            const SizedBox(height: 4),
            Text(
              subtitle, 
              textAlign: TextAlign.center, 
              style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPoliciesSection() {
    return Column(
      key: _policiesKey,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Policies & Information',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFF3F4F6)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              _buildPolicyItem(
                'Privacy Policy', 
                Icons.shield_outlined, 
                'We value your privacy. We do not sell your personal data. We use it only to provide and improve our services, process payments, and ensure safety.'
              ),
              const Divider(height: 1, color: Color(0xFFF3F4F6), indent: 16, endIndent: 16),
              _buildPolicyItem(
                'Terms & Conditions', 
                Icons.description_outlined, 
                'By using our app, you agree to comply with our community guidelines, maintain the vehicles in good condition, and return them on time. Full terms are available on our website.'
              ),
              const Divider(height: 1, color: Color(0xFFF3F4F6), indent: 16, endIndent: 16),
              _buildPolicyItem(
                'Cancellation Policy', 
                Icons.description_outlined, 
                'Free cancellation up to 24 hours before your trip starts. Cancellations made within 24 hours of the start time may be subject to a fee.'
              ),
              const Divider(height: 1, color: Color(0xFFF3F4F6), indent: 16, endIndent: 16),
              _buildPolicyItem(
                'Refund Policy', 
                Icons.description_outlined, 
                'Refunds for eligible cancellations are issued to the original payment method and take 5-7 business days to reflect in your account.'
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPolicyItem(String title, IconData icon, String content) {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        iconColor: AppColors.textPrimary,
        collapsedIconColor: AppColors.textPrimary,
        leading: Icon(icon, color: AppColors.textPrimary, size: 22),
        title: Text(
          title, 
          style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary, fontSize: 14)
        ),
        childrenPadding: const EdgeInsets.only(left: 16, right: 16, bottom: 20),
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(content, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.4)),
        ],
      ),
    );
  }
}
