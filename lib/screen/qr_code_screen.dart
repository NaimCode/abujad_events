import 'package:abujad_events/styles/colors.dart';
import 'package:abujad_events/utils/box.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';

// class QrScanScreen extends StatefulWidget {
//   const QrScanScreen({super.key});

//   @override
//   State<QrScanScreen> createState() => _QrScanScreenState();
// }

// class _QrScanScreenState extends State<QrScanScreen> {
//   final qrKey = GlobalKey(debugLabel: 'QR');
//   var isMenuVisible = false;
//   var restaurantID = "";

//   Barcode? barcode;

//   @override
//   Widget build(BuildContext context) {
//     final controller = useState<QRViewController?>(null);
//     return Scaffold(
//         body: Stack(
//       children: <Widget>[
//         buildQrView(context, controller),
//         const SafeArea(
//           child: Row(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: <Widget>[
//               // ObLogo(height: 24, vPadding: 16),
//             ],
//           ),
//         ),
//         // AnimatedPositioned(
//         //   bottom: isMenuVisible ? 150 : 0,
//         //   duration: const Duration(milliseconds: 280),
//         //   child: AnimatedOpacity(
//         //     opacity: isMenuVisible ? 1.0 : 0.0,
//         //     duration: const Duration(milliseconds: 280),
//         //     child: RestaurantIDCard(restaurantID: restaurantID),
//         //   ),
//         // ),
//       ],
//     ));
//   }

final _qrKey = GlobalKey(debugLabel: 'QR');

class QrScanScreen extends HookConsumerWidget {
  const QrScanScreen({super.key});

  @override
  Widget build(BuildContext context, ref) {
    var isMenuVisible = false;
    var restaurantID = "";
    Barcode? barcode;
    final controller = useState<QRViewController?>(null);
    return Scaffold(
        appBar: AppBar(
          title: const Text('Scanner'),
          actions: [
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () {
                showDialog(
                    context: context,
                    builder: (context) {
                      return AlertDialog(
                        title: const Text('Déconnexion'),
                        content: const Text(
                            'Voulez-vous vraiment vous déconnecter ?'),
                        actions: [
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            child: const Text('Annuler'),
                          ),
                          TextButton(
                            onPressed: () async {
                              await Box.clearToken();
                              // Navigator.pop(context);
                              // Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
                            },
                            child: const Text('Déconnexion'),
                          ),
                        ],
                      );
                    });
              },
            ),
          ],
        ),
        body: Stack(
          children: <Widget>[
            buildQrView(context, controller),
            const SafeArea(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  // ObLogo(height: 24, vPadding: 16),
                ],
              ),
            ),
            Positioned(
                bottom: 60,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton.filledTonal(
                        onPressed: () {
                          controller.value?.toggleFlash();
                        },
                        icon: const Icon(Icons.flash_on_rounded)),
                    const SizedBox(width: 20),
                    IconButton.filledTonal(
                        onPressed: () {
                          controller.value?.flipCamera();
                        },
                        icon: const Icon(Icons.flip_camera_ios)),
                  ],
                )),
          ],
        ));
  }

  Widget buildQrView(
      BuildContext context, ValueNotifier<QRViewController?> scannerState) {
    return QRView(
      key: _qrKey,
      onQRViewCreated: (controller) {
        scannerState.value = controller;
        controller.scannedDataStream.listen((barcode) {
          if (barcode.code != null) {
            scannerState.value?.pauseCamera();

            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (context) {
                return AlertDialog(
                  title: const Text('Code scanné'),
                  content: Text(barcode.code ?? ""),
                  actions: [
                    TextButton(
                      onPressed: () {
                        scannerState.value?.resumeCamera();
                        Navigator.pop(context);
                      },
                      child: const Text('OK'),
                    ),
                  ],
                );
              },
            );
          }
        });
      },
      overlay: QrScannerOverlayShape(
        cutOutSize: MediaQuery.of(context).size.width * 0.7,
        borderWidth: 15,
        borderColor: primaryColor,
        borderRadius: 12,
        borderLength: 24,
        overlayColor: Colors.black45,
      ),
    );
  }
}
