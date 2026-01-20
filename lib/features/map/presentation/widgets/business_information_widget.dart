// ignore_for_file: unused_element_parameter

// TODO: The widget file is large and contains multiple responsibilities
// (UI, platform calls, business logic). Consider splitting into smaller
// widgets/files and moving platform calls into services. Perspective:
// - Extract button styles and repeated UI pieces
// - Move phone/URL handling to a `ContactService` that can be tested
// - Localize all user-facing strings

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_phone_direct_caller/flutter_phone_direct_caller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ournego/core/ournego_text_styles.dart';
import 'package:ournego/features/map/domain/entities/business.dart';
import 'package:ournego/features/map/domain/entities/product.dart';
import 'package:ournego/features/map/domain/usecases/get_business_marker_usecase.dart';
import 'package:ournego/features/map/presentation/providers/map_providers.dart';
import 'package:ournego/features/auth/presentation/pages/auth_selection_screen.dart';
import 'package:ournego/core/failures.dart';
import 'package:url_launcher/url_launcher.dart';

class BusinessInformationWidget extends ConsumerWidget {
  final ScrollController scrollController;

  const BusinessInformationWidget({super.key, required this.scrollController});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final _modalState = ref.watch(modalState);
    final business = ref.watch(selectedBusiness);

    if (business == null) {
      return Container(
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(30),
            topRight: Radius.circular(30),
          ),
          color: Theme.of(context).colorScheme.surface,
        ),
      );
    }

    final IconData icon = GetBusinessMarkerUsecase(business: business)().icon;

    final bool isCollapsed = _modalState == 0;

    final ScrollPhysics scrollPhysics = isCollapsed
        ? const ClampingScrollPhysics()
        : const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics());

    final isFavorite =
        ref.watch(isBusinessFavoriteStreamProvider(business.id)).value ?? false;

    List<Widget> listChildren;

    if (isCollapsed) {
      // -----------------------------------------------------------------------------------------//
      // ------------------------------- Colapsed Widget List ------------------------------------//
      // -----------------------------------------------------------------------------------------//
      listChildren = [
        // ------------------------------- Business Name and Icon ------------------------------------//
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  business.name,
                  style: OurnegoTextStyles.header.copyWith(fontSize: 30),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  softWrap: false,
                ),
              ),
              _BusinessFavoriteButton(
                isFavorite: isFavorite,
                business: business,
              ),
            ],
          ),
        ),
        const SizedBox(height: 5),
        // ------------------------------- Action Buttons ------------------------------------//
        Row(
          children: [
            const Spacer(),
            // ------------------------------- General Opinion Button ------------------------------------//
            ElevatedButton(
              style: ButtonStyle(
                shadowColor: WidgetStatePropertyAll(Colors.transparent),
                backgroundColor: WidgetStatePropertyAll(
                  Colors.grey.withAlpha(80),
                ),
                foregroundColor: WidgetStatePropertyAll(
                  Theme.of(context).colorScheme.onSurface,
                ),
              ),
              onPressed: () {},
              child: const Icon(Icons.emoji_emotions, size: 20),
            ),
            const Spacer(),
            // ------------------------------- Search Products Button ------------------------------------//
            ElevatedButton(
              style: ButtonStyle(
                shadowColor: WidgetStatePropertyAll(Colors.transparent),
                backgroundColor: WidgetStatePropertyAll(
                  Colors.grey.withAlpha(80),
                ),
                foregroundColor: WidgetStatePropertyAll(
                  Theme.of(context).colorScheme.onSurface,
                ),
              ),
              onPressed: () {},
              child: Row(
                children: [
                  const Icon(Icons.search),
                  Text('Buscar Productos', style: OurnegoTextStyles.body),
                ],
              ),
            ),
            const Spacer(),
            // ------------------------------- Message Button ------------------------------------//
            ElevatedButton(
              style: ButtonStyle(
                shadowColor: WidgetStatePropertyAll(Colors.transparent),
                backgroundColor: WidgetStatePropertyAll(
                  Colors.grey.withAlpha(80),
                ),
                foregroundColor: WidgetStatePropertyAll(
                  Theme.of(context).colorScheme.onSurface,
                ),
              ),
              onPressed: () async {
                // TODO: Use a ContactService and proper URL checks.
                // - Validate phone format before launching
                // - Prefer `canLaunchUrl` (or `UrlLauncher.canLaunch`) and
                //   fall back to `flutter_phone_direct_caller` for direct
                //   dialing when appropriate.
                if (business.phoneNumber != null) {
                  final uri = Uri.parse(
                    'https://wa.me/${business.phoneNumber}',
                  );
                  // Try to launch, but guard with canLaunch in production
                  await launchUrl(uri);
                } else {
                  // TODO: Localize this string and move UI to a small helper
                  showDialog(
                    context: context,
                    builder: (context) {
                      return AlertDialog(
                        content: Text(
                          'Lamentablemente, este negocio no cuenta con número de teléfono :(',
                          style: OurnegoTextStyles.body,
                        ),
                        backgroundColor: Theme.of(context).colorScheme.surface,
                        actions: [
                          TextButton(
                            style: ButtonStyle(
                              foregroundColor: WidgetStatePropertyAll(
                                Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text(
                              'Entiendo',
                              style: OurnegoTextStyles.body,
                            ),
                          ),
                        ],
                      );
                    },
                  );
                }
              },
              child: const Icon(Icons.chat),
            ),
            const Spacer(),
          ],
        ),
      ];
    } else {
      // -----------------------------------------------------------------------------------------//
      // ------------------------------- Expanded Widget List ------------------------------------//
      // -----------------------------------------------------------------------------------------//
      listChildren = [
        // ------------------------------- Business Name ------------------------------------//
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                business.name,
                style: OurnegoTextStyles.header.copyWith(fontSize: 30),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // ---------------- Favorite Button ------------------------------------//
            _BusinessFavoriteButton(isFavorite: isFavorite, business: business),
          ],
        ),
        const SizedBox(height: 10),
        // --------------------------- Business Description ---------------------------------//
        Text(
          business.description,
          style: OurnegoTextStyles.body.copyWith(fontSize: 18),
        ),
        const SizedBox(height: 20),
        // ------------------------------- Image Gallery ------------------------------------//
        if (business.images.isNotEmpty)
          _BusinessImagesGallery(business: business),
        if (business.images.isNotEmpty) SizedBox(height: 20),
        // ------------------------------- General Opinion ------------------------------------//
        _BusinessOpinionsButton(business: business),
        SizedBox(height: 20),
        // ------------------------------- Business Owner Contact ------------------------------------//
        _BusinessOwnerContact(business: business),
        SizedBox(height: 20),
        // ------------------------------- Products Search ------------------------------------//
        _BusinessProductsSearch(business: business),
        SizedBox(height: 50),
      ];
    }

    // -----------------------------------------------------------------------------------------//
    // ------------------------------- Main Blurry Container -----------------------------------//
    // -----------------------------------------------------------------------------------------//

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(30),
            blurRadius: 15,
            spreadRadius: 1,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
        child: Stack(
          children: [
            BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
              child: Container(
                color: Theme.of(context).colorScheme.surface.withAlpha(150),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10.0),
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  const _DragHandle(),
                  const SizedBox(height: 10),
                  Expanded(
                    child: ListView(
                      controller: scrollController,
                      padding: const EdgeInsets.only(top: 0),
                      physics: scrollPhysics,
                      children: listChildren,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BusinessFavoriteButton extends ConsumerWidget {
  const _BusinessFavoriteButton({
    super.key,
    required this.isFavorite,
    required this.business,
  });

  final bool isFavorite;
  final Business business;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ElevatedButton(
      style: ButtonStyle(
        shadowColor: WidgetStatePropertyAll(Colors.transparent),
        backgroundColor: WidgetStatePropertyAll(
          isFavorite ? Colors.red.withAlpha(100) : Colors.grey.withAlpha(80),
        ),
        foregroundColor: WidgetStatePropertyAll(
          Theme.of(context).colorScheme.onSurface,
        ),
        padding: WidgetStatePropertyAll(
          EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        shape: WidgetStatePropertyAll(CircleBorder()),
        minimumSize: WidgetStatePropertyAll(Size(40, 40)),
      ),
      onPressed: () async {
        final result = await ref
            .read(businessFavoritesUsecaseProvider)
            .toggleFavorite(business.id, isFavorite);

        result.fold(
          (failure) {
            if (failure is AuthenticationRequiredFailure) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AuthSelectionScreen(),
                ),
              );
            } else {
              // TODO: Provide user-friendly messages based on `Failure`
              // and localize strings. Consider a centralized `ErrorMapper`
              // that maps domain failures to snackbars/dialogs.
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('No se pudo actualizar favorito')),
              );
            }
          },
          (_) {
            ref.invalidate(isBusinessFavoriteStreamProvider(business.id));
          },
        );
      },
      child: Icon(
        isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
        color: isFavorite ? Colors.red : Colors.grey,
        size: 18,
      ),
    );
  }
}
// -----------------------------------------------------------------------------------------//
// ------------------------------- Business Products Search ------------------------------------//
// -----------------------------------------------------------------------------------------//

