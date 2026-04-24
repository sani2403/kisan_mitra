import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/input_field.dart';
import '../widgets/dropdown_field.dart';

class ProfileScreen extends StatefulWidget {
  final bool isOnboarding;
  const ProfileScreen({super.key, this.isOnboarding = false});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _farmSizeCtrl = TextEditingController();
  String? _state, _cropType, _irrigation;
  bool _saving = false;

  late AnimationController _enterCtrl;
  late Animation<Offset> _enterSlide;
  late Animation<double> _enterFade;

  final _states      = ['Chhattisgarh', 'Maharashtra', 'Punjab', 'Uttar Pradesh', 'Tamil Nadu', 'Madhya Pradesh', 'Rajasthan', 'Karnataka'];
  final _crops       = ['Wheat', 'Rice', 'Maize', 'Vegetables', 'Soybean', 'Cotton', 'Sugarcane'];
  final _irrigations = ['Rain-fed', 'Drip', 'Canal', 'Borewell', 'Sprinkler'];

  @override
  void initState() {
    super.initState();
    _enterCtrl  = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _enterSlide = Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero)
        .animate(CurvedAnimation(parent: _enterCtrl, curve: Curves.easeOutCubic));
    _enterFade  = CurvedAnimation(parent: _enterCtrl, curve: Curves.easeOut);
    _enterCtrl.forward();
    _loadExisting();
  }

  Future<void> _loadExisting() async {
    final p = await SharedPreferences.getInstance();
    if (!mounted) return;

    setState(() {
      _nameCtrl.text       = p.getString('farmer_name') ?? '';
      _state               = p.getString('state').let((v) => v?.isEmpty == true ? null : v);
      _cropType            = p.getString('crop_type').let((v) => v?.isEmpty == true ? null : v);
      _farmSizeCtrl.text   = p.getString('farm_size') ?? '';
      _irrigation          = p.getString('irrigation').let((v) => v?.isEmpty == true ? null : v);
    });
  }

  @override
  void dispose() {
    _enterCtrl.dispose();
    _nameCtrl.dispose();
    _farmSizeCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    HapticFeedback.mediumImpact();
    final p = await SharedPreferences.getInstance();
    await Future.wait([
      p.setString('farmer_name', _nameCtrl.text.trim()),
      p.setString('state',       _state ?? ''),
      p.setString('crop_type',   _cropType ?? ''),
      p.setString('farm_size',   _farmSizeCtrl.text.trim()),
      p.setString('irrigation',  _irrigation ?? ''),
    ]);
    if (!mounted) return;
    setState(() => _saving = false);
    if (widget.isOnboarding) {
      Navigator.of(context).pushNamedAndRemoveUntil('/home', (_) => false);
    } else {
      Navigator.of(context).pushReplacementNamed('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F5F2),
      body: SafeArea(
        child: FadeTransition(
          opacity: _enterFade,
          child: SlideTransition(
            position: _enterSlide,
            child: Form(
              key: _formKey,
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(child: _buildHeader()),
                  SliverToBoxAdapter(child: _buildForm()),
                  const SliverToBoxAdapter(child: SizedBox(height: 40)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (!widget.isOnboarding)
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
            ),
          ),
        Row(children: [
          Container(
            width: 56, height: 56,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF43A047), Color(0xFF1B5E20)]),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Center(child: Text('👨‍🌾', style: TextStyle(fontSize: 28))),
          ),
          const SizedBox(width: 16),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(
              widget.isOnboarding ? 'Welcome to KisanMitra! 🌱' : 'Farmer Profile',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFF1A1A1A)),
            ),
            const SizedBox(height: 3),
            Text(
              widget.isOnboarding ? 'Tell us about your farm' : 'Update your details',
              style: TextStyle(fontSize: 13, color: Colors.grey[500]),
            ),
          ])),
        ]),
        if (widget.isOnboarding) ...[
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF2E7D32).withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(children: [
              const Text('💡', style: TextStyle(fontSize: 16)),
              const SizedBox(width: 10),
              Expanded(child: Text(
                'Fill in your farm details to get personalized recommendations',
                style: TextStyle(fontSize: 12.5, color: Colors.grey[700], height: 1.4),
              )),
            ]),
          ),
        ],
      ]),
    );
  }

  Widget _buildForm() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Card 1 – Basic Info
        _card('👤 Basic Information', children: [
          _label('Full Name'),
          InputField(controller: _nameCtrl, hint: 'Enter your name',
              validator: (v) => v?.trim().isEmpty == true ? 'Name is required' : null),
          const SizedBox(height: 16),
          _label('State'),
          DropdownField(value: _state, hint: 'Select your state', items: _states,
              onChanged: (v) => setState(() => _state = v),
              validator: (v) => v == null ? 'Please select a state' : null),
        ]),
        const SizedBox(height: 14),

        // Card 2 – Farm Details
        _card('🌾 Farm Details', children: [
          _label('Main Crop'),
          DropdownField(value: _cropType, hint: 'Select crop type', items: _crops,
              onChanged: (v) => setState(() => _cropType = v),
              validator: (v) => v == null ? 'Please select a crop' : null),
          const SizedBox(height: 16),
          _label('Farm Size (Acres)'),
          InputField(controller: _farmSizeCtrl, hint: 'e.g. 2.5',
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: (v) => v?.trim().isEmpty == true ? 'Enter farm size' : null),
          const SizedBox(height: 16),
          _label('Irrigation Type'),
          DropdownField(value: _irrigation, hint: 'Select irrigation method', items: _irrigations,
              onChanged: (v) => setState(() => _irrigation = v),
              validator: (v) => v == null ? 'Please select irrigation type' : null),
        ]),
        const SizedBox(height: 14),


        const SizedBox(height: 28),

        // Save Button
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: _saving ? null : _save,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2E7D32),
              foregroundColor: Colors.white,
              elevation: 0,
              shadowColor: Colors.transparent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: _saving
                ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(widget.isOnboarding ? Icons.rocket_launch_rounded : Icons.check_rounded, size: 20),
                    const SizedBox(width: 10),
                    Text(widget.isOnboarding ? 'Get Started' : 'Save Changes',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                  ]),
          ),
        ),
      ]),
    );
  }

  Widget _card(String title, {required List<Widget> children}) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 14, offset: const Offset(0, 4))],
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF1A1A1A))),
      const SizedBox(height: 14),
      ...children,
    ]),
  );

  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(text, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF555555))),
  );
}

extension _NullableExt<T> on T? {
  T? let(T? Function(T?) fn) => fn(this);
}
