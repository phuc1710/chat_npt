import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:random_avatar/random_avatar.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:text_to_speech/text_to_speech.dart';

import 'http_utils.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key, required this.box});

  final Box box;

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  Box box = Hive.box('chat_history');
  final TextEditingController _textController = TextEditingController();
  late List<String> messages;
  final ScrollController _scrollController = ScrollController();
  TextToSpeech tts = TextToSpeech();
  bool _voiceEnabled = true;
  bool isEn = true;
  SpeechToText speech = SpeechToText();
  bool speechEnable = false;
  List<LocaleName> locale = [];
  LocaleName selectedLocale = LocaleName('', '');

  @override
  void initState() {
    super.initState();
    _initSpeech();
    messages = box.get('messages', defaultValue: <String>[]);
    isEn = box.get('isEn', defaultValue: true);
    scrollToBottom();
    tts.setLanguage(isEn ? 'en-US' : 'vi-VN');
    selectedLocale = LocaleName(isEn ? 'en-US' : 'English (United States)',
        isEn ? 'vi-VN' : 'Vietnamese (Vietnam)');
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
                      selectedLocale =
                          LocaleName('en-US', 'English (United States)');
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
                      selectedLocale =
                          LocaleName('vi-VN', 'Vietnamese (Vietnam)');
                    });
                  },
                ),
                PopupMenuItem(
                    onTap: () => setState(() {
                          _voiceEnabled = !_voiceEnabled;
                          tts.stop();
                        }),
                    child: Text(_voiceEnabled
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
              suffixIcon: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  InkWell(
                      onTap: () {
                        speech.isNotListening
                            ? _startListening()
                            : _stopListening();
                      },
                      child: Icon(
                          speech.isNotListening ? Icons.mic : Icons.mic_off)),
                  const SizedBox(width: 10),
                  InkWell(
                      onTap: () async {
                        if (_textController.text.isEmpty) return;
                        setState(() {
                          messages.add(_textController.text);
                          _textController.clear();
                          scrollToBottom();
                        });
                        var response =
                            await getResponse(getRequestBody(messages));
                        setState(() {
                          messages.add(response);
                          scrollToBottom();
                          box.put('messages', messages);
                          if (_voiceEnabled) tts.speak(response);
                        });
                      },
                      child: const Icon(Icons.send)),
                ],
              ),
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

  void _initSpeech() async {
    _voiceEnabled = await speech.initialize();
    locale = await speech.locales();
    setState(() {});
  }

  void _startListening() async {
    await speech.listen(
        onResult: _onSpeechResult, localeId: selectedLocale.localeId);
    setState(() {});
  }

  void _stopListening() async {
    await speech.stop();
    setState(() {});
  }

  void _onSpeechResult(SpeechRecognitionResult result) {
    setState(() {
      _textController.text = result.recognizedWords;
    });
  }
}
