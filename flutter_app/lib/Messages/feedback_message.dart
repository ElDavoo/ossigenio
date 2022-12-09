import '../Messages/message.dart';

enum FeedbackValues { nothing, positive, neutral, negative}

class FeedbackMessage extends Message {
  late final int rawData;
  late final int temperature;
  late final int humidity;
  late final FeedbackValues feedback;

  @override
  int get type => MessageTypes.feedbackMessage;

}

class FeedbackMessageRequest extends Message {
  @override
  int get type => MessageTypes.msgRequest4;
}