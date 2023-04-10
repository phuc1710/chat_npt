import 'package:flutter/material.dart';
import 'package:random_avatar/random_avatar.dart';

import 'http_utils.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _textController = TextEditingController();
  List<String> messages = [];
  final ScrollController _scrollController = ScrollController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(title: const Text('ChatNPT')),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              itemCount: messages.length,
              shrinkWrap: true,
              itemBuilder: (context, index) => Container(
                color: (index & 1 == 1) ? Colors.grey[200] : Colors.white,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: RandomAvatar((index & 1 == 1) ? 'ChatNPT' : 'p',
                            width: 40),
                      ),
                      Expanded(child: Text(messages[index])),
                    ],
                  ),
                ),
              ),
            ),
          ),
          TextField(
            controller: _textController,
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              hintText: 'Input message',
              suffixIcon: InkWell(
                  onTap: () async {
                    if (_textController.text.isEmpty) return;
                    setState(() {
                      messages.add(_textController.text);
                      _textController.clear();
                      scrollToBottom();
                    });
                    var response = await getResponse(getRequestBody(messages));
                    setState(() {
                      messages.add(response);
                      scrollToBottom();
                    });
                  },
                  child: const Icon(Icons.send)),
            ),
            textInputAction: TextInputAction.send,
          )
        ],
      ),
    );
  }

  void scrollToBottom() {
    return WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }
}