class _BusinessProductsSearch extends StatelessWidget {
  _BusinessProductsSearch({super.key, required this.business});

  final Business business;

  final List<Product> discountProductsList = [
    //Product(id: '1', name: 'Ñiñiñi', imageUrl: 'noche'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.maxFinite,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        color: Colors.grey.withAlpha(80),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Products Search Bar
            SearchBar(
              hintText: 'Buscar productos...',
              elevation: WidgetStatePropertyAll(0),
              backgroundColor: WidgetStatePropertyAll(
                Colors.grey.withAlpha(80),
              ),
              leading: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Icon(Icons.search_rounded),
              ),
            ),

            // Discount Products
            if (discountProductsList.isNotEmpty) const SizedBox(height: 10),

            if (discountProductsList.isNotEmpty)
              SizedBox(
                width: double.maxFinite,
                height: 200,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: discountProductsList.map((product) {
                    // TODO: Implement product card widget and image placeholders
                    return SizedBox();
                  }).toList(),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------------------//
// ------------------------------ Business Owner Contact -----------------------------------//
// -----------------------------------------------------------------------------------------//

class _BusinessOwnerContact extends ConsumerWidget {
  const _BusinessOwnerContact({super.key, required this.business});

  final Business business;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ownerProfile = ref.watch(
      ownerProfileStreamProvider(business.ownerId),
    );

    return Container(
      width: double.maxFinite,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        color: Colors.grey.withAlpha(80),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Section's Icon and Name
            ownerProfile.when(
              data: (profile) {
                return Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          height: 35,
                          width: 35,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(1000),
                            child: Image(
                              image: NetworkImage(profile.profilePicture ?? ''),
                              fit: BoxFit.fill,
                              errorBuilder: (context, error, stackTrace) {
                                return Icon(
                                  Icons.account_circle,
                                  size: 35,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurface,
                                );
                              },
                            ),
                          ),
                        ),
                        SizedBox(width: 15),
                        Text(
                          profile.name ?? '',
                          style: OurnegoTextStyles.header,
                        ),
                      ],
                    ),
                    SizedBox(height: 7),
                  ],
                );
              },
              error: (error, stackTrace) {
                return SizedBox();
              },
              loading: () {
                return Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(width: 16),
                        Icon(
                          Icons.account_circle,
                          size: 35,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                        SizedBox(width: 15),
                        Text(
                          'Nombre de Usuario',
                          style: OurnegoTextStyles.header,
                        ),
                      ],
                    ),
                    SizedBox(height: 7),
                  ],
                );
              },
            ),

            // Message and Call Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Message Button
                ElevatedButton(
                  style: ButtonStyle(
                    shadowColor: WidgetStatePropertyAll(Colors.transparent),
                    backgroundColor: WidgetStatePropertyAll(
                      Colors.grey.withAlpha(80),
                    ),
                    foregroundColor: WidgetStatePropertyAll(
                      Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  onPressed: () {
                    if (business.phoneNumber != null) {
                      launchUrl(
                        Uri.parse('https://wa.me/${business.phoneNumber}'),
                      );
                    } else {
                      showDialog(
                        context: context,
                        builder: (context) {
                          return AlertDialog(
                            content: Text(
                              'Lamentablemente, este negocio no cuenta con número de teléfono :(',
                              style: OurnegoTextStyles.body,
                            ),
                            backgroundColor: Theme.of(
                              context,
                            ).colorScheme.surface,
                            actions: [
                              TextButton(
                                style: ButtonStyle(
                                  foregroundColor: WidgetStatePropertyAll(
                                    Theme.of(context).colorScheme.onSurface,
                                  ),
                                ),
                                onPressed: () => Navigator.of(context).pop(),
                                child: const Text(
                                  'Entiendo',
                                  style: OurnegoTextStyles.body,
                                ),
                              ),
                            ],
                          );
                        },
                      );
                    }
                  },
                  child: Row(
                    children: [
                      Icon(Icons.chat, size: 20),
                      SizedBox(width: 10),
                      Text('Mensaje', style: OurnegoTextStyles.body),
                    ],
                  ),
                ),

                SizedBox(width: 20),

                // Call Button
                ElevatedButton(
                  style: ButtonStyle(
                    shadowColor: WidgetStatePropertyAll(Colors.transparent),
                    backgroundColor: WidgetStatePropertyAll(
                      Colors.grey.withAlpha(80),
                    ),
                    foregroundColor: WidgetStatePropertyAll(
                      Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  onPressed: () async {
                    if (business.phoneNumber != null) {
                      await FlutterPhoneDirectCaller.callNumber(
                        business.phoneNumber.toString(),
                      );
                    } else {
                      showDialog(
                        context: context,
                        builder: (context) {
                          return AlertDialog(
                            content: Text(
                              'Lamentablemente, este negocio no cuenta con número de teléfono :(',
                              style: OurnegoTextStyles.body,
                            ),
                            backgroundColor: Theme.of(
                              context,
                            ).colorScheme.surface,
                            actions: [
                              TextButton(
                                style: ButtonStyle(
                                  foregroundColor: WidgetStatePropertyAll(
                                    Theme.of(context).colorScheme.onSurface,
                                  ),
                                ),
                                onPressed: () => Navigator.of(context).pop(),
                                child: const Text(
                                  'Entiendo',
                                  style: OurnegoTextStyles.body,
                                ),
                              ),
                            ],
                          );
                        },
                      );
                    }
                  },
                  child: Row(
                    children: [
                      Icon(Icons.call, size: 20),
                      SizedBox(width: 10),
                      Text('Llamar', style: OurnegoTextStyles.body),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------------------//
// ----------------------------- Business General Opinion ----------------------------------//
// -----------------------------------------------------------------------------------------//

class _BusinessOpinionsButton extends StatelessWidget {
  const _BusinessOpinionsButton({super.key, required this.business});

  final Business business;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: ButtonStyle(
        minimumSize: WidgetStatePropertyAll(Size(double.maxFinite, 70)),
        maximumSize: WidgetStatePropertyAll(Size(double.maxFinite, 70)),
        shadowColor: WidgetStatePropertyAll(Colors.transparent),
        backgroundColor: WidgetStatePropertyAll(Colors.grey.withAlpha(80)),
        foregroundColor: WidgetStatePropertyAll(
          Theme.of(context).colorScheme.onSurface,
        ),
      ),
      onPressed: () {},
      child: Row(
        children: [
          Icon(Icons.emoji_emotions, size: 50),
          Spacer(),
          Text('  Opinión General', style: OurnegoTextStyles.header),
          Spacer(),
          Icon(Icons.chevron_right_rounded, size: 50),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------------------//
// ------------------------------ Business Image Gallery -----------------------------------//
// -----------------------------------------------------------------------------------------//

class _BusinessImagesGallery extends StatelessWidget {
  const _BusinessImagesGallery({super.key, required this.business});

  final Business business;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 200,
      width: double.maxFinite,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: business.images.map((imageUrl) {
          return Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadiusGeometry.circular(20),
                child: GestureDetector(
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(20.0),
                            child: ClipRRect(
                              borderRadius: BorderRadiusGeometry.circular(30),
                              child: Image(image: NetworkImage(imageUrl)),
                            ),
                          ),
                        );
                      },
                    );
                  },
                  child: Image(
                    image: NetworkImage(imageUrl),
                    loadingBuilder: (context, child, loadingProgress) {
                      return loadingProgress == null
                          ? child
                          : Container(
                              width: 200,
                              height: double.maxFinite,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(30),
                                color: Colors.grey.withAlpha(80),
                              ),
                            );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return SizedBox();
                    },
                  ),
                ),
              ),
              SizedBox(width: 10),
            ],
          );
        }).toList(),
      ),
    );
  }
}

class _DragHandle extends StatelessWidget {
  const _DragHandle();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 40,
        height: 5,
        decoration: BoxDecoration(
          color: Colors.grey[400],
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }
}
