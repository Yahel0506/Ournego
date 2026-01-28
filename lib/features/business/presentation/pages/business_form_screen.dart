import 'dart:io';

import 'package:flutter/material.dart';

import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_animations/flutter_map_animations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import 'package:ournego/core/ournego_text_styles.dart';
import 'package:ournego/features/business/domain/usecases/get_addresses_suggestions_usecase.dart';
import 'package:ournego/features/business/presentation/pages/components/business_hours_picker.dart';
import 'package:ournego/features/map/domain/entities/app_position.dart';
import 'package:ournego/shared/widgets/animated_background.dart';

import '../../domain/entitites/app_schedule.dart';
import '../providers/business_providers.dart';

class BusinessFormScreen extends ConsumerStatefulWidget {
  const BusinessFormScreen({super.key});

  @override
  ConsumerState<BusinessFormScreen> createState() => _BusinessFormScreenState();
}

class _BusinessFormScreenState extends ConsumerState<BusinessFormScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _addressController = TextEditingController();
  late final _animatedMapController = AnimatedMapController(vsync: this);
  final _picker = ImagePicker();
  File _pickedImage = File('');
  final List<BusinessHoursPicker> _hoursPickers = List.generate(
    7,
    (index) => BusinessHoursPicker(day: index),
  );
  int? _selectedCategory = 0; // 0 - 12
  final _phoneController = TextEditingController();

  Future<File> pickBusinessImage() async {
    return _picker.pickImage(source: ImageSource.gallery).then((pickedFile) {
      if (pickedFile != null) {
        return File(pickedFile.path);
      } else {
        return File('');
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
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

    const String myAccessToken =
        'pk.eyJ1IjoieWFoZWwwNTA2IiwiYSI6ImNta2Q5a3l2aTBhMnczZXB3dXVpM29kd2cifQ.7EkrO3IQj-HfS2bR7tKPcg';
    const String myUsername = 'yahel0506';

    const String styleIdDark = 'cmke90wyw005w01qqgz7k6av3';
    const String styleIdLight = 'cmke8zt80000v01rx067dbgpr';

    //final String currentStyleId = isDarkModeOn ? styleIdDark : styleIdLight;
    final String currentStyleId = isDarkModeOn ? styleIdLight : styleIdDark;

    return Scaffold(
      body: Stack(
        children: [
          AnimatedBackground(),
          Padding(
            padding: const EdgeInsets.all(28.0),
            child: Form(
              key: _formKey,
              child: ListView(
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
                        if (pickedImage.path.isEmpty) return;
                        setState(() {
                          _pickedImage = pickedImage;
                        });
                        debugPrint(_pickedImage.path);
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
                            _pickedImage.path.isEmpty
                                ? Icons.cloud_upload_rounded
                                : Icons.check_rounded,
                            size: 24,
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 16),
                  _pickedImage.path.isEmpty
                      ? Text(
                          'Para verificar que tu negocio realmente existe, necesitamos una foto del exterior de tu local.',
                          style: OurnegoTextStyles.body.copyWith(
                            color: Colors.orange,
                          ),
                          textAlign: TextAlign.center,
                        )
                      : Container(
                          width: double.maxFinite,
                          height: 300,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(30),
                            image: _pickedImage.path.isNotEmpty
                                ? DecorationImage(
                                    image: FileImage(_pickedImage),
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
                  ),
                  SizedBox(height: 16),
                  BusinessPositionSelector(
                    animatedMapController: _animatedMapController,
                    myUsername: myUsername,
                    currentStyleId: currentStyleId,
                    myAccessToken: myAccessToken,
                  ),
                  SizedBox(height: 24),
                  Text(
                    '¿En qué categoría se encuentra tu negocio?',
                    style: OurnegoTextStyles.body,
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 16),
                  DropdownButtonFormField(
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
                    },
                    decoration: InputDecoration(
                      labelText: 'Categoría del negocio',
                      border: OutlineInputBorder(),
                      filled: true,
                      fillColor: Theme.of(context).colorScheme.surface,
                    ),
                  ),
                  SizedBox(height: 24),
                  Text(
                    'Número de teléfono de tu negocio (opcional)',
                    style: OurnegoTextStyles.body,
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 16),
                  TextFormField(
                    validator: (value) {
                      if (value != null && value.isNotEmpty) {
                        final phoneRegExp = RegExp(r'^\d{10}$');
                        if (!phoneRegExp.hasMatch(value)) {
                          return 'Por favor ingresa un número de teléfono válido de 10 dígitos';
                        }
                      }
                      return null;
                    },
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      icon: Text('+52'),
                      hintText: 'Número de teléfono',
                      border: OutlineInputBorder(),
                      filled: true,
                      fillColor: Theme.of(context).colorScheme.surface,
                    ),
                  ),
                  SizedBox(height: 24),
                  /*Text(
                    '¿En qué horarios abre tu negocio?',
                    style: OurnegoTextStyles.body,
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 16),
                  Column(children: [..._hoursPickers]),
                  SizedBox(height: 24),*/
                  Divider(),
                  SizedBox(height: 24),
                  SizedBox(
                    height: 56,
                    child: FilledButton(
                      onPressed: () async {
                        final hasImage = _pickedImage.path.isNotEmpty;

                        if (_formKey.currentState!.validate() && hasImage) {
                          final hours = _hoursPickers
                              .map((picker) {
                                final schedule = picker.getSchedule();
                                if (schedule != null) {
                                  return schedule;
                                }
                                return null;
                              })
                              .whereType<AppSchedule>()
                              .toList();
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
                            image: _pickedImage,
                            phoneNumber: _phoneController.text,
                            hours: hours,
                          );

                          response.fold(
                            (failure) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Error al registrar el negocio. Intenta de nuevo.',
                                  ),
                                ),
                              );
                            },
                            (success) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Negocio registrado exitosamente.',
                                  ),
                                ),
                              );
                              ref.invalidate(isOwnerProvider);
                              Navigator.of(context).pop();
                            },
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Formulario inválido. Por favor revisa los campos.',
                              ),
                            ),
                          );
                          ref.invalidate(isOwnerProvider);
                          Navigator.of(context).pop();
                        }
                      },
                      child: Text(
                        'Registrar Negocio',
                        style: OurnegoTextStyles.header,
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
  }) : _animatedMapController = animatedMapController;

  final AnimatedMapController _animatedMapController;
  final String myUsername;
  final String currentStyleId;
  final String myAccessToken;

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
                mapController: _animatedMapController.mapController,
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://api.mapbox.com/styles/v1/mapbox/streets-v12/tiles/512/{z}/{x}/{y}@2x?access_token=$myAccessToken',
                    userAgentPackageName: 'com.ournego.app',
                    tileProvider: NetworkTileProvider(
                      headers: {
                        'User-Agent': 'com.ournego.app',
                        // Mismo nombre que arriba
                        'Referer': 'com.ournego.app',
                      },
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
                        Icon(Icons.location_on, size: 48, color: Colors.red),
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
  }) : _addressController = addressController,
       _animatedMapController = animatedMapController;

  final TextEditingController _addressController;
  final AnimatedMapController _animatedMapController;
  final GetAddressesSuggestionsUsecase getAddressesSuggestionsUsecase;

  @override
  Widget build(BuildContext context) {
    return TypeAheadField(
      controller: _addressController,
      builder: (context, controller, focusNode) {
        return TextFormField(
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Por favor ingresa una dirección válida';
            }
            return null;
          },
          controller: controller,
          focusNode: focusNode,
          decoration: InputDecoration(
            hintStyle: OurnegoTextStyles.body.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withAlpha(150),
            ),
            hintText: 'Calle y número, ciudad, estado...',
            border: OutlineInputBorder(),
            filled: true,
            fillColor: Theme.of(context).colorScheme.surface,
          ),
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
      },
      suggestionsCallback: (query) async {
        if (query.isEmpty || query.length < 3) {
          return [];
        }
        final result = await getAddressesSuggestionsUsecase(query);
        return result.fold((failure) {
          debugPrint('Error fetching suggestions');
          return <AppPosition>[];
        }, (suggestions) => suggestions);
      },
      debounceDuration: Duration(milliseconds: 400),
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
    return TextFormField(
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Por favor ingresa una descripción del negocio';
        }
        return null;
      },
      controller: _descriptionController,
      maxLines: 4,
      decoration: InputDecoration(
        border: OutlineInputBorder(),
        hintStyle: TextStyle(
          color: Theme.of(context).colorScheme.onSurface.withAlpha(150),
        ),
        hintText:
            'Ejemplo: Cafetería que ofrece café orgánico y pasteles caseros.',
        filled: true,
        fillColor: Theme.of(context).colorScheme.surface,
      ),
    );
  }
}

// ------------------- Input para nombre del negocio -------------------

class BusinessNameInput extends StatelessWidget {
  final TextEditingController controller;

  BusinessNameInput({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Por favor ingresa el nombre del negocio';
        }
        return null;
      },
      controller: controller,
      decoration: InputDecoration(
        labelText: 'Nombre del negocio',
        border: OutlineInputBorder(),
        filled: true,
        fillColor: Theme.of(context).colorScheme.surface,
      ),
    );
  }
}
