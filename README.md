flutter-web-socket-demo

## Node Setup Instructions

1. cd into nodejs-ws
2. Run "npm install"
3. then "node index.js"

## Flutter Setup Instructions
1. In flutter project, under flutter_websocker_app_demo
2. change your host ip in MyApp
3. channel: IOWebSocketChannel.connect('ws://192.168.1.XX:3000'),

A helper boolean is set 
 //Uncomment to test image, note this crashes the app
  bool textOnly = true;

This allows you to just send text message, as of now this works great, its an echo server, just sends back what you send it

If you uncomment "bool textOnly = true;"

You can use the image picker to send a image. Right now the image picker to send an image over web socket is broken. Pull requests are welcome. 
