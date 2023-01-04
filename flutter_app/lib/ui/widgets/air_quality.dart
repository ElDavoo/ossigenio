import 'package:flutter/material.dart';
import 'package:flutter_app/Messages/message.dart';
import 'package:flutter_app/managers/ble_man.dart';
import 'package:flutter_app/utils/device.dart';
import 'package:flutter_app/utils/ui.dart';

import '../../Messages/co2_message.dart';

// A stateful widget which gets the stream of co2 values
// from a BLE device and displays them
class AirQualityLocal extends StatefulWidget {
  final Device device;

  const AirQualityLocal({Key? key, required this.device}) : super(key: key);

  @override
  _AirQualityLocalState createState() => _AirQualityLocalState();
}

class _AirQualityLocalState extends State<AirQualityLocal> {
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const FittedBox(
            fit: BoxFit.fitWidth,
            alignment: Alignment.topLeft,
            child: Text(
              "La qualità dell'aria è",
              style: TextStyle(fontSize: 320),
            )),

        //Padding to separate the text from the dropdown
        //const Padding(padding: EdgeInsets.all(10.0)),
        StreamBuilder(
          stream: BLEManager().dvc != null
              ? BLEManager().dvc!.messagesStream
              : null,
          builder: (BuildContext context, AsyncSnapshot snapshot) {
            if (snapshot.hasData) {
              MessageWithDirection msg = snapshot.data;
              if (msg.message is CO2Message) {
                CO2Message co2 = msg.message as CO2Message;

                return SizedBox(
                  height: 390,
                  child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                              child: Column(
                            children: [
                              AirQualityText(co2: co2.co2),
                              Padding(
                                padding: const EdgeInsets.fromLTRB(0, 20, 0, 0),
                                child: Text(
                                    // Insert temperature
                                    buildExplanationText(co2),
                                    style: const TextStyle(fontSize: 16),
                                  ),
                              ),
                            ],
                          )),

                          UIWidgets.verticalSlider(
                                Colors.green, co2.co2.toDouble()),
                        ]
                  ),
                );
              } else {
                return const Text("Loading...");
              }
            } else {
              return const Text("Loading...");
            }
          },
        )
      ],
    );
  }

  static String buildExplanationText(Message message) {
    String text = "lol";
    if (message is CO2Message) {
      CO2Message co2 = message;
      text = "Temperatura: ${co2.temperature}°C\nUmidità: ${co2.humidity}%";
      text += "\nMisurare la concentrazione di anidride carbonica nell'aria è "
          "importante per assicurare un ambiente sano e confortevole. "
          "Un livello di CO2 troppo alto può causare sonnolenza, "
          "mal di testa, perdita di concentrazione e altri sintomi. "
          "La CO2 viene misurata in PPM (parti per milione).";

      if (co2.co2 < 500) {
        text += "\nLa concentrazione di CO2 è ottima, "
            "non è necessario intervenire.";
      } else if (co2.co2 < 600) {
        text += "\nLa concentrazione di CO2 è buona, "
            "non è necessario intervenire.";
      } else if (co2.co2 < 700) {
        text += "\nLa concentrazione di CO2 è accettabile, "
            "non è necessario intervenire.";
      } else if (co2.co2 < 800) {
        text += "\nLa concentrazione di CO2 è scarsa, "
            "è necessario intervenire.";
      } else if (co2.co2 < 900) {
        text += "\nLa concentrazione di CO2 è pessima, "
            "è necessario intervenire.";
      } else {
        text += "\nLa concentrazione di CO2 è pericolosa, "
            "è necessario intervenire.";
      }
    }

    return text;
  }
}

// A stateful widget which maps a range of co2 values to a text
class AirQualityText extends StatefulWidget {
  final int co2;

  const AirQualityText({Key? key, required this.co2}) : super(key: key);

  @override
  _AirQualityTextState createState() => _AirQualityTextState();
}

class _AirQualityTextState extends State<AirQualityText> {
  @override
  Widget build(BuildContext context) {
    String text = "Loading...";
    TextStyle style = const TextStyle(fontSize: 60);
    if (widget.co2 < 500) {
      text = "eccellente!";
      style = const TextStyle(color: Colors.green, fontSize: 60);
    } else if (widget.co2 < 600) {
      text = "buona";
      style = const TextStyle(color: Colors.yellow, fontSize: 60);
    } else if (widget.co2 < 700) {
      text = "accettabile";
      style = const TextStyle(color: Colors.orange, fontSize: 60);
    } else if (widget.co2 < 800) {
      text = "scarsa";
      style = const TextStyle(color: Colors.red, fontSize: 60);
    } else if (widget.co2 < 900) {
      text = "pessima";
      style = const TextStyle(color: Colors.purple, fontSize: 60);
    } else {
      text = "pericolosa";
      style = const TextStyle(color: Colors.black, fontSize: 60);
    }
    return FittedBox(
      fit: BoxFit.fill,
      alignment: Alignment.topLeft,
      child: Text(text, style: style),
    );
  }
}
