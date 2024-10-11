import 'dart:io';
import 'dart:math';
import 'dart:async';

class Point {
  int x, y;
  Point(this.x, this.y);
}

class Cicak {
  List<Point> body;
  String direction;
  int bodyLength;
  
  Cicak(Point start) : body = [start], direction = 'right', bodyLength = 1;

  void move(Point food) {
    Point head = body.first;
    Point newHead;
    
    if (head.y != food.y) {
      newHead = Point(head.x, head.y + (food.y > head.y ? 1 : -1));
      direction = food.y > head.y ? 'down' : 'up';
    } else if (head.x != food.x) {
      newHead = Point(head.x + (food.x > head.x ? 1 : -1), head.y);
      direction = food.x > head.x ? 'right' : 'left';
    } else {
      newHead = Point(head.x, head.y);
    }
    
    body.insert(0, newHead);
    if (body.length > bodyLength) {
      body.removeLast();
    }
  }

  List<String> getShape() {
    if (direction == 'up' || direction == 'down') {
      return [
        '  *  ',
        '*****',
        '  *  ',
        ...List.filled(bodyLength - 1, '  *  '),
        '*****',
        '  *  '
      ];
    } else {
      String middleRow = '*${'*' * (bodyLength + 2)}*';
      return [
        ' *${''.padRight(bodyLength)}* ',
        middleRow,
        ' *${''.padRight(bodyLength)}* '
      ];
    }
  }

  void grow() {
    bodyLength++;
  }
}

class Game {
  late int width, height;
  late Cicak cicak;
  late Point food;
  final Random random = Random();
  List<List<String>> buffer = [];

  Game() {
    updateSize();
    cicak = Cicak(Point(width ~/ 2, height ~/ 2));
    generateFood();
  }

  void updateSize() {
    if (stdout.hasTerminal) {
      width = stdout.terminalColumns - 1;
      height = stdout.terminalLines - 1;
    } else {
      width = 80;
      height = 24;
    }
    buffer = List.generate(height, (_) => List.filled(width, ' '));
  }

  void generateFood() {
    do {
      food = Point(random.nextInt(width - 2) + 1, random.nextInt(height - 2) + 1);
    } while (cicak.body.any((segment) => segment.x == food.x && segment.y == food.y));
  }

  void update() {
    cicak.move(food);
    if (cicak.body.last.x == food.x && cicak.body.last.y == food.y) {
      cicak.grow();
      generateFood();
    }
    
    for (var segment in cicak.body) {
      segment.x = (segment.x + width) % width;
      segment.y = (segment.y + height) % height;
    }

    Point head = cicak.body.last;
    if (head.x == 0 || head.x == width - 1) {
      if (cicak.direction == 'left') {
        cicak.direction = 'right';
      } else if (cicak.direction == 'right') {
        cicak.direction = 'left';
      }
    } else if (head.y == 0 || head.y == height - 1) {
      if (cicak.direction == 'up') {
        cicak.direction = 'down';
      } else if (cicak.direction == 'down') {
        cicak.direction = 'up';
      }
    }
  }

  void render() {
    // Clear buffer
    for (var row in buffer) {
      row.fillRange(0, width, ' ');
    }
    
    // Draw food
    buffer[food.y][food.x] = '@';
    
    // Draw cicak
    List<String> cicakShape = cicak.getShape();
    Point head = cicak.body.last;
    int offsetX = cicak.direction == 'left' || cicak.direction == 'right' ? cicakShape[0].length ~/ 2 : 2;
    int offsetY = cicak.direction == 'up' || cicak.direction == 'down' ? cicakShape.length ~/ 2 : 1;
    
    for (int dy = 0; dy < cicakShape.length; dy++) {
      for (int dx = 0; dx < cicakShape[dy].length; dx++) {
        int x = (head.x + dx - offsetX + width) % width;
        int y = (head.y + dy - offsetY + height) % height;
        if (cicakShape[dy][dx] != ' ') {
          buffer[y][x] = cicakShape[dy][dx];
        }
      }
    }
    
    // Render buffer
    stdout.write('\x1B[H'); 
    for (var row in buffer) {
      stdout.writeln(row.join());
    }
    
    stdout.write('Size: ${width}x$height | Score: ${cicak.bodyLength - 1} | Direction: ${cicak.direction}');
    stdout.flush();
  }
}

void main() async {
  Game game = Game();
  
  Duration frameDuration = Duration(milliseconds: 100);
  Stopwatch stopwatch = Stopwatch()..start();
  
  while (true) {
    game.update();
    game.render();
    
    int elapsedMilliseconds = stopwatch.elapsedMilliseconds;
    int remainingMilliseconds = frameDuration.inMilliseconds - elapsedMilliseconds;
    
    if (remainingMilliseconds > 0) {
      await Future.delayed(Duration(milliseconds: remainingMilliseconds));
    }
    
    stopwatch.reset();
  }
}
