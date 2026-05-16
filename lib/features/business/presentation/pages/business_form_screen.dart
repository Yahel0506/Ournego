import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_animations/flutter_map_animations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import 'package:ournego/core/failures.dart';
import 'package:ournego/core/location/app_position.dart';
import 'package:ournego/core/location/geolocator_location_datasource.dart';
import 'package:ournego/core/location/location_datasource.dart';
import 'package:ournego/core/mapbox_config.dart';
import 'package:ournego/core/ournego_text_styles.dart';
import 'package:ournego/core/theme/tokens/ournego_color_tokens.dart';
import 'package:ournego/features/business/domain/entities/business_image_data.dart';
import 'package:ournego/features/business/domain/usecases/get_addresses_suggestions_usecase.dart';
import 'package:ournego/features/business/presentation/pages/components/business_hours_picker.dart';
import 'package:ournego/features/feedback/presentation/widgets/feedback_dialog_widget.dart';
import 'package:ournego/features/navigation/presentation/providers/navigation_provider.dart';
import 'package:ournego/shared/widgets/animated_background.dart';
import 'package:ournego/shared/widgets/information_card_widget.dart';
import 'package:ournego/shared/widgets/ournego_alert_dialog.dart';
import 'package:ournego/shared/widgets/ournego_information_dialog.dart';
import 'package:ournego/shared/widgets/ournego_inputs.dart';
import 'package:ournego/shared/widgets/ournego_snackbars.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/entities/app_schedule.dart';
import '../providers/business_providers.dart';

final _businessLocationDatasourceProvider = Provider<LocationDatasource>(
  (ref) => GeolocatorLocationDatasource(),
);

final _businessCurrentLocationProvider = FutureProvider<AppPosition>((
  ref,
) async {
  final datasource = ref.watch(_businessLocationDatasourceProvider);
  return datasource.getCurrentLocation();
});

class BusinessFormScreen extends ConsumerStatefulWidget {
  const BusinessFormScreen({super.key});

  @override
  ConsumerState<BusinessFormScreen> createState() => _BusinessFormScreenState();
}

