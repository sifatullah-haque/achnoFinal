import 'package:achno/config/theme.dart';
import 'package:achno/providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'dart:ui';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:shared_preferences/shared_preferences.dart';
// Add imports for language provider and geolocation
import 'package:achno/providers/language_provider.dart';
import 'package:achno/l10n/app_localizations.dart';
import 'package:google_maps_webservice/places.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

class Register extends StatefulWidget {
  const Register({super.key});

  @override
  State<Register> createState() => _RegisterState();
}

class _RegisterState extends State<Register>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _cityController = TextEditingController();

  String _selectedUserType = 'Client';
  String? _selectedActivity;
  String? _selectedLanguage;
  bool _isProfessionalActivityScreen = false;

  // Google Places API client
  final places = GoogleMapsPlaces(
    apiKey: 'AIzaSyD3Mr3cCo8RIrkqbR-seZaUODMxFrfvLSI',
  );
  List<dynamic> _placePredictions = [];
  bool _isGettingLocation = false;

  final List<Map<String, dynamic>> _mainActivities = [
    {'name': 'Plumber', 'icon': Icons.plumbing},
    {'name': 'Electrician', 'icon': Icons.electrical_services},
    {'name': 'Painter', 'icon': Icons.format_paint},
    {'name': 'Carpenter', 'icon': Icons.carpenter},
    {'name': 'Mason', 'icon': Icons.domain},
    {'name': 'Tiler', 'icon': Icons.grid_on},
  ];

  final List<String> _additionalActivities = [
    'Gardener',
    'Cleaner',
    'Roofer',
    'Welder',
    'Window Installer',
    'HVAC Technician',
    'Flooring Installer',
    'Landscaper',
    'Other'
  ];

  // Available languages
  final List<Map<String, dynamic>> _languages = [
    {'code': 'en', 'name': 'English'},
    {'code': 'ar', 'name': 'العربية'},
    {'code': 'fr', 'name': 'Français'},
  ];

  bool _isLoading = false;
  String _errorMessage = '';
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.7, curve: Curves.easeOut),
      ),
    );

    _animationController.forward();

    // Set default language to system language or provider's current language
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final languageProvider =
          Provider.of<LanguageProvider>(context, listen: false);
      setState(() {
        _selectedLanguage = languageProvider.locale.languageCode;
      });
    });

    // Check if already authenticated and redirect if needed
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      // Check SharedPreferences first for faster response
      final prefs = await SharedPreferences.getInstance();
      final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;

      if (isLoggedIn) {
        // If SharedPrefs shows logged in, check with provider
        await authProvider.checkAuthStatus();
      }

      if (authProvider.isAuthenticated) {
        debugPrint(
            'Register: User is already authenticated, navigating to home');
        if (!mounted) return;
        context.go('/');
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _cityController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  bool _validateForm() {
    if (_isProfessionalActivityScreen) {
      return _selectedActivity != null;
    } else {
      return _nameController.text.isNotEmpty &&
          _phoneController.text.isNotEmpty &&
          _phoneController.text.length >= 10 &&
          _passwordController.text.isNotEmpty &&
          _passwordController.text == _confirmPasswordController.text &&
          _passwordController.text.length >= 6 &&
          _cityController.text.isNotEmpty;
    }
  }

  // Search places with Google Places API
  void _searchPlaces(String query) async {
    if (query.isEmpty) {
      setState(() {
        _placePredictions = [];
      });
      return;
    }

    try {
      PlacesAutocompleteResponse response = await places.autocomplete(
        query,
        components: [
          Component(Component.country, "ma")
        ], // Already set to "ma" for Morocco
      );

      if (response.status == "OK") {
        setState(() {
          _placePredictions = response.predictions;
        });
      } else {
        setState(() {
          _errorMessage = 'Place search failed';
          _placePredictions = [];
        });
      }
    } catch (e) {
      debugPrint('Error searching places: $e');
      setState(() {
        _errorMessage = 'Failed to search places';
        _placePredictions = [];
      });
    }
  }

  // Select place from predictions
  void _selectPlace(dynamic prediction) {
    final cityName = _extractCityName(prediction.description);
    setState(() {
      _cityController.text = cityName;
      _placePredictions = [];
    });
    FocusScope.of(context).unfocus();
  }

  // Modified helper method to extract city name with better error handling
  String _extractCityName(String fullAddress) {
    // Split the address by commas
    final parts = fullAddress.split(',');

    // Handle different address formats
    if (parts.isEmpty) return fullAddress.trim();

    if (parts.length == 1) {
      // If there's only one part, return it as the city
      return parts[0].trim();
    } else if (parts.length == 2) {
      // For two parts, the first part is usually the city
      return parts[0].trim();
    } else {
      // For longer addresses from Morocco, we typically want the first part
      // as it usually contains the locality/city
      String cityPart = parts[0].trim();

      // Remove any extra information in parentheses if present
      cityPart = cityPart.replaceAll(RegExp(r'\(.*\)'), '').trim();

      return cityPart;
    }
  }

  // Get current location
  Future<void> _getCurrentLocation() async {
    setState(() {
      _isGettingLocation = true;
      _errorMessage = '';
    });

    try {
      // Request location permission
      final permission = await Permission.location.request();
      if (permission.isDenied) {
        setState(() {
          _errorMessage = 'Location permission denied';
          _isGettingLocation = false;
        });
        return;
      }

      // Get current position
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // Use Places API to get the city name from coordinates
      final response = await places.searchNearbyWithRadius(
        Location(lat: position.latitude, lng: position.longitude),
        1000, // 1km radius
        type: "locality",
      );

      if (response.status == "OK" && response.results.isNotEmpty) {
        // Find the locality (city) in the results
        String cityName = "Unknown location";
        for (var result in response.results) {
          if (result.types.contains("locality")) {
            // Extract city name from address components
            cityName = result.name;
            break;
          }
        }

        setState(() {
          _cityController.text = cityName;
        });
      } else {
        // If no specific locality found, try reverse geocoding
        final placemarks = await places.searchNearbyWithRadius(
          Location(lat: position.latitude, lng: position.longitude),
          100,
        );

        if (placemarks.status == "OK" && placemarks.results.isNotEmpty) {
          setState(() {
            _cityController.text =
                _extractCityName(placemarks.results.first.name);
          });
        } else {
          setState(() {
            _errorMessage = 'Could not determine your city';
          });
        }
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error getting location: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isGettingLocation = false;
      });
    }
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.register(
        phoneNumber: _phoneController.text.trim(),
        password: _passwordController.text.trim(),
        firstName: _nameController.text.trim(),
        lastName: "", // Not collecting last name separately
        city: _cityController.text.trim(),
        userType: _selectedUserType,
        activity:
            _selectedUserType == 'Professional' ? _selectedActivity : null,
        isProfessional: _selectedUserType == 'Professional',
      );

      // Language is already set in the _buildLanguageSelector method,
      // so we don't need to set it again here

      if (mounted) {
        // For clients, go directly to the home page
        if (_selectedUserType == 'Client') {
          context.go('/');
        } else {
          // For professionals who completed registration, show success and go to home
          if (_isProfessionalActivityScreen) {
            // Show success dialog
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (BuildContext context) {
                return Dialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20.r),
                  ),
                  backgroundColor: Theme.of(context).colorScheme.surface,
                  child: Padding(
                    padding: EdgeInsets.all(20.w),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: EdgeInsets.all(12.w),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.check_circle_outline_rounded,
                            color: Colors.green,
                            size: 32.w,
                          ),
                        ),
                        SizedBox(height: 16.h),
                        Text(
                          'Success!',
                          style: TextStyle(
                            fontSize: 18.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 8.h),
                        Text(
                          'Account created successfully',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14.sp,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withOpacity(0.7),
                          ),
                        ),
                        SizedBox(height: 20.h),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                              context.go('/');
                            },
                            style: ElevatedButton.styleFrom(
                              padding: EdgeInsets.symmetric(vertical: 12.h),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12.r),
                              ),
                            ),
                            child: Text(
                              'Continue to App',
                              style: TextStyle(fontSize: 15.sp),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          }
        }
      }
    } on firebase_auth.FirebaseAuthException catch (e) {
      setState(() {
        switch (e.code) {
          case 'email-already-in-use':
            _errorMessage = 'This phone number is already registered.';
            break;
          case 'invalid-email':
            _errorMessage = 'The phone number is not valid.';
            break;
          case 'operation-not-allowed':
            _errorMessage = 'Phone/password accounts are not enabled.';
            break;
          case 'weak-password':
            _errorMessage = 'The password is too weak.';
            break;
          default:
            _errorMessage = 'Registration failed. Please try again.';
        }
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'An error occurred. Please try again.';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _handleContinue() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedUserType == 'Professional' && !_isProfessionalActivityScreen) {
      setState(() {
        _isProfessionalActivityScreen = true;
      });
    } else {
      _register();
    }
  }

  void _goBack() {
    if (_isProfessionalActivityScreen) {
      setState(() {
        _isProfessionalActivityScreen = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Stack(
        children: [
          // Background design elements
          Positioned(
            top: -70.h,
            left: -40.w,
            child: Container(
              width: 170.w,
              height: 170.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.primaryColor.withOpacity(0.07),
              ),
            ),
          ),
          Positioned(
            bottom: -60.h,
            right: -30.w,
            child: Container(
              width: 160.w,
              height: 160.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.accentColor.withOpacity(0.09),
              ),
            ),
          ),
          // Decorative elements
          Positioned(
            top: size.height * 0.3,
            right: 30.w,
            child: Container(
              width: 15.w,
              height: 15.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.darkAccentColor.withOpacity(0.2),
              ),
            ),
          ),
          Positioned(
            bottom: size.height * 0.25,
            left: 40.w,
            child: Container(
              width: 12.w,
              height: 12.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.primaryColor.withOpacity(0.15),
              ),
            ),
          ),

          // Main content
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                    horizontal: 20.w,
                    vertical: 12.h), // Slightly increased padding
                child: AnimatedBuilder(
                  animation: _animationController,
                  builder: (context, child) {
                    return Opacity(
                      opacity: _fadeAnimation.value,
                      child: child,
                    );
                  },
                  child: Container(
                    padding: EdgeInsets.all(24.w), // Slightly increased padding
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius:
                          BorderRadius.circular(20.r), // Larger radius
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 20,
                          spreadRadius: 0,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    width: size.width,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Header with back button - only shown on activity selection screen
                        Row(
                          children: [
                            if (_isProfessionalActivityScreen)
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.grey[100],
                                  borderRadius: BorderRadius.circular(10.r),
                                ),
                                child: IconButton(
                                  icon: Icon(
                                    Icons.arrow_back_ios_rounded,
                                    size: 18.w,
                                    color: AppTheme.textPrimaryColor,
                                  ),
                                  onPressed: _goBack,
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  visualDensity: VisualDensity.compact,
                                ),
                              ),
                            Expanded(
                              child: Center(
                                child: Text(
                                  _isProfessionalActivityScreen
                                      ? "Select Your Activity"
                                      : "Create Account",
                                  style: TextStyle(
                                    fontSize: 18.sp, // Slightly larger font
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.textPrimaryColor,
                                  ),
                                ),
                              ),
                            ),
                            // Add a spacer on the right for alignment when back button is shown
                            if (_isProfessionalActivityScreen)
                              SizedBox(width: 24.w)
                            else
                              const SizedBox(width: 0),
                          ],
                        ),

                        SizedBox(height: 16.h), // Slightly increased spacing

                        // App logo with gradient
                        // Container(
                        //   width: 60.w, // Slightly larger logo
                        //   height: 60.w,
                        //   decoration: BoxDecoration(
                        //     shape: BoxShape.circle,
                        //     gradient: LinearGradient(
                        //       colors: [
                        //         AppTheme.primaryColor.withOpacity(0.1),
                        //         AppTheme.accentColor.withOpacity(0.2),
                        //       ],
                        //       begin: Alignment.topLeft,
                        //       end: Alignment.bottomRight,
                        //     ),
                        //     boxShadow: [
                        //       BoxShadow(
                        //         color: AppTheme.primaryColor.withOpacity(0.2),
                        //         blurRadius: 10,
                        //         offset: const Offset(0, 4),
                        //       ),
                        //     ],
                        //   ),
                        //   child: Icon(
                        //     Icons.eco_outlined,
                        //     size: 30.w, // Slightly larger icon
                        //     color: AppTheme.primaryColor,
                        //   ),
                        // ),
                        Image.asset(
                          'assets/logo.png',
                          width: 60.w, // Slightly larger logo
                          height: 60.w,
                        ),

                        SizedBox(height: 20.h), // Slightly increased spacing

                        // Form content
                        Form(
                          key: _formKey,
                          child: _isProfessionalActivityScreen
                              ? _buildProfessionSelection()
                              : _buildRegistrationForm(),
                        ),

                        // Error message
                        if (_errorMessage.isNotEmpty)
                          Padding(
                            padding: EdgeInsets.only(
                                top: 16.h,
                                bottom: 8.h), // Slightly increased padding
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                  vertical: 10.h, horizontal: 12.w),
                              decoration: BoxDecoration(
                                color: Colors.red.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12.r),
                                border: Border.all(
                                  color: Colors.red.withOpacity(0.3),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.error_outline_rounded,
                                    color: Colors.red,
                                    size: 18.w, // Slightly larger icon
                                  ),
                                  SizedBox(width: 8.w),
                                  Flexible(
                                    child: Text(
                                      _errorMessage,
                                      style: TextStyle(
                                        color: Colors.red,
                                        fontSize: 12.sp, // Slightly larger font
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                        SizedBox(height: 20.h), // Slightly increased spacing

                        // Action button with gradient
                        _buildActionButton(),

                        SizedBox(height: 20.h), // Slightly increased spacing

                        // Login link
                        if (!_isProfessionalActivityScreen)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                l10n.alreadyMember,
                                style: TextStyle(
                                  fontSize: 13.sp, // Slightly larger font
                                  color: AppTheme.textSecondaryColor,
                                ),
                              ),
                              TextButton(
                                onPressed: () => context.go('/login'),
                                style: TextButton.styleFrom(
                                  foregroundColor: AppTheme.primaryColor,
                                  padding:
                                      EdgeInsets.symmetric(horizontal: 8.w),
                                  minimumSize: Size(0, 30.h),
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: Text(
                                  l10n.signIn,
                                  style: TextStyle(
                                    fontSize: 13.sp, // Slightly larger font
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRegistrationForm() {
    final l10n = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Full Name field
        _buildTextField(
          controller: _nameController,
          labelText: l10n.fullName,
          prefixIcon: Icons.person_outline_rounded,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return l10n.pleaseEnterName;
            }
            return null;
          },
        ),

        SizedBox(height: 10.h), // Reduced spacing

        // Phone Number field
        _buildTextField(
          controller: _phoneController,
          labelText: l10n.phoneNumber,
          prefixIcon: Icons.phone_outlined,
          keyboardType: TextInputType.phone,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return l10n.pleaseEnterPhone;
            }
            if (value.length < 10) {
              return l10n.invalidPhoneNumber;
            }
            return null;
          },
        ),

        SizedBox(height: 10.h), // Reduced spacing

        // Password field
        _buildTextField(
          controller: _passwordController,
          labelText: l10n.password,
          prefixIcon: Icons.lock_outline_rounded,
          obscureText: _obscurePassword,
          suffixIcon: IconButton(
            icon: Icon(
              _obscurePassword
                  ? Icons.visibility_rounded
                  : Icons.visibility_off_rounded,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              size: 18.w, // Smaller icon
            ),
            padding: const EdgeInsets.all(0), // Remove padding
            constraints: const BoxConstraints(), // Remove constraints
            onPressed: () {
              setState(() {
                _obscurePassword = !_obscurePassword;
              });
            },
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return l10n.pleaseEnterPassword;
            }
            if (value.length < 6) {
              return l10n.passwordMinLength;
            }
            return null;
          },
        ),

        SizedBox(height: 10.h), // Reduced spacing

        // Confirm Password field
        _buildTextField(
          controller: _confirmPasswordController,
          labelText: l10n.confirmPassword,
          prefixIcon: Icons.lock_outline_rounded,
          obscureText: _obscureConfirmPassword,
          suffixIcon: IconButton(
            icon: Icon(
              _obscureConfirmPassword
                  ? Icons.visibility_rounded
                  : Icons.visibility_off_rounded,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              size: 18.w, // Smaller icon
            ),
            padding: const EdgeInsets.all(0), // Remove padding
            constraints: const BoxConstraints(), // Remove constraints
            onPressed: () {
              setState(() {
                _obscureConfirmPassword = !_obscureConfirmPassword;
              });
            },
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return l10n.pleaseConfirmPassword;
            }
            if (value != _passwordController.text) {
              return l10n.passwordsDoNotMatch;
            }
            return null;
          },
        ),

        // City field with search and geolocation
        _buildCityField(l10n.city),

        SizedBox(height: 10.h), // Reduced spacing

        // Language selector
        _buildLanguageSelector(l10n.preferredLanguage),

        SizedBox(height: 16.h), // Reduced spacing

        // User type selection
        Text(
          l10n.iAm,
          style: TextStyle(
            fontSize: 14.sp, // Smaller font
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 8.h), // Reduced spacing
        Row(
          children: [
            Expanded(
              child: _buildUserTypeButton(l10n.client, 'Client'),
            ),
            SizedBox(width: 10.w), // Reduced spacing
            Expanded(
              child: _buildUserTypeButton(l10n.professional, 'Professional'),
            ),
          ],
        ),
      ],
    );
  }

  // New method for language selector
  Widget _buildLanguageSelector(String labelText) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          labelText,
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 8.h),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14.r),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14.r),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[50],
                border: Border.all(
                  color: Colors.grey[200]!,
                  width: 1,
                ),
                borderRadius: BorderRadius.circular(14.r),
              ),
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: _languages.map((language) {
                  final isSelected = _selectedLanguage == language['code'];
                  return GestureDetector(
                    onTap: () {
                      // Get the language provider and update it immediately
                      final languageProvider =
                          Provider.of<LanguageProvider>(context, listen: false);
                      final String languageCode = language['code'] as String;

                      // Update both the UI state and the app's language
                      setState(() {
                        _selectedLanguage = languageCode;
                      });

                      // Apply the language change immediately
                      languageProvider.setLocale(Locale(languageCode));
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding:
                          EdgeInsets.symmetric(vertical: 8.h, horizontal: 16.w),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppTheme.primaryColor
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(10.r),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: AppTheme.primaryColor.withOpacity(0.3),
                                  blurRadius: 6,
                                  spreadRadius: 0,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : null,
                      ),
                      child: Text(
                        language['name'],
                        style: TextStyle(
                          fontSize: 13.sp,
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected
                              ? Colors.white
                              : AppTheme.textPrimaryColor,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // New method for city field with search and geolocation
  Widget _buildCityField(String labelText) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14.r),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: TextFormField(
            controller: _cityController,
            style: TextStyle(
              fontSize: 15.sp,
              color: AppTheme.textPrimaryColor,
            ),
            decoration: InputDecoration(
              labelText: labelText,
              labelStyle: TextStyle(
                color: AppTheme.textSecondaryColor,
                fontSize: 13.sp,
              ),
              prefixIcon: Icon(
                Icons.location_city_outlined,
                size: 20.w,
                color: AppTheme.textSecondaryColor,
              ),
              suffixIcon: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Clear button - only show when there's text
                  if (_cityController.text.isNotEmpty)
                    IconButton(
                      icon: Icon(
                        Icons.clear,
                        size: 16.w,
                        color: AppTheme.textSecondaryColor,
                      ),
                      onPressed: () {
                        setState(() {
                          _cityController.clear();
                          _placePredictions = [];
                        });
                      },
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      visualDensity: VisualDensity.compact,
                    ),
                  // Get current location button
                  IconButton(
                    icon: _isGettingLocation
                        ? SizedBox(
                            width: 16.w,
                            height: 16.w,
                            child: const CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation(AppTheme.primaryColor),
                            ),
                          )
                        : Icon(
                            Icons.my_location,
                            size: 16.w,
                            color: AppTheme.primaryColor,
                          ),
                    onPressed: _isGettingLocation ? null : _getCurrentLocation,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
              filled: true,
              fillColor: Colors.grey[50],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14.r),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14.r),
                borderSide: BorderSide(
                  color: Colors.grey[200]!,
                  width: 1,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14.r),
                borderSide: BorderSide(
                  color: AppTheme.primaryColor.withOpacity(0.5),
                  width: 1.5,
                ),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14.r),
                borderSide: BorderSide(
                  color: Colors.red.withOpacity(0.5),
                  width: 1,
                ),
              ),
              contentPadding:
                  EdgeInsets.symmetric(vertical: 14.h, horizontal: 18.w),
              isDense: true,
            ),
            onChanged: _searchPlaces,
            validator: (value) {
              final l10n = AppLocalizations.of(context);
              if (value == null || value.isEmpty) {
                return l10n.pleaseEnterCity;
              }
              return null;
            },
          ),
        ),

        // Place predictions dropdown
        if (_placePredictions.isNotEmpty)
          Container(
            margin: EdgeInsets.only(top: 4.h),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12.r),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
              border: Border.all(
                color: Colors.grey[200]!,
                width: 1,
              ),
            ),
            constraints: BoxConstraints(maxHeight: 150.h),
            child: ListView.builder(
              padding: EdgeInsets.zero,
              shrinkWrap: true,
              itemCount:
                  _placePredictions.length > 5 ? 5 : _placePredictions.length,
              itemBuilder: (context, index) {
                final prediction = _placePredictions[index];
                return Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => _selectPlace(prediction),
                    child: Padding(
                      padding:
                          EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                      child: Row(
                        children: [
                          Icon(
                            Icons.location_on_outlined,
                            size: 16.w,
                            color: AppTheme.primaryColor,
                          ),
                          SizedBox(width: 8.w),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  prediction.structuredFormatting?.mainText ??
                                      prediction.description.split(',').first,
                                  style: TextStyle(
                                    fontSize: 13.sp,
                                    color: AppTheme.textPrimaryColor,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (prediction
                                        .structuredFormatting?.secondaryText !=
                                    null)
                                  Text(
                                    prediction
                                        .structuredFormatting!.secondaryText!,
                                    style: TextStyle(
                                      fontSize: 11.sp,
                                      color: AppTheme.textSecondaryColor,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildProfessionSelection() {
    final l10n = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.chooseProfession,
          style: TextStyle(
            fontSize: 14.sp, // Smaller font
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 12.h), // Reduced spacing

        // Grid of profession cards with reduced spacing
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3, // 3 columns for more compact layout
            childAspectRatio: 0.9, // Adjusted ratio for smaller cards
            crossAxisSpacing: 8.w, // Reduced spacing
            mainAxisSpacing: 8.h, // Reduced spacing
          ),
          itemCount: _mainActivities.length,
          itemBuilder: (context, index) {
            final activity = _mainActivities[index];
            return _buildActivityCard(
              activity['name'],
              activity['icon'],
            );
          },
        ),

        SizedBox(height: 16.h), // Reduced spacing

        // Dropdown for other activities
        _buildDropdownField(
          labelText: l10n.selectOtherActivity,
          prefixIcon: Icons.work_outline_rounded,
          value: _additionalActivities.contains(_selectedActivity)
              ? _selectedActivity
              : null,
          items: _additionalActivities.map((String activity) {
            return DropdownMenuItem<String>(
              value: activity,
              child: Text(activity,
                  style: TextStyle(fontSize: 13.sp)), // Smaller font
            );
          }).toList(),
          onChanged: (String? newValue) {
            setState(() {
              _selectedActivity = newValue;
            });
          },
          validator: (value) => null, // Optional for this field
        ),
      ],
    );
  }

  Widget _buildActivityCard(String name, IconData icon) {
    final isSelected = _selectedActivity == name;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedActivity = name;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor : Colors.white,
          borderRadius: BorderRadius.circular(12.r), // Smaller radius
          border: Border.all(
            color: isSelected ? AppTheme.primaryColor : Colors.grey[200]!,
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppTheme.primaryColor.withOpacity(0.3),
                    blurRadius: 6,
                    spreadRadius: 0,
                    offset: const Offset(0, 2),
                  )
                ]
              : [],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 24.w, // Smaller icon
              color: isSelected ? Colors.white : AppTheme.textPrimaryColor,
            ),
            SizedBox(height: 4.h), // Reduced spacing
            Text(
              name,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11.sp, // Smaller font
                fontWeight: FontWeight.w500,
                color: isSelected ? Colors.white : AppTheme.textPrimaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserTypeButton(String displayText, String type) {
    final isSelected = _selectedUserType == type;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedUserType = type;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(vertical: 8.h), // Reduced padding
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor : Colors.grey[50],
          borderRadius: BorderRadius.circular(12.r), // Smaller radius
          border: Border.all(
            color: isSelected ? AppTheme.primaryColor : Colors.grey[200]!,
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppTheme.primaryColor.withOpacity(0.3),
                    blurRadius: 6,
                    spreadRadius: 0,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [],
        ),
        alignment: Alignment.center,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              type == 'Client' ? Icons.person : Icons.work,
              color: isSelected ? Colors.white : AppTheme.textPrimaryColor,
              size: 16.w, // Smaller icon
            ),
            SizedBox(width: 4.w), // Reduced spacing
            Text(
              displayText,
              style: TextStyle(
                fontSize: 12.sp, // Smaller font
                fontWeight: FontWeight.w500,
                color: isSelected ? Colors.white : AppTheme.textPrimaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String labelText,
    required IconData prefixIcon,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
    Widget? suffixIcon,
    required String? Function(String?) validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        style: TextStyle(
          fontSize: 15.sp, // Slightly larger font
          color: AppTheme.textPrimaryColor,
        ),
        decoration: InputDecoration(
          labelText: labelText,
          labelStyle: TextStyle(
            color: AppTheme.textSecondaryColor,
            fontSize: 13.sp, // Slightly larger font
          ),
          prefixIcon: Icon(
            prefixIcon,
            size: 20.w, // Slightly larger icon
            color: AppTheme.textSecondaryColor,
          ),
          prefixIconConstraints: BoxConstraints(
              minWidth: 40.w, minHeight: 40.h), // Slightly larger constraints
          suffixIcon: suffixIcon,
          suffixIconConstraints: suffixIcon != null
              ? BoxConstraints(minWidth: 40.w, minHeight: 40.h)
              : null,
          filled: true,
          fillColor: Colors.grey[50],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14.r), // Larger radius
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14.r),
            borderSide: BorderSide(
              color: Colors.grey[200]!,
              width: 1,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14.r),
            borderSide: BorderSide(
              color: AppTheme.primaryColor.withOpacity(0.5),
              width: 1.5,
            ),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14.r),
            borderSide: BorderSide(
              color: Colors.red.withOpacity(0.5),
              width: 1,
            ),
          ),
          contentPadding: EdgeInsets.symmetric(
              vertical: 14.h, horizontal: 18.w), // Slightly increased padding
          isDense: true,
          errorStyle: TextStyle(fontSize: 11.sp), // Slightly larger error text
        ),
        validator: validator,
      ),
    );
  }

  Widget _buildDropdownField({
    required String labelText,
    required IconData prefixIcon,
    required String? value,
    required List<DropdownMenuItem<String>> items,
    required void Function(String?) onChanged,
    required String? Function(String?) validator,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      style: TextStyle(
        fontSize: 14.sp, // Smaller font
        color: AppTheme.textPrimaryColor,
      ),
      decoration: InputDecoration(
        labelText: labelText,
        labelStyle: TextStyle(
          color: AppTheme.textSecondaryColor,
          fontSize: 12.sp, // Smaller font
        ),
        prefixIcon: Icon(
          prefixIcon,
          size: 18.w, // Smaller icon
          color: AppTheme.textSecondaryColor,
        ),
        prefixIconConstraints: BoxConstraints(
            minWidth: 36.w, minHeight: 36.h), // Smaller constraints
        filled: true,
        fillColor: Colors.grey[50],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r), // Smaller radius
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide(
            color: Colors.grey[200]!,
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide(
            color: AppTheme.primaryColor.withOpacity(0.5),
            width: 1.5,
          ),
        ),
        contentPadding: EdgeInsets.symmetric(
            vertical: 10.h, horizontal: 16.w), // Reduced padding
        isDense: true, // Make the field more compact
      ),
      items: items,
      onChanged: onChanged,
      validator: validator,
      dropdownColor: Colors.white,
      icon: Icon(
        Icons.arrow_drop_down_rounded,
        size: 20.w, // Smaller icon
        color: AppTheme.textSecondaryColor,
      ),
      isExpanded: true,
      menuMaxHeight: 200.h, // Limit menu height
      hint: Text(
        "Select an option",
        style: TextStyle(
          fontSize: 12.sp, // Smaller font
          color: AppTheme.textSecondaryColor.withOpacity(0.5),
        ),
      ),
    );
  }

  Widget _buildActionButton() {
    final l10n = AppLocalizations.of(context);
    final buttonText = _isProfessionalActivityScreen
        ? l10n.completeRegistration
        : l10n.continue_;

    return Container(
      width: double.infinity,
      height: 50.h, // Slightly larger height
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.primaryColor, AppTheme.darkAccentColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14.r), // Larger radius
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.35),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _isLoading ? null : _handleContinue,
          borderRadius: BorderRadius.circular(14.r),
          splashColor: Colors.white.withOpacity(0.2),
          highlightColor: Colors.transparent,
          child: Center(
            child: _isLoading
                ? SizedBox(
                    height: 22.h, // Slightly larger loading indicator
                    width: 22.w,
                    child: const CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Colors.white,
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        buttonText,
                        style: TextStyle(
                          fontSize: 16.sp, // Slightly larger font
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(width: 8.w), // Slightly increased spacing
                      Icon(
                        _isProfessionalActivityScreen
                            ? Icons.check
                            : Icons.arrow_forward_rounded,
                        color: Colors.white,
                        size: 18.w, // Slightly larger icon
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
