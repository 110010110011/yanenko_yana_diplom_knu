import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:confirm_dialog/confirm_dialog.dart';
import 'package:my_app/saveImage.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'parametersActions.dart';
import 'package:flutter/material.dart';
import 'package:web_socket_channel/status.dart' as status;
import 'package:uuid/uuid.dart';

void main() => runApp(const SPMapp());

class SPMapp extends StatelessWidget {
  const SPMapp({super.key});

  static const String _title = 'Virtual Scanning Probe Microscope';

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: _title, // The title of app, which appears in the app's title bar.
      home: Scaffold(
        resizeToAvoidBottomInset: false,
        appBar: AppBar(title: const Text(_title)),
        body: const MyStatefulWidget(), // The main content of the app, represented here by the MyStatefulWidget.
      )
    );
  }
}

class MyStatefulWidget extends StatefulWidget {
  const MyStatefulWidget({super.key}); // Additional parameters can be added if needed

  @override
  State<MyStatefulWidget> createState() => _MyStatefulWidgetState();
  }
  // Define a custom FocusNode class named FirstDisabledFocusNode
  class FirstDisabledFocusNode extends FocusNode {
    // Override the consumeKeyboardToken method to return false
    @override
    bool consumeKeyboardToken() {
      return false;
    }
  }

