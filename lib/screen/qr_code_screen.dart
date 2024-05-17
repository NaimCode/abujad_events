import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_ringtone_player/flutter_ringtone_player.dart';
import 'package:hive_flutter/hive_flutter.dart' as b;
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:oktoast/oktoast.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:supmti_events/styles/colors.dart';
import 'package:supmti_events/utils/api.dart';
import 'package:supmti_events/utils/box.dart';
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
    final controller = useState<QRViewController?>(null);
    final isLoading = useState(false);
    final api = ref.watch(apiProvider);
    Future<void> scan(String? code) async {
      if (isLoading.value) return;
      isLoading.value = true;
      try {
        final response = await api.post(
            'https://events-preprod.supmti.ac.ma/src/api/check_ticket.php',
            data: {
              "ticket_code": code,
            });
        {
//   "status": "success",
//   "message": "Ticket validated"
// }
          if (response.data['status'] == 'success') {
            FlutterRingtonePlayer().play(fromAsset: "assets/success_2.mp3");
            await Future.delayed(const Duration(milliseconds: 700));
            final date = DateTime.now();
            final formattedDate =
                '${date.day}/${date.month}/${date.year} à ${date.hour}:${date.minute}';
            b.Hive.box('history').add({
              'code': code,
              'status': 'success', // 'success' or 'error
              'message': response.data['message'],
              'date': formattedDate,
            });
            await showDialog(
              // ignore: use_build_context_synchronously
              context: context,
              barrierDismissible: false,
              builder: (context) {
                return AlertDialog(
                  content: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Icon(Icons.check_circle,
                          color: Colors.green, size: 40),
                      const SizedBox(height: 6),
                      Text(
                        response.data['message'] ?? 'Ticket validé',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 10),
                      Text('$code',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          )),
                    ],
                  ),
                  actions: [
                    FilledButton.tonal(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: const Text('OK'),
                    ),
                  ],
                );
              },
            );
          } else {
            // showToast(
            //   response.data['message'] as String? ?? 'Ticket non valide');

            // ignore: use_build_context_synchronously
            try {
              if (response.data['message'].toString().contains('token')) {
                await Box.clearToken();
              }
            } catch (e) {}
            try {
              await FlutterRingtonePlayer()
                  .play(fromAsset: "assets/cursor_error.mp3");

              await Future.delayed(const Duration(milliseconds: 700));
              final date = DateTime.now();
              // format to french date
              final formattedDate =
                  '${date.day}/${date.month}/${date.year} à ${date.hour}:${date.minute}';
              b.Hive.box('history').add({
                'code': code,
                'status': 'error', // 'success' or 'error
                'message': response.data['message'],
                'date': formattedDate,
              });
              // ignore: use_build_context_synchronously
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                action: SnackBarAction(
                  label: 'X',
                  onPressed: () {
                    ScaffoldMessenger.of(context).hideCurrentSnackBar();
                  },
                ),
                backgroundColor: Colors.red,
                content: Row(
                  children: [
                    const Icon(Icons.error, color: Colors.white),
                    const SizedBox(width: 6),
                    Column(
                      children: [
                        Text(
                          response.data['message'] as String? ??
                              'Ticket non valide',
                          style: const TextStyle(color: Colors.white),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$code',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                duration: const Duration(seconds: 3),
              ));
            } catch (e) {}

            // showDialog(
            //   context: context,
            //   barrierDismissible: false,
            //   builder: (context) {
            //     return AlertDialog(
            //       title: const Text('Code scanné'),
            //       content: Text(response.data['message']),
            //       actions: [
            //         TextButton(
            //           onPressed: () {
            //             controller.value?.resumeCamera();
            //             Navigator.pop(context);
            //           },
            //           child: const Text('OK'),
            //         ),
            //       ],
            //     );
            //   },
            // );
          }
        }
      } on DioException catch (e) {
        final msg = e.response?.data['message'] as String?;
        if (msg != null && msg.contains('token')) {
          await Box.clearToken();
        }
      }
      isLoading.value = false;
    }

    isLoading.addListener(() {
      if (isLoading.value) {
        controller.value?.pauseCamera();
      } else {
        controller.value?.resumeCamera();
      }
    });
    return Scaffold(
        //history on floating action button

        floatingActionButton: FloatingActionButton(
          onPressed: () {
            final histories =
                b.Hive.box('history').values.toList().reversed.toList();
            // final histories = [
            //   {
            //     'code': '#B123456789',
            //     'status': 'success',
            //     'message': 'Ticket validé',
            //     'date': '2021-09-01T12:00:01Z',
            //   },
            //   {
            //     'code': '#B123456789',
            //     'status': 'error',
            //     'message': 'Ticket non valide',
            //     'date': '2021-09-01T12:00:00Z',
            //   },
            //   {
            //     'code': '#B123456789',
            //     'status': 'success',
            //     'message': 'Ticket validé',
            //     'date': '2021-09-01T12:00:00Z',
            //   },
            //   {
            //     'code': '#B123456789',
            //     'status': 'error',
            //     'message': 'Ticket non valide',
            //     'date': '2021-09-01T12:00:00Z',
            //   },
            //   {
            //     'code': '#B123456789',
            //     'status': 'success',
            //     'message': 'Ticket validé',
            //     'date': '2021-09-01T12:00:00Z',
            //   },
            //   {
            //     'code': '#B123456789',
            //     'status': 'error',
            //     'message': 'Ticket non valide',
            //     'date': '2021-09-01T12:00:00Z',
            //   },
            //   {
            //     'code': '#B123456789',
            //     'status': 'success',
            //     'message': 'Ticket validé',
            //     'date': '2021-09-01T12:00:00Z',
            //   },
            //   {
            //     'code': '#B123456789',
            //     'status': 'error',
            //     'message': 'Ticket non valide',
            //     'date': '2021-09-01T12:00:00Z',
            //   },
            //   {
            //     'code': '#B123456789',
            //     'status': 'success',
            //     'message': 'Ticket validé',
            //     'date': '2021-09-01T12:00:00Z',
            //   },
            //   {
            //     'code': '#B123456789',
            //     'status': 'error',
            //     'message': 'Ticket non valide',
            //     'date': '2021-09-01T12:00:00Z',
            //   },
            //   {
            //     'code': '#B123456789',
            //     'status': 'success',
            //     'message': 'Ticket validé',
            //     'date': '2021-09-01T12:00:00Z',
            //   },
            //   {
            //     'code': '#B123456789',
            //     'status': 'error',
            //     'message': 'Ticket non valide',
            //     'date': '2021-09-01T12:00:00Z',
            //   },
            // ].reversed.toList();
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => Scaffold(
                  appBar: AppBar(
                    title: const Text('Historique'),
                  ),
                  body: histories.isEmpty
                      ? const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.history, size: 60),
                              SizedBox(height: 20),
                              Text('Aucun historique'),
                            ],
                          ),
                        )
                      : ListView.separated(
                          separatorBuilder: (context, index) =>
                              const Divider(height: 0),
                          itemCount: histories.length,
                          itemBuilder: (context, index) {
                            final history = histories[index];
                            return ListTile(
                              leading: Icon(
                                history['status'] == 'success'
                                    ? Icons.check_circle
                                    : Icons.error,
                                color: history['status'] == 'success'
                                    ? primaryColor
                                    : Colors.red,
                              ),
                              tileColor: history['status'] == 'success'
                                  ? null
                                  : Colors.red.withOpacity(0.1),
                              title: Text(history['code'] as String),
                              subtitle: Text(history['message'] as String),
                              trailing: Text(history['date'] as String),
                            );
                          },
                        ),
                ),
              ),
            );
          },
          child: const Icon(Icons.history),
        ),
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
            buildQrView(context, controller, scan),
            const SafeArea(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  // ObLogo(height: 24, vPadding: 16),
                ],
              ),
            ),
            Positioned(
                bottom: 100,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton.filledTonal(
                        onPressed: () {
                          controller.value?.toggleFlash();

                          // ignore
                          //isLoading.value = true;
                          // FlutterRingtonePlayer()
                          //     .play(fromAsset: "assets/success_2.mp3")
                          //     .whenComplete(() async {
                          //   await Future.delayed(
                          //       const Duration(milliseconds: 700));
                          //   ScaffoldMessenger.of(context)
                          //       .showSnackBar(const SnackBar(
                          //     content: Text('Ticket non valide'),
                          //     duration: Duration(seconds: 3),
                          //   ));
                          // });
                          // ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          //   content: Text(response.data['message'] as String? ??
                          //       'Ticket non valide'),
                          //   duration: const Duration(seconds: 3),
                          // ));
                        },
                        icon: const Icon(Icons.flash_on_rounded)),
                    const SizedBox(width: 20),
                    IconButton.filledTonal(
                        onPressed: () {
                          //isLoading.value = false;
                          controller.value?.flipCamera();
                        },
                        icon: const Icon(Icons.flip_camera_ios)),
                  ],
                )),
            if (isLoading.value)
              const Positioned(
                top: 100,
                left: 0,
                right: 0,
                child: SizedBox(
                  width: 30,
                  height: 30,
                  child: Center(
                    child: CircularProgressIndicator(
                      color: Colors.white,
                    ),
                  ),
                ),
              )
          ],
        ));
  }

  Widget buildQrView(
      BuildContext context,
      ValueNotifier<QRViewController?> scannerState,
      Future<void> Function(String?) scan) {
    return QRView(
      key: _qrKey,
      onQRViewCreated: (controller) async {
        scannerState.value = controller;
        controller.scannedDataStream.listen((barcode) async {
          if (barcode.code != null) {
            if (barcode.code!.startsWith('#B')) {
              await scan(barcode.code);
            } else {
              showToast('Ticket non pris en charge');
            }
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
