import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:tic_tac_toe/model/message.dart';
import 'package:tic_tac_toe/util/constants.dart';

class Game extends StatefulWidget {
  const Game({Key? key}) : super(key: key);

  @override
  _GameState createState() => _GameState();
}

class WrapperCreator {

  final bool creator;
  final String nameGame;

  WrapperCreator(this.creator, this.nameGame);

}

class _GameState extends State<Game> {

  late bool minhaVez;
  WrapperCreator? creator;

  // 0 = branco. 1 = eu. 2 - adversário
  List<List<int>> cells = [
    [0, 0, 0],
    [0, 0, 0],
    [0, 0, 0]
  ];

  TextStyle textStyle75 = const TextStyle(
      fontSize: 75,
      color: Colors.white
  );

  TextStyle textStyle36 = const TextStyle(
      fontSize: 36,
      color: Colors.white
  );

  static const platform = MethodChannel('game/exchange');

  @override
  void initState() {
    super.initState();
    configurePubNub();
  }

  //nativo -> DART
  configurePubNub(){
    platform.setMethodCallHandler((call) {
      String argumentos = call.arguments.toString();
      List<String> parts = argumentos.split("|");
      ExchangeMessage message = ExchangeMessage(parts[0], int.parse(parts[1]), int.parse(parts[2]));

      if (message.user == (creator!.creator ? 'p2' : 'p1')) {
        setState(() {
          minhaVez = true;
          cells[message.x][message.y] = 2;
        });
        //checkWinner();
      }

      return Future.value(null);
    });
  }

    //DART -> nativo
  Future<bool> _sendAction(String action, Map<String, dynamic> arguments) async {
    try {
      final bool result = await platform.invokeMethod(action, arguments);
      return result;
    } on PlatformException catch (e) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    ScreenUtil.init(
        BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width,
            maxHeight: MediaQuery.of(context).size.height),
        context: context,
        designSize: const Size(700, 1400),
        minTextAdapt: true,
        orientation: Orientation.portrait);

    return Scaffold(
      body: SingleChildScrollView(
        child: Stack(
          children: [
            Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: ScreenUtil().setWidth(550),
                      height: ScreenUtil().setHeight(550),
                      color: colorBackBlue1,
                    ),
                    Container(
                      width: ScreenUtil().setWidth(150),
                      height: ScreenUtil().setHeight(550),
                      color: colorBackBlue2,
                    )
                  ],
                ),
                Container(
                  width: ScreenUtil().setWidth(700),
                  height: ScreenUtil().setHeight(850),
                  color: colorBackBlue3,
                )
              ],
            ),
            Container(
              height: ScreenUtil().setHeight(1400),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    creator == null ? Row(
                      children: [
                        buildButton("Criar", true),
                        SizedBox(width: 10),
                        buildButton("Entrar", false)
                      ],
                      mainAxisSize: MainAxisSize.min,
                    ) : Text(
                        minhaVez ? "Sua Vez!!" : "Aguarde Sua Vez!!!",
                        style: textStyle36
                    ),
                    GridView.count(
                      shrinkWrap: true,
                      padding: EdgeInsets.all(20),
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      crossAxisCount: 3,
                      children: <Widget>[
                        getCell(0, 0),
                        getCell(0, 1),
                        getCell(0, 2),
                        getCell(1, 0),
                        getCell(1, 1),
                        getCell(1, 2),
                        getCell(2, 0),
                        getCell(2, 1),
                        getCell(2, 2),
                      ],
                    ),
                  ],
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget buildButton(String label, bool owner) => Container(
    width: ScreenUtil().setWidth(300),
    child: OutlinedButton(
      onPressed: () {
        createGame(owner);
      },
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Text(
            label,
            style: textStyle36
        ),
      ),
    ),
  );

  Widget getCell(int x, int y) =>
      InkWell(
        child: Container(
          padding: EdgeInsets.all(8),
          child: Center(
              child: Text(
                  cells[x][y] == 0 ? " " : cells[x][y] == 1 ? "X" : "O",
                  style: textStyle75
              )
          ),
          color: Colors.lightBlueAccent,
        ),
        onTap: () async {
          if (minhaVez && cells[x][y] == 0) {
            _showSendingAcion();
            _sendAction('sendAction', {'tap': '${creator!.creator ? 'p1' : 'p2'}|$x|$y'}).then((value) {
              Navigator.of(context).pop();
              minhaVez = false;
              cells[x][y] = 1;

              setState(() {});

              //checkWinner();
            });
          }
        },

      );

  Future createGame(bool isCreator) async {
    TextEditingController editingController = TextEditingController();
    return showDialog(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Qual o nome do jogo?'),
          content: TextField(
            controller: editingController,
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Jogar'),
              onPressed: () {
                Navigator.of(context).pop();
                _sendAction('subscribe', {'channel': editingController.text}).then((value) {
                  setState(() {
                    creator = WrapperCreator(isCreator, editingController.text);
                    minhaVez = isCreator;
                  });
                });
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _showSendingAcion() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Enviando ação, aguarde...'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator()
            ],
          ),
        );
      },
    );
  }

}
