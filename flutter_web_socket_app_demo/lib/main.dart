import 'dart:convert';
import 'dart:io';

import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

/**
 * use image picker example for futher reading and more concrete implementation
 * https://github.com/flutter/plugins/blob/master/packages/image_picker/image_picker/example/lib/main.dart
 */
void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final title = 'WebSocket Demo';
    return MaterialApp(
      title: title,
      home: MyHomePage(
        title: title,
        channel: IOWebSocketChannel.connect('ws://192.168.1.XX:3000'),
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  final String title;
  final WebSocketChannel channel;

  MyHomePage({Key key, @required this.title, @required this.channel})
      : super(key: key);

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  PickedFile _image;
  final picker = ImagePicker();

  //Uncomment to test image, note this crashes the app
  bool textOnly = true;

  TextEditingController _controller = TextEditingController();

  Future getImage() async {
    final pickedFile = await picker.getImage(source: ImageSource.camera);

    setState(() {
      _image = PickedFile(pickedFile.path);
      if (!textOnly) {
        _sendImageMessage();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            RaisedButton(
              child: Text("Image"),
              onPressed: getImage,
            ),
            Form(
              child: TextFormField(
                controller: _controller,
                decoration: InputDecoration(labelText: 'Send a message'),
              ),
            ),
            StreamBuilder(
              stream: widget.channel.stream,
              builder: (context, snapshot) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24.0),
                  child: Column(
                    children: <Widget>[
                      Text(snapshot.hasData &&
                              snapshot.data.runtimeType == String
                          ? '${snapshot.data}'
                          : ''),
                      Center( 
                          child: !textOnly? Image.memory(_getImageFromBase64( snapshot.data)) : Text("test"),
                          )
                          
                    ],
                  ),
                );
              },
            )
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _sendMessage,
        tooltip: 'Send message',
        child: Icon(Icons.send),
      ),

      // This trailing comma makes auto-formatting nicer for build methods.
    );
  }

  void _sendMessage() {
    if (_controller.text.isNotEmpty) {
      widget.channel.sink.add(_controller.text);
    }
  }

  Uint8List _getImageFromBase64(base64Image) {
    final _byteImage = Base64Decoder().convert(base64Image);
    return _byteImage;
  }

  void _sendImageMessage() {
    if (_image.path != null) {
      //trying something no luck
      // Future<Uint8List> bytesImage = _image.readAsBytes();
      // bytesImage.then((value) =>
      // {widget.channel.sink.add(value)});

      final bytes = File(_image.path).readAsBytesSync();
      String img64 = base64Encode(bytes);
      widget.channel.sink.add(img64);
    }
  }

  @override
  void dispose() {
    widget.channel.sink.close();
    super.dispose();
  }
}
