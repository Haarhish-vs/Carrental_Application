import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../home/presentation/widgets/bottom_navigation.dart';

enum SupportSection {
  support,
  faq,
  policies,
}

class SupportScreen extends StatefulWidget {
  final SupportSection initialSection;
  final VoidCallback? onGoToHome;
  final VoidCallback? onGoToBookings;
  final VoidCallback? onGoToMyCar;
  final Future<void> Function()? onGoToHost;
  final VoidCallback? onGoToProfile;

  const SupportScreen({
    super.key,
    this.initialSection = SupportSection.support,
    this.onGoToHome,
    this.onGoToBookings,
    this.onGoToMyCar,
    this.onGoToHost,
    this.onGoToProfile,
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
      _scrollToSection();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToSection() {
    if (widget.initialSection == SupportSection.support) return;

    RenderBox? targetBox;
    if (widget.initialSection == SupportSection.faq && _faqKey.currentContext != null) {
      targetBox = _faqKey.currentContext!.findRenderObject() as RenderBox?;
    } else if (widget.initialSection == SupportSection.policies && _policiesKey.currentContext != null) {
      targetBox = _policiesKey.currentContext!.findRenderObject() as RenderBox?;
    }

    if (targetBox != null) {
      final position = targetBox.localToGlobal(Offset.zero).dy;
      final currentOffset = _scrollController.offset;
      _scrollController.animateTo(
        currentOffset + position - AppBar().preferredSize.height - 20,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      // 1. SUPPORT APP BAR
      appBar: AppBar(
        title: const Text('Support', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 20)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        centerTitle: false,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: InkWell(
              onTap: widget.onGoToProfile,
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.blue.shade100, width: 2),
                ),
                child: const Icon(Icons.person_outline, color: Colors.blue, size: 20),
              ),
            ),
          )
        ],
      ),
      body: SingleChildScrollView(
        controller: _scrollController,
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 2. TOP SUPPORT CARD
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [const Color(0xFFF2F6FE), const Color(0xFFE6F0FF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8F5E9),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(Icons.circle, color: Colors.green, size: 8),
                              SizedBox(width: 4),
                              Text(
                                '24/7 Support',
                                style: TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          "We're here to help you!",
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          "Our support team is available 24/7 to assist you with anything you need.",
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.black54,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 10,
                          runSpacing: 6,
                          children: const [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.verified_user_outlined, size: 14, color: Colors.blueGrey),
                                SizedBox(width: 4),
                                Text('Secure & Reliable', style: TextStyle(fontSize: 10, color: Colors.blueGrey, fontWeight: FontWeight.w600)),
                              ],
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.bolt, size: 14, color: Colors.blueGrey),
                                SizedBox(width: 4),
                                Text('Quick Response', style: TextStyle(fontSize: 10, color: Colors.blueGrey, fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        InkWell(
                          onTap: () => _openWhatsApp(message: "Hi, I need help with my car rental."),
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.green.shade400),
                              borderRadius: BorderRadius.circular(8),
                              color: Colors.white,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.green.withValues(alpha: 0.1),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                )
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.chat_bubble, color: Colors.green, size: 20),
                                const SizedBox(width: 8),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: const [
                                    Text(
                                      'Chat on WhatsApp',
                                      style: TextStyle(
                                        color: Colors.green,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                    Text(
                                      "We'll reply shortly",
                                      style: TextStyle(
                                        color: Colors.black54,
                                        fontSize: 10,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.blue.withValues(alpha: 0.1),
                          ),
                        ),
                        const Icon(Icons.headset_mic_rounded, size: 80, color: Colors.blueAccent),
                        Positioned(
                          right: 10,
                          top: 10,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.blue,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.more_horiz, color: Colors.white, size: 16),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // 3. QUICK HELP SECTION
            const Text(
              'Quick Help',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              "Select a topic and we'll guide you in the right place.",
              style: TextStyle(
                fontSize: 13,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 16),
            
            _buildQuickHelpCard(
              icon: Icons.calendar_today,
              iconColor: Colors.blue,
              title: 'Booking Issues',
              subtitle: 'Get help with your bookings',
              children: [
                const Text('Manage all your booking related issues from here.', style: TextStyle(color: Colors.black54, fontSize: 13)),
                const SizedBox(height: 16),
                _buildCheckItem('Cancel a booking', Colors.blue),
                _buildCheckItem('Modify a booking', Colors.blue),
                _buildCheckItem('Check booking status', Colors.blue),
                _buildCheckItem('Booking not showing', Colors.blue),
                const SizedBox(height: 20),
                _buildActionButton('Go to My Bookings', Colors.blue, widget.onGoToBookings),
              ],
            ),
            
            _buildQuickHelpCard(
              icon: Icons.credit_card,
              iconColor: Colors.green,
              title: 'Payments & Methods',
              subtitle: 'Help with payments and methods',
              children: [
                const Text('View your payments, transactions and refund details.', style: TextStyle(color: Colors.black54, fontSize: 13)),
                const SizedBox(height: 16),
                _buildCheckItem('Payment history', Colors.green),
                _buildCheckItem('Refund status', Colors.green),
                _buildCheckItem('Failed payment help', Colors.green),
                _buildCheckItem('Payment methods', Colors.green),
                const SizedBox(height: 20),
                _buildActionButton('Go to My Bookings', Colors.green, widget.onGoToBookings),
              ],
            ),

            _buildQuickHelpCard(
              icon: Icons.directions_car,
              iconColor: Colors.orange,
              title: 'Vehicle Help',
              subtitle: 'Problems with your vehicle',
              children: [
                const Text('Get help with vehicle related issues.', style: TextStyle(color: Colors.black54, fontSize: 13)),
                const SizedBox(height: 16),
                _buildCheckItem('Vehicle not available', Colors.orange),
                _buildCheckItem('Vehicle condition', Colors.orange),
                _buildCheckItem('Breakdown assistance', Colors.orange),
                _buildCheckItem('Other vehicle issues', Colors.orange),
                const SizedBox(height: 20),
                _buildActionButton('Go to My Car', Colors.orange, widget.onGoToMyCar),
              ],
            ),

            _buildQuickHelpCard(
              icon: Icons.person_outline,
              iconColor: Colors.purple,
              title: 'Account Issues',
              subtitle: 'Account, profile and login help',
              children: [
                const Text('Manage your account, profile and login issues.', style: TextStyle(color: Colors.black54, fontSize: 13)),
                const SizedBox(height: 16),
                _buildCheckItem('Log in problems', Colors.purple),
                _buildCheckItem('Update profile', Colors.purple),
                _buildCheckItem('Change password', Colors.purple),
                _buildCheckItem('Account verification', Colors.purple),
                const SizedBox(height: 20),
                _buildActionButton('Go to Profile', Colors.purple, widget.onGoToProfile),
              ],
            ),

            _buildQuickHelpCard(
              icon: Icons.chat_bubble_outline,
              iconColor: Colors.blue,
              title: 'General Inquiries',
              subtitle: "Other questions? We're here.",
              children: [
                const Text("Have any other questions? We're here to help.", style: TextStyle(color: Colors.black54, fontSize: 13)),
                const SizedBox(height: 16),
                _buildCheckItem('How it works', Colors.blue),
                _buildCheckItem('Pricing & Charges', Colors.blue),
                _buildCheckItem('Offers & Promotions', Colors.blue),
                _buildCheckItem('Other inquiries', Colors.blue),
                const SizedBox(height: 20),
                InkWell(
                  onTap: () => _openWhatsApp(message: "Hi, I need help with my car rental."),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.green),
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.white,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.chat_bubble_outline, color: Colors.green),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text(
                              'Chat on WhatsApp',
                              style: TextStyle(
                                color: Colors.green,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            Text(
                              "We'll reply shortly",
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // 4. FREQUENTLY ASKED QUESTIONS
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    key: _faqKey,
                    'Frequently Asked Questions',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () {},
                  child: const Text('See all', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Card(
              color: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: Colors.grey.shade200),
              ),
              child: Theme(
                data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                child: Column(
                  children: [
                    _buildFaqTile(
                      'How do I cancel a booking?',
                      'You can cancel a booking by navigating to "My Bookings", selecting your trip, and tapping "Cancel". Cancellation policies apply.',
                    ),
                    Divider(height: 1, indent: 16, endIndent: 16, color: Colors.grey.shade200),
                    _buildFaqTile(
                      'When will I receive my refund?',
                      'Refunds are typically processed within 5-7 business days depending on your payment method and bank.',
                    ),
                    Divider(height: 1, indent: 16, endIndent: 16, color: Colors.grey.shade200),
                    _buildFaqTile(
                      'What documents are required?',
                      "You need a valid driver's license, a credit card in your name, and a government-issued ID.",
                    ),
                    Divider(height: 1, indent: 16, endIndent: 16, color: Colors.grey.shade200),
                    _buildFaqTile(
                      'How do I extend my trip?',
                      'To extend your trip, go to "My Bookings", select the active trip, and choose "Extend Trip". Extensions are subject to vehicle availability.',
                    ),
                    Divider(height: 1, indent: 16, endIndent: 16, color: Colors.grey.shade200),
                    _buildFaqTile(
                      'Can someone else drive the car?',
                      'Only registered and approved drivers are allowed to drive the vehicle. You can add additional drivers during the booking process.',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            
            // 5. EMERGENCY ASSISTANCE
            const Text(
              'Emergency Assistance',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFFD32F2F), // Red text to match styling
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
                    () => _openWhatsApp(message: "EMERGENCY: Vehicle Breakdown. I need immediate assistance."),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildEmergencyCard(
                    'Accident\nSupport',
                    'Report an accident',
                    Icons.car_crash_outlined,
                    () => _openWhatsApp(message: "EMERGENCY: Accident Support. I need immediate assistance."),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildEmergencyCard(
                    'SOS\nAssistance',
                    'Call emergency',
                    Icons.sos,
                    () => _callEmergency(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // 6. POLICIES & INFORMATION
            Text(
              key: _policiesKey,
              'Policies & Information',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            Card(
              color: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: Colors.grey.shade200),
              ),
              child: Theme(
                data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                child: Column(
                  children: [
                    _buildPolicyTile(
                      Icons.privacy_tip_outlined,
                      'Privacy Policy',
                      'We value your privacy. We do not sell your personal data. We use it only to provide and improve our services, process payments, and ensure safety.',
                    ),
                    Divider(height: 1, indent: 48, endIndent: 16, color: Colors.grey.shade200),
                    _buildPolicyTile(
                      Icons.description_outlined,
                      'Terms & Conditions',
                      'By using our app, you agree to comply with our community guidelines, maintain the vehicles in good condition, and return them on time. Full terms are available on our website.',
                    ),
                    Divider(height: 1, indent: 48, endIndent: 16, color: Colors.grey.shade200),
                    _buildPolicyTile(
                      Icons.event_busy_outlined,
                      'Cancellation Policy',
                      'Free cancellation up to 24 hours before your trip starts. Cancellations made within 24 hours of the start time may be subject to a fee.',
                    ),
                    Divider(height: 1, indent: 48, endIndent: 16, color: Colors.grey.shade200),
                    _buildPolicyTile(
                      Icons.receipt_long_outlined,
                      'Refund Policy',
                      'Refunds for eligible cancellations are issued to the original payment method and take 5-7 business days to reflect in your account.',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            // 7. BOTTOM "STILL NEED HELP?" AREA
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF2F6FE),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.blue.shade100),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.mark_email_unread_outlined, color: Colors.blue, size: 24),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Still need help?',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.blue),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          "Can't find what you're looking for? Our team is here for you.",
                          style: TextStyle(fontSize: 12, color: Colors.black54),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            InkWell(
              onTap: () => _openWhatsApp(message: "Hi, I still need help."),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Colors.green),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.chat_bubble, color: Colors.green, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Chat with us on WhatsApp',
                      style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
      // 8. BOTTOM NAVIGATION
      bottomNavigationBar: BottomNavigation(
        currentIndex: 0, // Highlight Home since Support screen is opened from Home
        onHomeTap: widget.onGoToHome ?? () {},
        onBookingsTap: widget.onGoToBookings ?? () {},
        onMyCarTap: widget.onGoToMyCar ?? () {},
        onHostTap: widget.onGoToHost ?? () async {},
      ),
    );
  }

  Widget _buildQuickHelpCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required List<Widget> children,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 4,
              offset: const Offset(0, 2),
            )
          ],
        ),
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87, fontSize: 15)),
            subtitle: Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.black54)),
            trailing: const Icon(Icons.chevron_right, color: Colors.grey),
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: children,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCheckItem(String text, Color iconColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          Icon(Icons.check_circle, color: iconColor, size: 18),
          const SizedBox(width: 12),
          Text(text, style: const TextStyle(color: Colors.black87, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildActionButton(String label, Color color, VoidCallback? onPressed) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color.withValues(alpha: 0.1),
          foregroundColor: color,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
        child: Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildFaqTile(String title, String content) {
    return ExpansionTile(
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.black87, fontSize: 14),
      ),
      iconColor: Colors.black54,
      collapsedIconColor: Colors.black54,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 16.0),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              content,
              style: const TextStyle(color: Colors.black54, height: 1.5, fontSize: 13),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPolicyTile(IconData icon, String title, String content) {
    return ExpansionTile(
      leading: Icon(icon, color: Colors.black87, size: 22),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.black87, fontSize: 14),
      ),
      iconColor: Colors.black54,
      collapsedIconColor: Colors.black54,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 48.0, right: 16.0, bottom: 16.0),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              content,
              style: const TextStyle(color: Colors.black54, height: 1.5, fontSize: 13),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmergencyCard(String title, String subtitle, IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 160, // Increased height to prevent overflow
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF5F5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFFFE5E5)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(icon, color: const Color(0xFFE53935), size: 28),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.black87, height: 1.2),
              maxLines: 2,
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 10, color: Colors.black54),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFFFE5E5)),
              ),
              child: const Icon(Icons.chevron_right, color: Color(0xFFE53935), size: 16),
            ),
          ],
        ),
      ),
    );
  }
}
