
const app = require('express')()
const port = 3000
const http = require('http').createServer(app)
console.log("started")

app.get('/', (req, res) => {
    res.send("Node Server is running. Yay!!")
})

//Socket Logic
const socketio = require('socket.io')(http)

socketio.on("connection", (userSocket) => {
    console.log('a user connected');
    userSocket.on("send_message", (data) => {
        console.log(data);
        userSocket.broadcast.emit("receive_message", data)
    })
})

http.listen(port)