class _MyStatefulWidgetState extends State<MyStatefulWidget>
    with SingleTickerProviderStateMixin {
  MicroscopeParams microscopeParams = MicroscopeParams(); // Instance of MicroscopeParams class, likely containing parameters for the microscope
  SaveImages saveImg = SaveImages();  // Instance of SaveImages class, likely responsible for saving images
  late List<Color?> startPixels; // List of colors representing pixels, declared as late to be initialized in initState
  late int rowStartPoint; // Starting point for the row, declared as late to be initialized in initState
  late List<dynamic> messages = <dynamic>[];
  late Uuid processIndex;

  // WebSocket channel for communication, connecting to a local server
  late WebSocketChannel channel;
  late int targetIndex;
  late int counter;

  final _inputParameterFieldController = TextEditingController();

  @override
  void initState(){
    super.initState();
    // Initialize pixels with a list filled with grey color, based on microscope parameters
    startPixels = List.filled(pow(microscopeParams.sizeInPxl, 2).toInt(), Colors.grey[200]);
  }

  // Variables for dropdown selection and names, with initial value for dropdown
  String? dropdownSelectedValue = "0";

  // Boolean to track if scanning is in progress
  bool isScanning = false;
  bool startEnabled = true;
  bool resumePauseEnabled = false;

  void scan(){
    setState(() {
      channel = WebSocketChannel.connect(
        Uri.parse('ws://10.0.2.2:8080/ws'),
      );
    });

    var paramsMessage = jsonEncode(microscopeParams);

    channel.sink.add(paramsMessage);

    channel.stream.listen((message) {
      setState(() {
        if (!messages.contains(message)) {
          messages.add(message);

          var heightValue = double.parse(messages.last.toString().split(',')[0]);
          targetIndex = int.parse(messages.last.toString().split(',')[1]);
          var pixel = getColorFromNumber(heightValue);

          drawPixels(pixel, targetIndex);
        }
      });
    });
  }

  void drawPixels(Color pixel, int targetIndex){
    setState(() {
      startPixels[targetIndex] = pixel;
    });
  }

  void stopScanning(){
    channel.sink.close(status.goingAway);
  }

  Color getColorFromNumber(double number){
    if (number == 0){
      return Colors.black;
    }
    else if (number < 0.3){
      return Color.fromARGB(255, 1, 1, (255 * number).toInt());
    }
    else if (number >= 0.3 && number < 0.5){
      return Color.fromARGB(255, (255 * number).toInt(), (255 * number).toInt(), 255);
    }
    else if (number >= 0.5 && number < 0.9){
      return Color.fromARGB(255, 255, 255, (255 * (number - 0.5)).toInt());
    }
    else{
      return Color.fromARGB(255, 255, 255, (255 * number).toInt());
    }
  }

  Future<void> confirmationDialog() async {
    if (await confirm(
      context,
      title: const Text('Confirm Clean'),
      content: const Text('Are you sure you want to clean params and image?'),
      textOK: const Text('Yes'),
      textCancel: const Text('No'),)) {

      _inputParameterFieldController.clear();

      stopScanning();

      setState(() {
        microscopeParams = MicroscopeParams();
        startEnabled = true;
        resumePauseEnabled = false;

        startPixels = List.filled(microscopeParams.sizeInPxl * microscopeParams.sizeInPxl, Colors.grey[200]);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Container(
        decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.black,
                Colors.indigo,
                Colors.blue,
                Colors.blue,
                Colors.yellow,
                Colors.yellow,
                Colors.yellow,
                Colors.yellow,
                Colors.white
              ],
            )
        ),
        width: MediaQuery.of(context).size.width,
        height: 50,
      ),

      const Divider(color: Colors.black, height: 1, thickness: 3),

    Expanded(
      flex: 0,
      child: RepaintBoundary(
        key: saveImg.globalKey,
        child: GridView.builder(
          shrinkWrap: true,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: microscopeParams.sizeInPxl,
          ),
          itemCount: startPixels.length,
          itemBuilder: (BuildContext context, int index) {
            return Container(
              color: startPixels[index],
            );
          },
        ),
      ),
    ),

      Row(
        children: [
          Expanded(
            child: ElevatedButton(
              style: TextButton.styleFrom(
                textStyle: const TextStyle(fontSize: 20),
                backgroundColor: startEnabled ? Colors.white70 : Colors.white12
              ),
              onPressed: () {
                if (startEnabled){
                  isScanning = true;
                  startEnabled = false;
                  resumePauseEnabled = true;
                  microscopeParams.processId = const Uuid().v1();
                  scan();
                }
              },
              child: const Text('Start'),
            ),
          ),
          Expanded(
            child: ElevatedButton(
              style: TextButton.styleFrom(
                textStyle: const TextStyle(fontSize: 20),
                backgroundColor: resumePauseEnabled ? Colors.white70 : Colors.white12
              ),
              child: isScanning ? const Text('Pause') : const Text('Resume'),
              onPressed: (){
                if(isScanning){
                  stopScanning();
                }else{
                  scan();
                }
                setState(() {
                  isScanning = !isScanning;
                });
              },
            ),
          ),
        ],
      ),

      const Padding(
        padding: EdgeInsets.all(10.0),
      ),

      Row(
        children: [
          Expanded(
              child: DropdownButtonFormField(
                decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: "All parameters"),
                value: "0",
                items: const [
                  DropdownMenuItem(
                    value: "0",
                    child:
                    Text("Time per pixel, ms${500}"),),
                  DropdownMenuItem(
                    value: "1",
                    child:
                    Text("Feedback Proportional"),),
                  DropdownMenuItem(
                    value: "2",
                    child:
                    Text("Feedback Integral"),),
                  DropdownMenuItem(
                    value: "3",
                    child:
                    Text("Feedback Differential"),),
                  DropdownMenuItem(
                    value: "4",
                    child:
                    Text("Size in Pixels"),),
                  DropdownMenuItem(
                    value: "5",
                    child:
                    Text("Size in nm"),),
                  DropdownMenuItem(
                    value: "6",
                    child:
                    Text("Sample Bias, V"),),
                  DropdownMenuItem(
                    value: "7",
                    child:
                    Text("Tunneling Current, nA"),),
                  DropdownMenuItem(
                    value: "8",
                    child:
                    Text("Sample Name"),),
                  DropdownMenuItem(
                    value: "9",
                    child:
                    Text("Tip Name"),),
                ],
                onChanged: (v) {
                  dropdownSelectedValue = v;
                  },
              )
          )
        ],
      ),

      const Padding(
        padding: EdgeInsets.all(5.0),
      ),

      Row(
        children: [
          Expanded(
            child: TextField(
                controller: _inputParameterFieldController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: "Input your parameters"),
                textAlign: TextAlign.center,
                onSubmitted: (String input) {
                  microscopeParams.setValue(input, dropdownSelectedValue);
                  setState(() {
                    startPixels = List.filled(pow(microscopeParams.sizeInPxl, 2).toInt(), Colors.grey[200]);
                  });
                }
            ),
          ),
        ],
      ),

      const Padding(
        padding: EdgeInsets.all(5.0),
      ),

      Row(
        children: [
          Expanded(
            child: ElevatedButton(
              style: TextButton.styleFrom(
                textStyle: const TextStyle(fontSize: 20),
                backgroundColor: Colors.white70
              ),
              onPressed: () async {
                await confirmationDialog();
              },
              child: const Text('Clean'),
            ),
          ),
          Expanded(
            child: ElevatedButton(
              style: TextButton.styleFrom(
                textStyle: const TextStyle(fontSize: 20),
                backgroundColor: Colors.white70
              ),
              onPressed: () => {saveImg.captureAndSave()},

              child: const Text('Save'),
            ),
          ),
        ],
      ),
    ]);

  }
}