class _BusinessFormScreenState extends ConsumerState<BusinessFormScreen>
    with TickerProviderStateMixin {
  static const _genericBusinessErrorImage = 'assets/images/generic_error.png';
  static const _draftNameKey = 'business_form_draft_name';
  static const _draftDescriptionKey = 'business_form_draft_description';
  static const _draftAddressKey = 'business_form_draft_address';
  static const _draftPhoneKey = 'business_form_draft_phone';
  static const _draftCategoryKey = 'business_form_draft_category';
  static const _draftImageBytesKey = 'business_form_draft_image_bytes';
  static const _draftImageNameKey = 'business_form_draft_image_name';
  static const _draftImageMimeTypeKey = 'business_form_draft_image_mime_type';
  static const _draftLatitudeKey = 'business_form_draft_latitude';
  static const _draftLongitudeKey = 'business_form_draft_longitude';

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _addressController = TextEditingController();
  final _addressFocusNode = FocusNode();
  late final _animatedMapController = AnimatedMapController(vsync: this);
  late ProviderSubscription<AsyncValue<AppPosition>> _providerSubscription;
  final _picker = ImagePicker();
  Uint8List? _pickedImageBytes;
  String _pickedImageName = '';
  String? _pickedImageMimeType;
  // TODO: re-enable business hours picker and collect schedules via callbacks
  // or a Riverpod notifier instead of querying child widget state.
  int? _selectedCategory = 0; // 0 - 12
  final _phoneController = TextEditingController();
  final _isSending = ValueNotifier<bool>(false);

  final Map<int, AppSchedule?> _hoursByDay = <int, AppSchedule?>{};

  final ScrollController _scrollController = ScrollController();
  bool _isHydratingDraft = false;

  Future<void> _persistDraft() async {
    if (_isHydratingDraft) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_draftNameKey, _nameController.text);
    await prefs.setString(_draftDescriptionKey, _descriptionController.text);
    await prefs.setString(_draftAddressKey, _addressController.text);
    await prefs.setString(_draftPhoneKey, _phoneController.text);
    await prefs.setInt(_draftCategoryKey, _selectedCategory ?? 0);
    if (_pickedImageBytes != null && _pickedImageBytes!.isNotEmpty) {
      await prefs.setString(
        _draftImageBytesKey,
        base64Encode(_pickedImageBytes!),
      );
      await prefs.setString(_draftImageNameKey, _pickedImageName);
      await prefs.setString(_draftImageMimeTypeKey, _pickedImageMimeType ?? '');
    } else {
      await prefs.remove(_draftImageBytesKey);
      await prefs.remove(_draftImageNameKey);
      await prefs.remove(_draftImageMimeTypeKey);
    }

    final camera = _animatedMapController.mapController.camera;
    if (camera.zoom > 0) {
      await prefs.setDouble(_draftLatitudeKey, camera.center.latitude);
      await prefs.setDouble(_draftLongitudeKey, camera.center.longitude);
    }
  }

  void _onBusinessScheduleChanged(int dayOfWeek, AppSchedule? schedule) {
    _hoursByDay[dayOfWeek] = schedule;
  }

  Future<void> _clearDraft() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_draftNameKey);
    await prefs.remove(_draftDescriptionKey);
    await prefs.remove(_draftAddressKey);
    await prefs.remove(_draftPhoneKey);
    await prefs.remove(_draftCategoryKey);
    await prefs.remove(_draftImageBytesKey);
    await prefs.remove(_draftImageNameKey);
    await prefs.remove(_draftImageMimeTypeKey);
    await prefs.remove(_draftLatitudeKey);
    await prefs.remove(_draftLongitudeKey);
  }

  Future<void> _loadDraft() async {
    _isHydratingDraft = true;

    final prefs = await SharedPreferences.getInstance();
    final draftName = prefs.getString(_draftNameKey) ?? '';
    final draftDescription = prefs.getString(_draftDescriptionKey) ?? '';
    final draftAddress = prefs.getString(_draftAddressKey) ?? '';
    final draftPhone = prefs.getString(_draftPhoneKey) ?? '';
    final draftCategory = prefs.getInt(_draftCategoryKey);
    final draftImageBase64 = prefs.getString(_draftImageBytesKey) ?? '';
    final draftImageName = prefs.getString(_draftImageNameKey) ?? '';
    final draftImageMimeType = prefs.getString(_draftImageMimeTypeKey) ?? '';
    final draftLatitude = prefs.getDouble(_draftLatitudeKey);
    final draftLongitude = prefs.getDouble(_draftLongitudeKey);

    if (!mounted) {
      _isHydratingDraft = false;
      return;
    }

    _nameController.text = draftName;
    _descriptionController.text = draftDescription;
    _addressController.text = draftAddress;
    _phoneController.text = draftPhone;

    if (draftCategory != null) {
      _selectedCategory = draftCategory;
    }

    if (draftImageBase64.isNotEmpty) {
      try {
        _pickedImageBytes = base64Decode(draftImageBase64);
        _pickedImageName = draftImageName;
        _pickedImageMimeType = draftImageMimeType.isEmpty
            ? null
            : draftImageMimeType;
      } catch (_) {
        _pickedImageBytes = null;
        _pickedImageName = '';
        _pickedImageMimeType = null;
      }
    }

    setState(() {});

    if (draftLatitude != null && draftLongitude != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _animatedMapController.animateTo(
          dest: LatLng(draftLatitude, draftLongitude),
          zoom: 16,
        );
      });
    }

    _isHydratingDraft = false;
  }

  void _attachDraftListeners() {
    _nameController.addListener(_persistDraft);
    _descriptionController.addListener(_persistDraft);
    _addressController.addListener(_persistDraft);
    _phoneController.addListener(_persistDraft);
  }

  _BusinessRegistrationErrorContent _mapFailureToDialog(Failure failure) {
    if (failure is AuthenticationRequiredFailure) {
      return const _BusinessRegistrationErrorContent(
        title: 'Necesitas iniciar sesion',
        description:
            'Inicia sesion para poder registrar un negocio o usar autocompletado de direccion.',
      );
    }

    if (failure is BusinessRegistrationUnauthorizedFailure) {
      return const _BusinessRegistrationErrorContent(
        title: 'No tienes permisos para registrar un negocio',
        description:
            'Tu sesión no tiene permisos para escribir en una tabla protegida (RLS). Inicia sesión nuevamente o solicita habilitar políticas de business_hours en Supabase.',
      );
    }

    if (failure is BusinessRegistrationValidationFailure) {
      return const _BusinessRegistrationErrorContent(
        title: 'Hay datos invalidos en el registro',
        description:
            'Revisa nombre, direccion, categoria e imagen. Luego vuelve a intentar.',
      );
    }

    if (failure is BusinessRegistrationDuplicateFailure) {
      return const _BusinessRegistrationErrorContent(
        title: 'Este negocio ya existe',
        description:
            'Parece que ya hay un registro similar. Verifica la informacion o usa otro nombre.',
      );
    }

    if (failure is BusinessRegistrationImageUploadFailure) {
      return const _BusinessRegistrationErrorContent(
        title: 'No se pudo subir la imagen del negocio',
        description:
            'Intenta con otra imagen o verifica tu conexion y vuelve a intentar.',
      );
    }

    if (failure is BusinessRegistrationNetworkFailure) {
      return const _BusinessRegistrationErrorContent(
        title: 'No hay conexion para registrar el negocio',
        description:
            'Verifica tu internet y vuelve a intentarlo. Tu formulario se mantuvo guardado.',
      );
    }

    if (failure is BusinessRegistrationUnknownFailure ||
        failure is ServerFailure) {
      return const _BusinessRegistrationErrorContent(
        title: 'Ocurrio un error al registrar el negocio',
        description:
            'Intenta nuevamente. Si sigue ocurriendo, usa el boton de feedback para reportarlo.',
      );
    }

    return const _BusinessRegistrationErrorContent(
      title: 'No fue posible completar el registro',
      description:
          'Intenta de nuevo en unos minutos. Puedes enviar feedback si el error persiste.',
    );
  }

  Future<void> _openFeedbackDialogFromErrorDialog(BuildContext context) async {
    if (ref.read(isFeedbackDialogOpenProvider)) {
      return;
    }

    ref.read(isFeedbackDialogOpenProvider.notifier).setIsOpen();
    await showDialog<void>(
      context: context,
      builder: (_) => const FeedbackDialogWidget(),
    );
    ref.read(isFeedbackDialogOpenProvider.notifier).setIsClosed();
  }

  Future<void> _showBusinessRegistrationErrorDialog(Failure failure) async {
    if (!mounted) return;

    final content = _mapFailureToDialog(failure);

    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        return OurnegoInformationDialog(
          title: content.title,
          description: content.description,
          imagePath: _genericBusinessErrorImage,
          actions: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () async {
                    Navigator.of(dialogContext).pop();
                    await _openFeedbackDialogFromErrorDialog(context);
                  },
                  child: const Text('Feedback'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Entiendo'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<XFile?> pickBusinessImage() async {
    return _picker.pickImage(source: ImageSource.gallery);
  }

  @override
  void initState() {
    super.initState();

    for (var day = 0; day < 7; day++) {
      _hoursByDay[day] = AppSchedule(
        dayOfWeek: day,
        openMinutes: BusinessHoursPicker.defaultOpenMinutes,
        closeMinutes: BusinessHoursPicker.defaultCloseMinutes,
      );
    }

    _attachDraftListeners();
    _loadDraft();

    ProviderSubscription<AsyncValue<AppPosition>> updateLocation() {
      return ref.listenManual<
        AsyncValue<AppPosition>
      >(_businessCurrentLocationProvider, (previous, next) {
        next.whenOrNull(
          data: (data) {
            _animatedMapController.animateTo(
              dest: LatLng(data.latitude, data.longitude),
              zoom: 15,
            );
          },
          error: (error, stackTrace) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              ScaffoldMessenger.of(context).showSnackBar(
                OurnegoSnackbars.info(
                  'Error al obtener la ubicación actual. Por favor selecciona la ubicación manualmente.',
                ),
              );
            });
          },
        );
      });
    }

    _providerSubscription = updateLocation();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _addressController.dispose();
    _addressFocusNode.dispose();
    _phoneController.dispose();
    _isSending.dispose();
    _scrollController.dispose();
    _providerSubscription.close();
    _animatedMapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final getAddressesSuggestionsUsecase = ref.watch(
      getAdressesSuggestionsUsecaseProvider,
    );

    final registerBusinessUsecase = ref.watch(registerBusinessUsecaseProvider);

    final bool isDarkModeOn =
        MediaQuery.of(context).platformBrightness == Brightness.dark;

    final String myAccessToken = MapboxConfig.accessToken;
    final String myUsername = MapboxConfig.username;
    final String styleIdDark = MapboxConfig.styleIdDark;
    final String styleIdLight = MapboxConfig.styleIdLight;

    final String currentStyleId = isDarkModeOn ? styleIdLight : styleIdDark;

    final bool hasMapboxConfig =
        myAccessToken.isNotEmpty &&
        myUsername.isNotEmpty &&
        currentStyleId.isNotEmpty;

    return Scaffold(
      body: Stack(
        children: [
          AnimatedBackground(),
          Padding(
            padding: const EdgeInsets.all(28.0),
            child: Form(
              key: _formKey,
              child: ListView(
                controller: _scrollController,
                children: [
                  Divider(),
                  SizedBox(height: 24),
                  Text(
                    'Registra tu negocio',
                    style: OurnegoTextStyles.header,
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 24),
                  Divider(),
                  SizedBox(height: 24),
                  Text(
                    '¿Cómo se llama tu negocio?',
                    style: OurnegoTextStyles.body,
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 16),
                  BusinessNameInput(controller: _nameController),
                  SizedBox(height: 24),
                  Text(
                    '¿Qué es tu negocio?',
                    style: OurnegoTextStyles.body,
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 16),
                  BusinessDescriptionInput(
                    descriptionController: _descriptionController,
                  ),
                  SizedBox(height: 24),
                  Text(
                    'Foto de tu negocio',
                    style: OurnegoTextStyles.body,
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 16),
                  SizedBox(
                    height: 56,
                    child: FilledButton(
                      onPressed: () async {
                        final pickedImage = await pickBusinessImage();
                        if (pickedImage == null) return;

                        final bytes = await pickedImage.readAsBytes();
                        if (bytes.isEmpty) return;

                        setState(() {
                          _pickedImageBytes = bytes;
                          _pickedImageName = pickedImage.name;
                          _pickedImageMimeType = pickedImage.mimeType;
                        });

                        await _persistDraft();
                        debugPrint(_pickedImageName);
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Subir foto del negocio',
                            style: OurnegoTextStyles.body,
                          ),
                          SizedBox(width: 16),
                          Icon(
                            _pickedImageBytes == null ||
                                    _pickedImageBytes!.isEmpty
                                ? Icons.cloud_upload_rounded
                                : Icons.check_rounded,
                            size: 24,
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 16),
                  (_pickedImageBytes == null || _pickedImageBytes!.isEmpty)
                      ? Text(
                          'Para verificar que tu negocio realmente existe, necesitamos una foto del exterior de tu local.',
                          style: OurnegoTextStyles.bodyCompact.copyWith(
                            color: OurnegoColorTokens.warning,
                          ),
                          textAlign: TextAlign.center,
                        )
                      : Container(
                          width: double.maxFinite,
                          height: 300,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(30),
                            image:
                                _pickedImageBytes != null &&
                                    _pickedImageBytes!.isNotEmpty
                                ? DecorationImage(
                                    image: MemoryImage(_pickedImageBytes!),
                                    fit: BoxFit.cover,
                                  )
                                : null,
                          ),
                        ),

                  SizedBox(height: 24),

                  Text(
                    'Dirección de tu negocio',
                    style: OurnegoTextStyles.body,
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 16),
                  BusinessAddressInput(
                    addressController: _addressController,
                    animatedMapController: _animatedMapController,
                    getAddressesSuggestionsUsecase:
                        getAddressesSuggestionsUsecase,
                    focusNode: _addressFocusNode,
                    scrollController: _scrollController,
                  ),
                  SizedBox(height: 16),
                  if (!hasMapboxConfig)
                    InformationCardWidget(
                      title: 'Mapa deshabilitado',
                      description:
                          'Falta configurar Mapbox (MAPBOX_ACCESS_TOKEN, MAPBOX_USERNAME y style ids). Aun puedes registrar el negocio seleccionando la ubicacion manualmente mas tarde.',
                      imagePath: _genericBusinessErrorImage,
                    )
                  else
                    BusinessPositionSelector(
                      animatedMapController: _animatedMapController,
                      myUsername: myUsername,
                      currentStyleId: currentStyleId,
                      myAccessToken: myAccessToken,
                      onCenterChanged: (_) => _persistDraft(),
                    ),
                  SizedBox(height: 24),
                  Text(
                    '¿En qué categoría se encuentra tu negocio?',
                    style: OurnegoTextStyles.body,
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 16),
                  DropdownButtonFormField<int>(
                    initialValue: _selectedCategory,
                    validator: (category) {
                      if (category == null) {
                        return 'Por favor selecciona una categoría';
                      }
                      return null;
                    },
                    items: [
                      DropdownMenuItem(
                        value: 0,
                        child: Text('Bebida y Comida'),
                      ),
                      DropdownMenuItem(value: 1, child: Text('Tienda')),
                      DropdownMenuItem(
                        value: 2,
                        child: Text('Servicio Personal'),
                      ),
                      DropdownMenuItem(
                        value: 3,
                        child: Text('Servicio Profesional'),
                      ),
                      DropdownMenuItem(
                        value: 4,
                        child: Text('Salud y Bienestar'),
                      ),
                      DropdownMenuItem(value: 5, child: Text('Educación')),
                      DropdownMenuItem(
                        value: 6,
                        child: Text('Construcción y Hogar'),
                      ),
                      DropdownMenuItem(value: 7, child: Text('Transporte')),
                      DropdownMenuItem(
                        value: 8,
                        child: Text('Entretenimiento'),
                      ),
                      DropdownMenuItem(value: 9, child: Text('Tecnología')),
                      DropdownMenuItem(
                        value: 10,
                        child: Text('Negocio Informal'),
                      ),
                      DropdownMenuItem(
                        value: 11,
                        child: Text('Mezcla de categorías'),
                      ),
                      DropdownMenuItem(value: 12, child: Text('Otro')),
                    ],
                    onChanged: (category) {
                      setState(() {
                        _selectedCategory = category ?? 12;
                      });
                      _persistDraft();
                    },
                    decoration: OurnegoInputDecorations.filled(
                      context: context,
                      labelText: 'Categoría del negocio',
                    ),
                  ),
                  SizedBox(height: 24),
                  Text(
                    'Número de teléfono de tu negocio (opcional)',
                    style: OurnegoTextStyles.bodyCompact,
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 16),
                  OurnegoInputField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    icon: const Text('+52'),
                    hintText: 'Número de teléfono',
                  ),
                  SizedBox(height: 24),
                  Text(
                    '¿En qué horarios abre tu negocio?',
                    style: OurnegoTextStyles.bodyCompact,
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 16),
                  Column(
                    children: List.generate(
                      7,
                      (index) => BusinessHoursPicker(
                        day: index,
                        initialSchedule: _hoursByDay[index],
                        onChanged: (schedule) =>
                            _onBusinessScheduleChanged(index, schedule),
                      ),
                    ),
                  ),
                  SizedBox(height: 24),
                  Divider(),
                  SizedBox(height: 24),
                  SizedBox(
                    height: 56,
                    child: FilledButton(
                      onPressed: () async {
                        final hasImage =
                            _pickedImageBytes != null &&
                            _pickedImageBytes!.isNotEmpty;

                        if (_isSending.value) return;

                        if (_formKey.currentState!.validate() && hasImage) {
                          _isSending.value = true;
                          setState(() {});

                          debugPrint('${_isSending.value}');

                          final hours = _hoursByDay.values
                              .whereType<AppSchedule>()
                              .toList(growable: false);
                          final response = await registerBusinessUsecase(
                            name: _nameController.text,
                            description: _descriptionController.text,
                            category: _selectedCategory ?? 12,
                            address: _addressController.text,
                            latitude: _animatedMapController
                                .mapController
                                .camera
                                .center
                                .latitude,
                            longitude: _animatedMapController
                                .mapController
                                .camera
                                .center
                                .longitude,
                            image: BusinessImageData(
                              bytes: _pickedImageBytes!,
                              fileName: _pickedImageName.isNotEmpty
                                  ? _pickedImageName
                                  : 'business-image.jpg',
                              mimeType: _pickedImageMimeType,
                            ),
                            phoneNumber: _phoneController.text,
                            hours: hours,
                          );

                          await response.fold(
                            (failure) async {
                              _isSending.value = false;
                              setState(() {});
                              await _showBusinessRegistrationErrorDialog(
                                failure,
                              );
                            },
                            (success) {
                              _clearDraft();
                              if (!mounted) return Future<void>.value();
                              ScaffoldMessenger.of(context).showSnackBar(
                                OurnegoSnackbars.info(
                                  'Negocio registrado exitosamente.',
                                ),
                              );
                              ref.invalidate(isOwnerProvider);
                              Navigator.of(context).pop();
                              return Future<void>.value();
                            },
                          );
                        } else {
                          String errorMessage;
                          if (!hasImage) {
                            errorMessage =
                                'Por favor sube una foto del negocio.';
                          } else {
                            errorMessage =
                                'Por favor completa todos los campos requeridos.';
                          }

                          showDialog(
                            context: context,
                            builder: (buildContext) {
                              return OurnegoAlertDialog(
                                title: 'Error',
                                content: errorMessage,
                                onAction: () {
                                  Navigator.of(buildContext).pop();
                                },
                              );
                            },
                          );
                        }
                      },
                      child: _isSending.value
                          ? CircularProgressIndicator(
                              color: Theme.of(context).colorScheme.onPrimary,
                              strokeWidth: 2,
                            )
                          : Text(
                              'Registrar Negocio',
                              style: OurnegoTextStyles.button,
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class BusinessPositionSelector extends StatelessWidget {
  const BusinessPositionSelector({
    super.key,
    required AnimatedMapController animatedMapController,
    required this.myUsername,
    required this.currentStyleId,
    required this.myAccessToken,
    required this.onCenterChanged,
  }) : _animatedMapController = animatedMapController;

  final AnimatedMapController _animatedMapController;
  final String myUsername;
  final String currentStyleId;
  final String myAccessToken;
  final ValueChanged<LatLng> onCenterChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.maxFinite,
      height: 256,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        color: Theme.of(context).colorScheme.surface,
        border: BoxBorder.all(width: 1),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: Text(
              'Selecciona la ubicación',
              style: OurnegoTextStyles.body,
            ),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
              child: FlutterMap(
                options: MapOptions(
                  initialCenter: LatLng(19.4326, -99.1332),
                  initialZoom: 12,
                  maxZoom: 18,
                  minZoom: 3,
                  onPositionChanged: (camera, hasGesture) {
                    onCenterChanged(camera.center);
                  },
                ),
                mapController: _animatedMapController.mapController,
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://api.mapbox.com/styles/v1/mapbox/streets-v12/tiles/512/{z}/{x}/{y}@2x?access_token=$myAccessToken',
                    userAgentPackageName: 'com.ournego.app',
                    tileProvider: kIsWeb
                        ? NetworkTileProvider()
                        : NetworkTileProvider(
                            cachingProvider:
                                BuiltInMapCachingProvider.getOrCreateInstance(
                                  maxCacheSize: 1_000_000_000,
                                ),
                          ),
                    key: Key(currentStyleId),
                  ),
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.location_on,
                          size: 48,
                          color: Theme.of(context).colorScheme.error,
                        ),
                        SizedBox(height: 48),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class BusinessAddressInput extends StatelessWidget {
  const BusinessAddressInput({
    super.key,
    required TextEditingController addressController,
    required AnimatedMapController animatedMapController,
    required this.getAddressesSuggestionsUsecase,
    required this.focusNode,
    required this.scrollController,
  }) : _addressController = addressController,
       _animatedMapController = animatedMapController;

  final TextEditingController _addressController;
  final AnimatedMapController _animatedMapController;
  final GetAddressesSuggestionsUsecase getAddressesSuggestionsUsecase;
  final FocusNode focusNode;
  final ScrollController scrollController;

  @override
  Widget build(BuildContext context) {
    if (focusNode.hasFocus) {
      scrollController.animateTo(
        970,
        duration: Duration(milliseconds: 300),
        curve: Curves.linear,
      );
    }

    return TypeAheadField(
      focusNode: focusNode,
      controller: _addressController,
      builder: (context, controller, focusNode) {
        return OurnegoInputField(
          fieldKey: const ValueKey('businessAddressInput'),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Por favor ingresa una dirección válida';
            }
            return null;
          },
          controller: _addressController,
          focusNode: focusNode,
          hintStyle: OurnegoTextStyles.body.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withAlpha(150),
          ),
          hintText: 'Calle y número, ciudad, estado...',
        );
      },
      itemBuilder: (context, place) {
        return ListTile(
          leading: Icon(Icons.location_on_outlined),
          title: Text(place.address),
        );
      },
      onSelected: (place) {
        _animatedMapController.animateTo(
          dest: LatLng(place.latitude ?? 0.0, place.longitude ?? 0.0),
          zoom: 16,
          curve: Curves.bounceInOut,
        );

        _addressController.text = place.address;
      },
      suggestionsCallback: (query) async {
        if (query.isEmpty || query.length < 3) {
          return [];
        }
        final result = await getAddressesSuggestionsUsecase(query);
        return result.fold((failure) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            ScaffoldMessenger.of(context).showSnackBar(
              OurnegoSnackbars.info(
                failure is AuthenticationRequiredFailure
                    ? 'Inicia sesion para usar sugerencias de direccion.'
                    : 'No se pudieron cargar sugerencias de direccion.',
              ),
            );
          });
          return <AppPosition>[];
        }, (suggestions) => suggestions);
      },
      debounceDuration: const Duration(milliseconds: 400),
    );
  }
}

class BusinessDescriptionInput extends StatelessWidget {
  const BusinessDescriptionInput({
    super.key,
    required TextEditingController descriptionController,
  }) : _descriptionController = descriptionController;

  final TextEditingController _descriptionController;

  @override
  Widget build(BuildContext context) {
    return OurnegoInputField(
      fieldKey: const ValueKey('businessDescriptionInput'),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Por favor ingresa una descripción del negocio';
        }
        return null;
      },
      controller: _descriptionController,
      maxLines: 4,
      hintStyle: TextStyle(
        color: Theme.of(context).colorScheme.onSurface.withAlpha(150),
      ),
      hintText:
          'Ejemplo: Cafetería que ofrece café orgánico y pasteles caseros.',
    );
  }
}

// ------------------- Input para nombre del negocio -------------------

class BusinessNameInput extends StatelessWidget {
  final TextEditingController controller;

  const BusinessNameInput({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return OurnegoInputField(
      fieldKey: const ValueKey('businessNameInput'),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Por favor ingresa el nombre del negocio';
        }
        return null;
      },
      controller: controller,
      labelText: 'Nombre del negocio',
    );
  }
}

class _BusinessRegistrationErrorContent {
  final String title;
  final String description;

  const _BusinessRegistrationErrorContent({
    required this.title,
    required this.description,
  });
}
