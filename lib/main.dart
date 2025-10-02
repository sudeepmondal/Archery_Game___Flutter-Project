import 'package:flutter/material.dart';
import 'dart:math';
import 'dart:async';

void main() {
  runApp(const ArcheryGameApp());
}

class ArcheryGameApp extends StatelessWidget {
  const ArcheryGameApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Archery Game',
      theme: ThemeData(
        primarySwatch: Colors.brown,
        fontFamily: 'Arial',
      ),
      home: const MainMenu(),
      debugShowCheckedModeBanner: false,
    );
  }
}

// Main Menu Screen
class MainMenu extends StatelessWidget {
  const MainMenu({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue.shade300, Colors.green.shade200],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Game Title
              Text(
                '🏹 ARCHERY GAME',
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  shadows: [
                    Shadow(
                      blurRadius: 10,
                      color: Colors.black.withOpacity(0.5),
                      offset: const Offset(3, 3),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 50),

              // Play Button
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const GameScreen()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 20),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: const Text(
                  'PLAY',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 20),

              // Instructions
              Container(
                margin: const EdgeInsets.all(20),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Column(
                  children: const [
                    Text(
                      'HOW TO PLAY',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.brown,
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      '1. Drag on the screen to aim\n'
                          '2. Release to shoot the arrow\n'
                          '3. Hit the bullseye for maximum points\n'
                          '4. Get 10 arrows per game',
                      style: TextStyle(fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Game Screen
class GameScreen extends StatefulWidget {
  const GameScreen({Key? key}) : super(key: key);

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with TickerProviderStateMixin {
  // Game State
  int score = 0;
  int arrowsLeft = 10;
  bool isAiming = false;
  bool isArrowFlying = false;
  bool gameOver = false;

  // Arrow Properties
  Offset? aimStart;
  Offset? aimCurrent;
  Offset arrowPosition = const Offset(200, 500);
  double arrowRotation = 0;
  List<Offset> arrowTrail = [];

  // Target Properties
  Offset targetPosition = const Offset(200, 150);
  double targetVelocity = 1.0;
  bool targetMovingRight = true;

  // Animation
  Timer? gameTimer;
  AnimationController? hitAnimationController;
  Animation<double>? hitAnimation;

  // Score popup
  String? scorePopup;
  Offset? scorePopupPosition;

  @override
  void initState() {
    super.initState();
    startGameLoop();

    // Hit animation setup
    hitAnimationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    hitAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: hitAnimationController!, curve: Curves.easeOut),
    );
  }

  void startGameLoop() {
    gameTimer = Timer.periodic(const Duration(milliseconds: 16), (timer) {
      if (!gameOver) {
        updateGame();
      }
    });
  }

  void updateGame() {
    setState(() {
      // Move target
      if (targetMovingRight) {
        targetPosition = Offset(targetPosition.dx + targetVelocity, targetPosition.dy);
        if (targetPosition.dx > MediaQuery.of(context).size.width - 80) {
          targetMovingRight = false;
        }
      } else {
        targetPosition = Offset(targetPosition.dx - targetVelocity, targetPosition.dy);
        if (targetPosition.dx < 80) {
          targetMovingRight = true;
        }
      }

      // Update arrow flight
      if (isArrowFlying) {
        updateArrowFlight();
      }
    });
  }

  void updateArrowFlight() {
    // Simple physics simulation
    double gravity = 0.3;
    double velocityX = (aimStart!.dx - aimCurrent!.dx) * 0.2;
    double velocityY = (aimStart!.dy - aimCurrent!.dy) * 0.2;

    arrowPosition = Offset(
      arrowPosition.dx + velocityX,
      arrowPosition.dy + velocityY + gravity,
    );

    arrowTrail.add(arrowPosition);
    if (arrowTrail.length > 15) {
      arrowTrail.removeAt(0);
    }

    // Calculate rotation based on velocity
    arrowRotation = atan2(velocityY + gravity, velocityX);

    // Check collision with target
    double distance = sqrt(
      pow(arrowPosition.dx - targetPosition.dx, 2) +
          pow(arrowPosition.dy - targetPosition.dy, 2),
    );

    if (distance < 60) {
      hitTarget(distance);
      return;
    }

    // Check if arrow is off screen
    if (arrowPosition.dy < -50 ||
        arrowPosition.dy > MediaQuery.of(context).size.height ||
        arrowPosition.dx < -50 ||
        arrowPosition.dx > MediaQuery.of(context).size.width + 50) {
      missedShot();
    }
  }

  void hitTarget(double distance) {
    int points = 0;
    if (distance < 15) {
      points = 10; // Bullseye
      scorePopup = 'BULLSEYE! +10';
    } else if (distance < 30) {
      points = 8;
      scorePopup = 'GREAT! +8';
    } else if (distance < 45) {
      points = 5;
      scorePopup = 'GOOD! +5';
    } else {
      points = 3;
      scorePopup = 'HIT! +3';
    }

    setState(() {
      score += points;
      scorePopupPosition = arrowPosition;
      isArrowFlying = false;
      arrowTrail.clear();

      // Increase difficulty
      if (score % 50 == 0) {
        targetVelocity += 0.5;
      }
    });

    hitAnimationController?.forward(from: 0);

    // Clear popup after delay
    Future.delayed(const Duration(milliseconds: 1000), () {
      if (mounted) {
        setState(() {
          scorePopup = null;
        });
      }
    });

    resetArrow();
  }

  void missedShot() {
    setState(() {
      isArrowFlying = false;
      arrowTrail.clear();
      scorePopup = 'MISS!';
      scorePopupPosition = arrowPosition;
    });

    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) {
        setState(() {
          scorePopup = null;
        });
      }
    });

    resetArrow();
  }

  void resetArrow() {
    arrowsLeft--;
    if (arrowsLeft <= 0) {
      endGame();
    } else {
      arrowPosition = Offset(MediaQuery.of(context).size.width / 2,
          MediaQuery.of(context).size.height - 150);
      arrowRotation = -pi / 2;
    }
  }

  void endGame() {
    setState(() {
      gameOver = true;
    });
    gameTimer?.cancel();
  }

  @override
  void dispose() {
    gameTimer?.cancel();
    hitAnimationController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        onPanStart: (details) {
          if (!isArrowFlying && !gameOver && arrowsLeft > 0) {
            setState(() {
              isAiming = true;
              aimStart = details.localPosition;
              aimCurrent = details.localPosition;
            });
          }
        },
        onPanUpdate: (details) {
          if (isAiming && !gameOver) {
            setState(() {
              aimCurrent = details.localPosition;
            });
          }
        },
        onPanEnd: (details) {
          if (isAiming && !gameOver) {
            setState(() {
              isAiming = false;
              isArrowFlying = true;
            });
          }
        },
        child: Stack(
          children: [
            // Background
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.blue.shade200, Colors.green.shade100],
                ),
              ),
            ),

            // Target
            Positioned(
              left: targetPosition.dx - 50,
              top: targetPosition.dy - 50,
              child: CustomPaint(
                size: const Size(100, 100),
                painter: TargetPainter(),
              ),
            ),

            // Arrow trail
            if (arrowTrail.isNotEmpty)
              ...arrowTrail.asMap().entries.map((entry) {
                double opacity = (entry.key / arrowTrail.length) * 0.5;
                return Positioned(
                  left: entry.value.dx - 2,
                  top: entry.value.dy - 2,
                  child: Container(
                    width: 4,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.brown.withOpacity(opacity),
                      shape: BoxShape.circle,
                    ),
                  ),
                );
              }).toList(),

            // Arrow
            if (!gameOver)
              Positioned(
                left: arrowPosition.dx - 30,
                top: arrowPosition.dy - 5,
                child: Transform.rotate(
                  angle: arrowRotation,
                  child: CustomPaint(
                    size: const Size(60, 10),
                    painter: ArrowPainter(),
                  ),
                ),
              ),

            // Aim line
            if (isAiming && aimStart != null && aimCurrent != null)
              CustomPaint(
                size: MediaQuery.of(context).size,
                painter: AimLinePainter(aimStart!, aimCurrent!),
              ),

            // Score popup
            if (scorePopup != null && scorePopupPosition != null)
              AnimatedBuilder(
                animation: hitAnimation!,
                builder: (context, child) {
                  return Positioned(
                    left: scorePopupPosition!.dx - 50,
                    top: scorePopupPosition!.dy - 60 - (30 * (1 - hitAnimation!.value)),
                    child: Opacity(
                      opacity: hitAnimation!.value,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Text(
                          scorePopup!,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),

            // HUD
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Score
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'Score: $score',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),

                        // Arrows left
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            children: [
                              const Text(
                                '🏹 ',
                                style: TextStyle(fontSize: 20),
                              ),
                              Text(
                                '$arrowsLeft',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Game Over Screen
            if (gameOver)
              Container(
                color: Colors.black.withOpacity(0.7),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.all(30),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'GAME OVER',
                          style: TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'Final Score: $score',
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 30),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ElevatedButton(
                              onPressed: () {
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const GameScreen(),
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 30,
                                  vertical: 15,
                                ),
                              ),
                              child: const Text(
                                'PLAY AGAIN',
                                style: TextStyle(fontSize: 18),
                              ),
                            ),
                            const SizedBox(width: 15),
                            ElevatedButton(
                              onPressed: () {
                                Navigator.pop(context);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.grey,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 30,
                                  vertical: 15,
                                ),
                              ),
                              child: const Text(
                                'MENU',
                                style: TextStyle(fontSize: 18),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// Custom Painters
class TargetPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    // Outer ring (white)
    paint.color = Colors.white;
    canvas.drawCircle(Offset(size.width / 2, size.height / 2), 50, paint);

    // Black ring
    paint.color = Colors.black;
    canvas.drawCircle(Offset(size.width / 2, size.height / 2), 40, paint);

    // Blue ring
    paint.color = Colors.blue;
    canvas.drawCircle(Offset(size.width / 2, size.height / 2), 30, paint);

    // Red ring
    paint.color = Colors.red;
    canvas.drawCircle(Offset(size.width / 2, size.height / 2), 20, paint);

    // Yellow center (bullseye)
    paint.color = Colors.yellow;
    canvas.drawCircle(Offset(size.width / 2, size.height / 2), 10, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class ArrowPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.brown
      ..style = PaintingStyle.fill;

    // Arrow shaft
    canvas.drawRect(
      Rect.fromLTWH(0, size.height / 2 - 2, size.width - 10, 4),
      paint,
    );

    // Arrow head
    final arrowHead = Path();
    arrowHead.moveTo(size.width - 10, size.height / 2);
    arrowHead.lineTo(size.width, size.height / 2);
    arrowHead.lineTo(size.width - 5, size.height / 2 - 5);
    arrowHead.close();

    paint.color = Colors.grey.shade700;
    canvas.drawPath(arrowHead, paint);

    final arrowHead2 = Path();
    arrowHead2.moveTo(size.width - 10, size.height / 2);
    arrowHead2.lineTo(size.width, size.height / 2);
    arrowHead2.lineTo(size.width - 5, size.height / 2 + 5);
    arrowHead2.close();

    canvas.drawPath(arrowHead2, paint);

    // Fletching
    paint.color = Colors.red;
    canvas.drawRect(
      Rect.fromLTWH(5, size.height / 2 - 3, 8, 6),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class AimLinePainter extends CustomPainter {
  final Offset start;
  final Offset end;

  AimLinePainter(this.start, this.end);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.7)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    // Draw dashed line
    const dashWidth = 10;
    const dashSpace = 5;
    double distance = sqrt(pow(end.dx - start.dx, 2) + pow(end.dy - start.dy, 2));
    double angle = atan2(end.dy - start.dy, end.dx - start.dx);

    double currentDistance = 0;
    while (currentDistance < distance) {
      double x1 = start.dx + currentDistance * cos(angle);
      double y1 = start.dy + currentDistance * sin(angle);
      double x2 = start.dx + min(currentDistance + dashWidth, distance) * cos(angle);
      double y2 = start.dy + min(currentDistance + dashWidth, distance) * sin(angle);

      canvas.drawLine(Offset(x1, y1), Offset(x2, y2), paint);
      currentDistance += dashWidth + dashSpace;
    }

    // Draw power indicator
    paint.style = PaintingStyle.fill;
    paint.color = Colors.orange;
    canvas.drawCircle(end, 15, paint);

    paint.color = Colors.white;
    canvas.drawCircle(end, 10, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}