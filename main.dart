import 'package:flutter/material.dart';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sayı Tahmin Oyunu',
      theme: ThemeData(
        primarySwatch: Colors.orange,
        fontFamily: 'Inter',
      ),
      home: const NumberGuessingGame(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class UniqueDigitInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    String filtered = '';
    for (var char in newValue.text.split('')) {
      if (!filtered.contains(char)) filtered += char;
    }
    return TextEditingValue(
      text: filtered,
      selection: TextSelection.collapsed(offset: filtered.length),
    );
  }
}

class NumberGuessingGame extends StatefulWidget {
  const NumberGuessingGame({super.key});

  @override
  State<NumberGuessingGame> createState() => _NumberGuessingGameState();
}

class _NumberGuessingGameState extends State<NumberGuessingGame> {
  final TextEditingController _guessController = TextEditingController();
  final Random _random = Random();
  String _secretNumber = '';
  int _guessCount = 0;
  int _remainingGuesses = 10;
  final List<Map<String, dynamic>> _guessHistory = [];
  int _highScore = 0;
  int _difficulty = 4;
  bool _isGameOver = false;

  @override
  void initState() {
    super.initState();
    _loadHighScore();
    _startNewGame();
  }

  void _startNewGame() {
    setState(() {
      _guessController.clear();
      _guessCount = 0;
      _remainingGuesses = 10;
      _guessHistory.clear();
      _isGameOver = false;
      _secretNumber = _generateSecretNumber(_difficulty);
    });

    if (kDebugMode) {
      print('Gizli Sayı: $_secretNumber');
    }
  }

  String _generateSecretNumber(int length) {
    List<int> digits = [1,2,3,4,5,6,7,8,9];
    digits.shuffle(_random);
    String number = digits.sublist(0,1).join();
    if(length>1){
      List<int> remaining = [0,1,2,3,4,5,6,7,8,9]..removeWhere((d)=>d==int.parse(number));
      remaining.shuffle(_random);
      number += remaining.sublist(0,length-1).join();
    }
    return number;
  }

