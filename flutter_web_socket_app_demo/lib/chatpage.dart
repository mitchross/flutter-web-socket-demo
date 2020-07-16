import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_socket_io/flutter_socket_io.dart';
import 'package:flutter_socket_io/socket_io_manager.dart';
import 'package:flutter_web_socket_app_demo/message.dart';
import 'package:image_picker/image_picker.dart';

class ChatPage extends StatefulWidget {
  @override
  _ChatPageState createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  SocketIO socketIO;
  List<Message> messages;

  double height, width;
  TextEditingController textController;
  ScrollController scrollController;
  PickedFile _image;
  final picker = ImagePicker();

  Future getImage() async {
    final pickedFile = await picker.getImage(
        source: ImageSource.camera, maxHeight: 250.0, maxWidth: 250.0);

    setState(() {
      _image = PickedFile(pickedFile.path);
      _sendImageMessage2();
    });
  }

  @override
  void initState() {
    //Initializing the message list
    messages = List<Message>();

    //Initializing the TextEditingController and ScrollController
    textController = TextEditingController();
    scrollController = ScrollController();
    //Creating the socket
    socketIO = SocketIOManager().createSocketIO(
      'http://192.168.1.94:3000',
      '/',
    );
    //Call init before doing anything with socket
    socketIO.init();
    //Subscribe to an event to listen to
    socketIO.subscribe('receive_message', (jsonData) {
      //Convert the JSON data received into a Map
      Map<String, dynamic> data = json.decode(jsonData);
      if (data['img'] != null) {
        this.setState(() => messages.add(new Message(null, data['img'])));
      } else {
        this.setState(() => messages.add(new Message(data['message'], null)));
      }
      scrollController.animateTo(
        scrollController.position.maxScrollExtent,
        duration: Duration(milliseconds: 600),
        curve: Curves.ease,
      );
    });
    //Connect to the socket
    socketIO.connect();
    super.initState();
  }

  Widget buildSingleMessage(int index) {
    Message myMessage = messages[index];

    if (myMessage.base64Image != null) {
      return Container(
        alignment: Alignment.centerLeft,
        child: Container(
          padding: const EdgeInsets.all(20.0),
          margin: const EdgeInsets.only(bottom: 20.0, left: 20.0),
          decoration: BoxDecoration(
            color: Colors.deepPurple,
            borderRadius: BorderRadius.circular(20.0),
          ),
          child: Image.memory(getImageFromBase64(myMessage.base64Image)),
        ),
      );
    } else {
      return Container(
        alignment: Alignment.centerLeft,
        child: Container(
          padding: const EdgeInsets.all(20.0),
          margin: const EdgeInsets.only(bottom: 20.0, left: 20.0),
          decoration: BoxDecoration(
            color: Colors.deepPurple,
            borderRadius: BorderRadius.circular(20.0),
          ),
          child: Text(
            myMessage.text,
            style: TextStyle(color: Colors.white, fontSize: 15.0),
          ),
        ),
      );
    }
  }

  Widget buildMessageList() {
    return Container(
      height: height * 0.6,
      width: width,
      child: ListView.builder(
        controller: scrollController,
        itemCount: messages.length,
        itemBuilder: (BuildContext context, int index) {
          return buildSingleMessage(index);
        },
      ),
    );
  }

  Widget buildChatInput() {
    return Container(
      width: width * 0.7,
      padding: const EdgeInsets.all(2.0),
      margin: const EdgeInsets.only(left: 40.0),
      child: TextField(
        decoration: InputDecoration.collapsed(
          hintText: 'Send a message...',
        ),
        controller: textController,
      ),
    );
  }

  Widget buildSendButton() {
    return FloatingActionButton(
      backgroundColor: Colors.deepPurple,
      onPressed: () {
        //Check if the textfield has text or not
        if (textController.text.isNotEmpty) {
          //Send the message as JSON data to send_message event
          socketIO.sendMessage(
              'send_message', json.encode({'message': textController.text}));
          //Add the message to the list
          this.setState(() => messages.add(Message(textController.text, null)));
          textController.text = '';
          //Scrolldown the list to show the latest message
          scrollController.animateTo(
            scrollController.position.maxScrollExtent,
            duration: Duration(milliseconds: 600),
            curve: Curves.ease,
          );
        }
      },
      child: Icon(
        Icons.send,
        size: 30,
      ),
    );
  }

  Widget buildInputArea() {
    return Container(
      height: height * 0.1,
      width: width,
      child: Row(
        children: <Widget>[
          buildChatInput(),
          buildSendButton(),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    height = MediaQuery.of(context).size.height;
    width = MediaQuery.of(context).size.width;

    return Scaffold(body: SafeArea(
      child: LayoutBuilder(builder: (context, constraints) {
        return SingleChildScrollView(
            child: ConstrainedBox(
                constraints: BoxConstraints(
                    minWidth: constraints.maxWidth,
                    minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Column(mainAxisSize: MainAxisSize.max, children: [
                    Padding(
                      padding: EdgeInsets.only(top: 6.0),
                    ),
                    Expanded(
                      child: Container(
                        child: buildMessageList(),
                      ),
                    ),
                    RaisedButton(
                      child: Text("Image"),
                      onPressed: getImage,
                    ),
                    buildInputArea(),
                  ]),
                )));
      }),
    ));
  }

  void _sendImageMessage2() {
    if (_image.path != null) {
      //trying something no luck
      Future<Uint8List> bytesImage = _image.readAsBytes();
      bytesImage.then((value) => sendFunc(value));
    }
  }

  getImageFromBase64(value) {
    return base64Decode(value);
  }

  String base64Encode(List<int> value) => base64.encode(value);
  Uint8List base64Decode(String source) => base64.decode(source);

  void sendFunc(value) {
    String base64 = base64Encode(value);

    //sending messaget to another device via socket io
    socketIO.sendMessage('send_message', json.encode({'img': base64}));

    //this is the inline preview
    this.setState(() => messages.add(Message(null, base64)));
  }
}
