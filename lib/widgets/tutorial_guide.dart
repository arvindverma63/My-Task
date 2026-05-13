import 'package:flutter/material.dart';

class TutorialStep {
  final String title;
  final String message;
  final Alignment alignment;
  final IconData icon;

  const TutorialStep({
    required this.title,
    required this.message,
    required this.alignment,
    required this.icon,
  });
}

class TutorialOverlay extends StatefulWidget {
  final List<TutorialStep> steps;
  final VoidCallback onFinish;

  const TutorialOverlay({
    super.key,
    required this.steps,
    required this.onFinish,
  });

  @override
  State<TutorialOverlay> createState() => _TutorialOverlayState();
}

class _TutorialOverlayState extends State<TutorialOverlay> {
  int _currentStep = 0;

  void _next() {
    setState(() {
      if (_currentStep < widget.steps.length - 1) {
        _currentStep++;
      } else {
        widget.onFinish();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final step = widget.steps[_currentStep];
    final theme = Theme.of(context);

    return Material(
      color: Colors.black54,
      child: InkWell(
        onTap: _next,
        child: Stack(
          children: [
            Align(
              alignment: step.alignment,
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: step.alignment == Alignment.bottomCenter 
                      ? CrossAxisAlignment.center 
                      : CrossAxisAlignment.start,
                  children: [
                    if (step.alignment == Alignment.topRight || step.alignment == Alignment.topCenter)
                      _Pointer(up: true, alignment: step.alignment),
                    
                    Container(
                      constraints: const BoxConstraints(maxWidth: 300),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E1E1E),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha(50),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(step.icon, color: theme.colorScheme.primary, size: 20),
                              const SizedBox(width: 10),
                              Text(
                                '${_currentStep + 1}/${widget.steps.length}',
                                style: TextStyle(
                                  color: Colors.white.withAlpha(150),
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            step.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            step.message,
                            style: TextStyle(
                              color: Colors.white.withAlpha(200),
                              fontSize: 14,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: List.generate(
                                  widget.steps.length,
                                  (index) => Container(
                                    width: _currentStep == index ? 16 : 6,
                                    height: 6,
                                    margin: const EdgeInsets.only(right: 4),
                                    decoration: BoxDecoration(
                                      color: _currentStep == index 
                                          ? theme.colorScheme.primary 
                                          : Colors.white24,
                                      borderRadius: BorderRadius.circular(3),
                                    ),
                                  ),
                                ),
                              ),
                              Icon(
                                _currentStep == widget.steps.length - 1 
                                    ? Icons.check_circle_rounded 
                                    : Icons.arrow_forward_rounded,
                                color: theme.colorScheme.primary,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    
                    if (step.alignment == Alignment.bottomCenter || step.alignment == Alignment.bottomRight)
                      _Pointer(up: false, alignment: step.alignment),
                  ],
                ),
              ),
            ),
            Positioned(
              top: 40,
              right: 20,
              child: TextButton(
                onPressed: widget.onFinish,
                child: const Text('Skip tour', style: TextStyle(color: Colors.white70)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Pointer extends StatelessWidget {
  final bool up;
  final Alignment alignment;

  const _Pointer({required this.up, required this.alignment});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: alignment == Alignment.topRight || alignment == Alignment.bottomRight ? 240 : 0,
        right: alignment == Alignment.topLeft || alignment == Alignment.bottomLeft ? 240 : 0,
      ),
      child: CustomPaint(
        size: const Size(20, 10),
        painter: _TrianglePainter(up: up),
      ),
    );
  }
}

class _TrianglePainter extends CustomPainter {
  final bool up;

  _TrianglePainter({required this.up});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0xFF1E1E1E);
    final path = Path();
    if (up) {
      path.moveTo(size.width / 2, 0);
      path.lineTo(0, size.height);
      path.lineTo(size.width, size.height);
    } else {
      path.moveTo(0, 0);
      path.lineTo(size.width, 0);
      path.lineTo(size.width / 2, size.height);
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
