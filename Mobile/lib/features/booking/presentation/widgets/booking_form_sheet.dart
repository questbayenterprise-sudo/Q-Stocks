import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../My Venues/domain/entities/venue.dart';
import '../../../venues/domain/entities/venue.dart';
import '../../../auth/Session/user_session.dart';
import '../bloc/booking_bloc.dart';
import '../widgets/slot_booking_page.dart';

import '../../domain/entities/booking_info.dart';

class BookingFormSheet extends StatefulWidget {
  final VenueEntity venue;
  const BookingFormSheet({super.key, required this.venue});

  @override
  State<BookingFormSheet> createState() => _BookingFormSheetState();
}

class _BookingFormSheetState extends State<BookingFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _mobileController = TextEditingController();

  bool _isEmailValid = false;
  bool _isNameValid = false;
  bool _isMobileValid = false;

  @override
  void initState() {
    super.initState();
    // Pre-fill name from session
    final session = UserSession();
    if (session.username != null && session.username!.isNotEmpty) {
      _firstNameController.text = session.username!;
    }
    _emailController.addListener(_validateFields);
    _firstNameController.addListener(_validateFields);
    _mobileController.addListener(_validateFields);
    _validateFields();
  }

  void _validateFields() {
    final emailRegex = RegExp(
      r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+",
    );

    setState(() {
      _isEmailValid = emailRegex.hasMatch(_emailController.text);
      _isNameValid = _firstNameController.text.isNotEmpty;
      _isMobileValid = _mobileController.text.length == 10;
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _firstNameController.dispose();
    _mobileController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 12,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const Text(
                "What Can We Call You?",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 30),

              _buildTextField("Name*", _firstNameController),
              _buildTextField(
                "Email ID*",
                _emailController,
                keyboardType: TextInputType.emailAddress,
              ),
              _buildTextField(
                "Mobile Number*",
                _mobileController,
                keyboardType: TextInputType.phone,
                isPhone: true,
              ),

              const SizedBox(height: 10),

              BlocConsumer<BookingBloc, BookingState>(
                listener: (context, state) {
                  if (state is BookingSuccess) {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SlotBookingPage(
                          firstName: _firstNameController.text,
                          email: _emailController.text,
                          mobile: _mobileController.text,
                          venueId: widget.venue.id, // Pass from widget
                          price: widget.venue.price
                              .toString(), // Pass from widget
                        ),
                      ),
                    );
                  }
                  if (state is BookingError) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(state.message),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
                builder: (context, state) {
                  // Button is enabled ONLY if email is valid AND not loading
                  final bool canSubmit =
                      _isEmailValid &&
                      _isNameValid &&
                      _isMobileValid &&
                      state is! BookingLoading;

                  return ElevatedButton(
                    onPressed: canSubmit ? _onReadyPressed : null,
                    style: ElevatedButton.styleFrom(
                      // Toggle color based on state
                      backgroundColor: canSubmit
                          ? const Color(0xFF00A36C)
                          : const Color(0xFFF2F2F2),
                      foregroundColor: canSubmit ? Colors.white : Colors.grey,
                      minimumSize: const Size(double.infinity, 56),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: state is BookingLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            "I'M READY",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: canSubmit
                                  ? Colors.white
                                  : Colors.grey[400],
                            ),
                          ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Same helper as before
  Widget _buildTextField(
    String label,
    TextEditingController controller, {
    TextInputType? keyboardType,
    bool isPhone = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 14)),
          const SizedBox(height: 8),
          TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            decoration: InputDecoration(
              prefixIcon: isPhone ? _buildPhonePrefix() : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhonePrefix() {
    return Container(
      width: 90,
      padding: const EdgeInsets.only(left: 12),
      child: Row(
        children: [
          const Text(
            "+91",
            style: TextStyle(fontSize: 16, color: Colors.black),
          ),
          const SizedBox(width: 8),
          Image.network('https://flagcdn.com/w20/in.png', width: 20),
          const SizedBox(width: 8),
          Container(width: 1, height: 24, color: Colors.grey[300]),
        ],
      ),
    );
  }

  void _onReadyPressed() {
    final info = BookingInfo(
      firstName: _firstNameController.text,
      lastName: '',
      email: _emailController.text,
      phoneNumber: _mobileController.text,
    );
    // This triggers the API call via BLoC
    context.read<BookingBloc>().add(SubmitBookingForm(info));
  }
}

class MyBookingFormSheet extends StatefulWidget {
  final MyVenueEntity venue; // Added
  const MyBookingFormSheet({super.key, required this.venue});

  @override
  State<MyBookingFormSheet> createState() => _MyBookingFormSheetState();
}

class _MyBookingFormSheetState extends State<MyBookingFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _mobileController = TextEditingController();

  bool _isEmailValid = false;
  bool _isNameValid = false;
  bool _isMobileValid = false;

  @override
  void initState() {
    super.initState();
    final session = UserSession();
    if (session.username != null && session.username!.isNotEmpty) {
      _firstNameController.text = session.username!;
    }
    _emailController.addListener(_validateFields);
    _firstNameController.addListener(_validateFields);
    _mobileController.addListener(_validateFields);
    _validateFields();
  }

  void _validateFields() {
    final emailRegex = RegExp(
      r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+",
    );

    setState(() {
      _isEmailValid = emailRegex.hasMatch(_emailController.text);
      _isNameValid = _firstNameController.text.isNotEmpty;
      _isMobileValid = _mobileController.text.length == 10;
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _firstNameController.dispose();
    _mobileController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 12,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const Text(
                "What Can We Call You?",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 30),

              _buildTextField("Name*", _firstNameController),
              _buildTextField(
                "Email ID*",
                _emailController,
                keyboardType: TextInputType.emailAddress,
              ),
              _buildTextField(
                "Mobile Number*",
                _mobileController,
                keyboardType: TextInputType.phone,
                isPhone: true,
              ),

              const SizedBox(height: 10),

              BlocConsumer<BookingBloc, BookingState>(
                listener: (context, state) {
                  if (state is BookingSuccess) {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SlotBookingPage(
                          firstName: _firstNameController.text,
                          email: _emailController.text,
                          mobile: _mobileController.text,
                          venueId: widget.venue.id, // Pass from widget
                          price: widget.venue.price
                              .toString(), // Pass from widget
                        ),
                      ),
                    );
                  }
                  if (state is BookingError) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(state.message),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
                builder: (context, state) {
                  // Button is enabled ONLY if email is valid AND not loading
                  final bool canSubmit =
                      _isEmailValid &&
                      _isNameValid &&
                      _isMobileValid &&
                      state is! BookingLoading;

                  return ElevatedButton(
                    onPressed: canSubmit ? _onReadyPressed : null,
                    style: ElevatedButton.styleFrom(
                      // Toggle color based on state
                      backgroundColor: canSubmit
                          ? const Color(0xFF00A36C)
                          : const Color(0xFFF2F2F2),
                      foregroundColor: canSubmit ? Colors.white : Colors.grey,
                      minimumSize: const Size(double.infinity, 56),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: state is BookingLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            "I'M READY",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: canSubmit
                                  ? Colors.white
                                  : Colors.grey[400],
                            ),
                          ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Same helper as before
  Widget _buildTextField(
    String label,
    TextEditingController controller, {
    TextInputType? keyboardType,
    bool isPhone = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 14)),
          const SizedBox(height: 8),
          TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            decoration: InputDecoration(
              prefixIcon: isPhone ? _buildPhonePrefix() : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhonePrefix() {
    return Container(
      width: 90,
      padding: const EdgeInsets.only(left: 12),
      child: Row(
        children: [
          const Text(
            "+91",
            style: TextStyle(fontSize: 16, color: Colors.black),
          ),
          const SizedBox(width: 8),
          Image.network('https://flagcdn.com/w20/in.png', width: 20),
          const SizedBox(width: 8),
          Container(width: 1, height: 24, color: Colors.grey[300]),
        ],
      ),
    );
  }

  void _onReadyPressed() {
    final info = BookingInfo(
      firstName: _firstNameController.text,
      lastName: '',
      email: _emailController.text,
      phoneNumber: _mobileController.text,
    );
    // This triggers the API call via BLoC
    context.read<BookingBloc>().add(SubmitBookingForm(info));
  }
}
