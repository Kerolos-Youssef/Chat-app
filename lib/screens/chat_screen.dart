import 'package:flutter/material.dart';
import 'package:flashchat/constants.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

final _firestore = FirebaseFirestore.instance;
User loggedInUser;

class ChatScreen extends StatefulWidget {
  static const String id = "Chat";
  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final messageTextController = TextEditingController();
  String messageText;
  final _auth = FirebaseAuth.instance;
  @override
  void initState() {
    super.initState();
    getCurrentUser();
  }

  void getCurrentUser() async {
    final user = await _auth.currentUser;
    if (user != null) {
      loggedInUser = user;
      print(loggedInUser.email);
    }
  }

  void messagesStream() async {
    await for (var snapshot in _firestore.collection('messages').snapshots()) {
      for (var messages in snapshot.docs) {
        print(messages.data());
      }
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
                _auth.signOut();
                Navigator.pop(context);
                //messagesStream();
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
                      controller: messageTextController,
                      onChanged: (value) {
                        messageText = value;
                      },
                      decoration: kMessageTextFieldDecoration,
                    ),
                  ),
                  FlatButton(
                    onPressed: () {
                      messageTextController.clear();
                      _firestore.collection('messages').add({
                        'text': messageText,
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
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: CircularProgressIndicator(
                  backgroundColor: Colors.lightBlueAccent,
                ),
              ),
            );
          }
          final messages = snapshot.data.docs;
          List<MessageBubbles> WidgetMessages = [];
          for (var message in messages) {
            final messageText = message['text'];
            final messageSender = message['sender'];
            final currentUser = loggedInUser.email;
            if (currentUser == messageSender) {
              //The message from the logged in user
            }
            final messageBubbles = MessageBubbles(
              sender: messageSender,
              text: messageText,
              isMe: currentUser == messageSender,
            );
            WidgetMessages.add(messageBubbles);
          }
          return Expanded(
            child: ListView(
              reverse: true,
              padding: EdgeInsets.symmetric(horizontal: 15, vertical: 20),
              children: WidgetMessages,
            ),
          );
        });
  }
}

class MessageBubbles extends StatelessWidget {
  final String text, sender;
  final bool isMe;
  MessageBubbles({this.text, this.sender, this.isMe});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment:
          isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(
          sender,
          style: TextStyle(fontSize: 12, color: Colors.black54),
        ),
        Material(
          borderRadius: isMe
              ? BorderRadius.only(
                  topLeft: Radius.circular(45),
                  bottomLeft: Radius.circular(45),
                  bottomRight: Radius.circular(45),
                )
              : BorderRadius.only(
                  topRight: Radius.circular(45),
                  bottomLeft: Radius.circular(45),
                  bottomRight: Radius.circular(45),
                ),
          elevation: 5,
          color: isMe ? Color(0XFF4FC3F7) : Colors.white,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            child: Text(
              text,
              style: TextStyle(
                  fontSize: 16, color: isMe ? Colors.white : Colors.black),
            ),
          ),
        ),
        SizedBox(
          height: 10,
        )
      ],
    );
    ;
  }
}
