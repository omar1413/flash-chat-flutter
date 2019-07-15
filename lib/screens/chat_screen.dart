import 'package:flutter/material.dart';
import 'package:flash_chat/constants.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

final _firestore = Firestore.instance;
FirebaseUser loggedInUser;

class ChatScreen extends StatefulWidget {
  static const String id = 'chat_screen';
  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _auth = FirebaseAuth.instance;

  String messageText;

  final textEditingController = TextEditingController();

  @override
  void initState() {
    super.initState();
    getCurrentUser();
  }

  void getCurrentUser() async {
    try {
      final currentUser = await _auth.currentUser();
      if (currentUser != null) {
        loggedInUser = currentUser;
      }
    } catch (e) {
      print(e);
      //TODO: handle get current user errors
      kErrorMsgAlert(context).show();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: null,
        actions: <Widget>[
          IconButton(
              icon: Icon(Icons.close),
              onPressed: () {
                //Implement logout functionality
                _auth.signOut();
                Navigator.pop(context);
              }),
        ],
        title: Text('⚡️Chat'),
        backgroundColor: Colors.lightBlueAccent,
      ),
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            MessageStream(),
            Container(
              decoration: kMessageContainerDecoration,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Expanded(
                    child: TextField(
                      controller: textEditingController,
                      onChanged: (value) {
                        //Do something with the user input.
                        messageText = value;
                      },
                      decoration: kMessageTextFieldDecoration,
                    ),
                  ),
                  FlatButton(
                    onPressed: () {
                      //Implement send functionality.
                      textEditingController.clear();
                      _firestore.collection('messages').add({
                        'msg': messageText,
                        'sender': loggedInUser.email,
                      });
                    },
                    child: Text(
                      'Send',
                      style: kSendButtonTextStyle,
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

class MessageStream extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore.collection('messages').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return CircularProgressIndicator(
            backgroundColor: Colors.lightBlue,
          );
        }

        List<TextBubble> messageBubbles = [];

        final messages = snapshot.data.documents.reversed;
        for (var message in messages) {
          final msg = message.data['msg'];
          final sender = message.data['sender'];

          if (msg != null) {
            messageBubbles.add(TextBubble(
              msg: msg,
              sender: sender,
              isMe: loggedInUser.email == sender,
            ));
          }
        }
        return Expanded(
            child: ListView(reverse: true, children: messageBubbles));
      },
    );
  }
}

class TextBubble extends StatelessWidget {
  TextBubble({this.msg, this.sender, this.isMe = false});

  final String msg;
  final String sender;
  final bool isMe;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(10.0),
      child: Column(
        crossAxisAlignment:
            isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            sender,
            style: TextStyle(
              fontSize: 13.0,
              color: Colors.black38,
            ),
          ),
          Padding(
            padding: EdgeInsets.only(bottom: 8.0, top: 5.0),
            child: Material(
              elevation: 5.0,
              borderRadius: isMe
                  ? BorderRadius.only(
                      topLeft: Radius.circular(30.0),
                      bottomLeft: Radius.circular(30.0),
                      bottomRight: Radius.circular(30.0),
                    )
                  : BorderRadius.only(
                      topRight: Radius.circular(30.0),
                      bottomLeft: Radius.circular(30.0),
                      bottomRight: Radius.circular(30.0),
                    ),
              color: isMe ? Colors.lightBlue : Colors.white,
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: 8.0,
                  vertical: 10.0,
                ),
                child: Text(
                  msg,
                  style: TextStyle(
                    fontSize: 18,
                    color: isMe ? Colors.white : Colors.black45,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
