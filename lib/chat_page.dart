import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:random_avatar/random_avatar.dart';
import 'package:text_to_speech/text_to_speech.dart';

import 'http_utils.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key, required this.box});

  final Box box;

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  var box = Hive.box('chat_history');
  final TextEditingController _textController = TextEditingController();
  late List<String> messages;
  final ScrollController _scrollController = ScrollController();
  TextToSpeech tts = TextToSpeech();
  bool _speechEnabled = true;
  bool isEn = true;

  @override
  void initState() {
    super.initState();
    messages = box.get('messages', defaultValue: <String>[]);
    isEn = box.get('isEn', defaultValue: true);
    scrollToBottom();
    tts.setLanguage(isEn ? 'en-US' : 'vi-VN');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ChatNPT'),
        actions: [
          PopupMenuButton(
            itemBuilder: (context) {
              return [
                PopupMenuItem(
                  child: const Text('English'),
                  onTap: () {
                    setState(() {
                      isEn = true;
                      box.put('isEn', true);
                      tts.setLanguage('en-US');
                    });
                  },
                ),
                PopupMenuItem(
                  child: const Text('Tiếng Việt'),
                  onTap: () {
                    setState(() {
                      isEn = false;
                      box.put('isEn', false);
                      tts.setLanguage('vi-VN');
                    });
                  },
                ),
                PopupMenuItem(
                    onTap: () => setState(() {
                          _speechEnabled = !_speechEnabled;
                          tts.stop();
                        }),
                    child: Text(_speechEnabled
                        ? isEn
                            ? 'Disable voice'
                            : 'Tắt đọc'
                        : isEn
                            ? 'Enable voice'
                            : 'Bật đọc')),
                PopupMenuItem(
                    child:
                        Text(isEn ? 'Clear chat history' : 'Xóa lịch sử chat'),
                    onTap: () => setState(() {
                          messages.clear();
                          box.put('messages', messages);
                        }))
              ];
            },
            enableFeedback: false,
          )
        ],
      ),
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
                        child: Column(
                          children: [
                            RandomAvatar((index & 1 == 1) ? 'ChatNPT' : 'p',
                                width: 40),
                            if (index & 1 == 1)
                              Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: InkWell(
                                  onTap: () => tts.speak(messages[index]),
                                  child: const Icon(Icons.play_circle),
                                ),
                              )
                          ],
                        ),
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
              hintText: isEn ? 'Input message' : 'Nhập tin nhắn',
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
                      box.put('messages', messages);
                      if (_speechEnabled) tts.speak(response);
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
