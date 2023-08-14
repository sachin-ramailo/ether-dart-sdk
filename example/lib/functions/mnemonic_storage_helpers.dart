import 'package:flutter/services.dart';

const platform = MethodChannel('mnemonic_channel');

// Call the Kotlin method to save mnemonic
Future<void> _saveMnemonic({
  required String key,
  required String mneumonic,
  bool useBlockstore = true,
  bool forceBlocStore = false,
}) async {
  try {
    final data = await platform.invokeMethod('saveMnemonic', {
      'key': key,
      'mnemonic': mneumonic,
      'useBlockstore': useBlockstore, // or false
      'forceBlockstore': forceBlocStore, // or true
    });
    print("Save mnemonic $data");
  } on PlatformException catch (e) {
    print("Failed to save mnemonic: ${e.message}");
  } catch (e) {
    print("haha $e");
  }
}

// Call the Kotlin method to read mnemonic
Future<String> _readMnemonic(String key) async {
  try {
    print("Read mneumonci tapped");
    final mnemonic = await platform.invokeMethod<String>(
      'readMnemonic',
      {
        'key': key,
      },
    );
    return mnemonic ?? '';
  } on PlatformException catch (e) {
    return '';
  } catch (e) {
    //TODO handle this
    return "";
  }
}