  Future<void> _loadHighScore() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _highScore = prefs.getInt('highScore') ?? 0;
    });
  }

  Future<void> _saveHighScore(int score) async {
    final prefs = await SharedPreferences.getInstance();
    if(score>_highScore){
      setState(()=>_highScore=score);
      prefs.setInt('highScore', score);
    }
  }

  void _checkGuess(){
    if(_isGameOver) return;
    String guess = _guessController.text.trim();
    if(guess.length!=_difficulty){
      _showResultDialog('Hata','Lütfen $_difficulty haneli bir sayı girin.');
      return;
    }
    if(guess[0]=='0'){
      _showResultDialog('Hata','Sayı 0 ile başlayamaz.');
      return;
    }
    if(guess.split('').toSet().length != guess.length){
      _showResultDialog('Hata','Aynı rakamı iki kez giremezsiniz.');
      return;
    }

    _guessCount++;
    _remainingGuesses--;
    _addGuessToHistory(guess);

    if(guess==_secretNumber){
      int score = 11-_guessCount;
      _saveHighScore(score);
      _showResultDialog('Tebrikler!','Sayıyı $_guessCount denemede bildiniz. Puanınız: $score');
      setState(()=>_isGameOver=true);
    }else if(_remainingGuesses==0){
      _showResultDialog('Kaybettin!','Gizli sayı $_secretNumber idi.');
      setState(()=>_isGameOver=true);
    }
    _guessController.clear();
  }

  void _addGuessToHistory(String guess){
    List<String> result = [];
    List<bool> secretUsed = List.filled(_difficulty,false);
    List<bool> guessUsed = List.filled(_difficulty,false);
    for(int i=0;i<_difficulty;i++){
      if(guess[i]==_secretNumber[i]){
        result.add('green');
        secretUsed[i]=true;
        guessUsed[i]=true;
      }else{
        result.add('gray');
      }
    }
    for(int i=0;i<_difficulty;i++){
      if(!guessUsed[i]) {
        for(int j=0;j<_difficulty;j++){
          if(!secretUsed[j] && guess[i]==_secretNumber[j]){
            result[i]='yellow';
            secretUsed[j]=true;
            break;
          }
        }
      }
    }
    setState(()=>_guessHistory.insert(0,{'guess':guess,'result':result}));
  }

  void _showResultDialog(String title,String content){
    showDialog(context: context,builder:(context){
      return AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(title,style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Text(content),
        actions:[
          TextButton(onPressed: (){
            Navigator.of(context).pop();
            if(_isGameOver) _startNewGame();
          }, child: const Text('Tamam'))
        ],
      );
    });
  }

  void _showStatisticsDialog(){
    showDialog(context: context,builder:(context){
      return AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('İstatistikler',style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text('En Yüksek Skorunuz: $_highScore puan'),
        actions:[
          TextButton(onPressed: ()=>Navigator.of(context).pop(), child: const Text('Kapat'))
        ],
      );
    });
  }

  void _showRulesDialog(){
    showDialog(context: context,builder:(context){
      return AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Oyun Kuralları',style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text(
            '• Gizli sayı seçilen hane sayısına sahiptir (3, 4 veya 5 hane).\n'
                '• Her rakam yalnızca bir kez kullanılabilir. Aynı rakam tekrar yazılamaz.\n'
                '• Sayı 0 ile başlayamaz.\n'
                '• Tahmin hakkınız sınırlıdır ve ekranın üst kısmında gösterilir.\n'
                '• Tahmin ettiğiniz sayı gizli sayı ile karşılaştırılır: Doğru yer yeşil, yanlış yer sarı, yanlış rakam gri.\n'
                '• Tahmin kutusuna aynı rakam bir kez girildiyse tekrar yazılamaz.'
        ),
        actions:[TextButton(onPressed: ()=>Navigator.of(context).pop(), child: const Text('Kapat'))],
      );
    });
  }

  @override
  Widget build(BuildContext context){
    double screenWidth = MediaQuery.of(context).size.width;
    double guessFieldWidth = min(50.0*_difficulty,screenWidth*0.6);
    double fieldHeight = 60;

    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        backgroundColor: Colors.orange,
        iconTheme: const IconThemeData(color: Colors.white),
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: ()=>Scaffold.of(context).openDrawer(),
          ),
        ),
        actions: [
          IconButton(icon: const Icon(Icons.leaderboard),onPressed: _showStatisticsDialog)
        ],
      ),
      drawer: Drawer(
        child: Column(
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Colors.orange),
              child: Text('Oyun Ayarları',style: TextStyle(color: Colors.white,fontSize: 24)),
            ),
            ListTile(
              title: const Text('Hane Sayısı'),
              trailing: DropdownButton<int>(
                value: _difficulty,
                onChanged: (int? newValue){
                  if(newValue!=null){
                    setState(()=>_difficulty=newValue);
                    _startNewGame();
                    Navigator.pop(context);
                  }
                },
                items: const [
                  DropdownMenuItem(value:3,child: Text('3 Hane')),
                  DropdownMenuItem(value:4,child: Text('4 Hane')),
                  DropdownMenuItem(value:5,child: Text('5 Hane')),
                ],
              ),
            ),
            ListTile(
              title: const Text('Yeni Oyun Başlat'),
              onTap: (){
                _startNewGame();
                Navigator.pop(context);
              },
            ),
            const Divider(),
            ListTile(
              title: const Text('Oyun Kuralları'),
              onTap: ()=>_showRulesDialog(),
            ),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children:[
            // Logo ana ekran üstünde
            Center(
              child: Image.asset(
                'assets/logo.png',
                width: screenWidth * 0.2, // ekranın yarısı
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(vertical:20),
              child: Text(
                  'Kalan Hak: $_remainingGuesses',
                  style: const TextStyle(fontSize:24,fontWeight: FontWeight.bold,color: Colors.white)
              ),
            ),
            Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children:[
                  SizedBox(
                    width: guessFieldWidth*1.5,
                    height: fieldHeight,
                    child: TextFormField(
                      controller: _guessController,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white,fontWeight: FontWeight.bold,fontSize:24),
                      inputFormatters:[
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(_difficulty),
                        UniqueDigitInputFormatter(),
                      ],
                      enabled: !_isGameOver,
                      decoration: InputDecoration(
                        hintText: '$_difficulty haneli sayı',
                        hintStyle: TextStyle(color: Colors.grey[400]),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Colors.grey),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Colors.orange,width:2),
                        ),
                        filled: true,
                        fillColor: Colors.grey[800],
                      ),
                    ),
                  ),
                  const SizedBox(width:10),
                  SizedBox(
                    width: fieldHeight,
                    height: fieldHeight,
                    child: ElevatedButton(
                      onPressed: _isGameOver ? null : _checkGuess,
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                        elevation: 5,
                      ),
                      child: const Center(child: Icon(Icons.send,size:36)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height:20),
            Expanded(
              child: ListView.builder(
                itemCount: _guessHistory.length,
                itemBuilder: (context,index){
                  final guessData = _guessHistory[index];
                  final guess = guessData['guess'] as String;
                  final result = guessData['result'] as List<String>;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical:4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(guess.length,(i){
                        Color color;
                        switch(result[i]){
                          case 'green': color=Colors.green; break;
                          case 'yellow': color=Colors.yellow; break;
                          default: color=Colors.grey; break;
                        }
                        return Container(
                          width:40,
                          height:40,
                          margin: const EdgeInsets.symmetric(horizontal:4),
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Text(
                              guess[i],
                              style: const TextStyle(fontSize:24,fontWeight: FontWeight.bold,color: Colors.white),
                            ),
                          ),
                        );
                      }),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
