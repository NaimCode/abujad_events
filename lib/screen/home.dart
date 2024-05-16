import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lottie/lottie.dart';
import 'package:oktoast/oktoast.dart';
import 'package:supmti_events/styles/colors.dart';
import 'package:supmti_events/utils/api.dart';
import 'package:supmti_events/utils/box.dart';

class Home extends HookConsumerWidget {
  const Home({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Container(
                height: 400,
                width: double.infinity,
                color: primaryColor,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Lottie.network(
                        'https://lottie.host/fde6aa22-c568-4ac6-92a1-cbc16a3339f3/KNcmz1uHcY.json',
                        width: 200),
                    Text('SUPMTI',
                        style: Theme.of(context)
                            .textTheme
                            .displayLarge!
                            .copyWith(
                                color: Colors.white,
                                fontSize: 30,
                                fontWeight: FontWeight.bold)),
                    const SizedBox(height: 5),
                    Text('Events',
                        style: Theme.of(context)
                            .textTheme
                            .displayMedium!
                            .copyWith(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold)),
                  ],
                )),
            const LoginSection(),
          ],
        ),
      ),
    );
  }
}

final _key = GlobalKey<FormState>();

class LoginSection extends HookConsumerWidget {
  const LoginSection({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final email = useTextEditingController();
    final password = useTextEditingController();

    final api = ref.watch(apiProvider);
    final loading = useState(false);
    Future<void> login() async {
      loading.value = true;
      try {
        final response = await api.post(
            'https://events-preprod.supmti.ac.ma/src/api/authentification.php',
            data: {
              'email': email.text,
              'mot_de_passe': password.text,
            });
        final token = response.data['token'];
        await Box.setToken(token);
      } catch (e) {
        showToast('Erreur de connexion, veuillez réessayer');
      }
      loading.value = false;
    }

    return Form(
      key: _key,
      child: Padding(
        padding: const EdgeInsets.all(30.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Authenfication',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge!
                    .copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 40),
            TextFormField(
              controller: email,
              validator: (value) {
                if (value!.isEmpty) {
                  return 'Email est obligatoire';
                }
                if (!value.contains('@')) {
                  return 'Email invalide';
                }
                return null;
              },
              decoration: const InputDecoration(
                filled: true,
                labelText: 'Email',
              ),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: password,
              validator: (value) {
                if (value!.isEmpty) {
                  return 'Mot de passe est obligatoire';
                }
                return null;
              },
              obscureText: true,
              decoration: const InputDecoration(
                filled: true,
                labelText: 'Password',
              ),
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: 250,
              child: InkWell(
                onTap: () {
                  if (_key.currentState!.validate()) {
                    login();
                  }
                },
                borderRadius: BorderRadius.circular(5),
                child: Container(
                  height: 50,
                  decoration: BoxDecoration(
                    color: loading.value ? Colors.grey.shade200 : Colors.amber,
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: loading.value
                      ? Center(
                          child: Transform.scale(
                            scale: 0.5,
                            child: const CircularProgressIndicator(),
                          ),
                        )
                      : const Center(
                          child: Text('Login',
                              style: TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.w600))),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
