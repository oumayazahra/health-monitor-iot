import 'package:flutter/material.dart';
import 'dart:math';

class EcgChart extends StatefulWidget {
  final List<double> ecgData;

  const EcgChart({super.key, required this.ecgData});

  @override
  State<EcgChart> createState() => _EcgChartState();
}

class _EcgChartState extends State<EcgChart>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;
  late List<double> _currentData;

  @override
  void initState() {
    super.initState();
    _currentData = List.from(widget.ecgData);

    // Animation pour le défilement et les effets
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();

    _animation = Tween<double>(begin: 0, end: 1).animate(_animationController)
      ..addListener(() {
        setState(() {});
      });
  }

  // Méthode pour mettre à jour les données
  void updateEcgData(List<double> newData) {
    setState(() {
      _currentData = List.from(newData);
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(double.infinity, double.infinity),
      painter: _DynamicEcgPainter(
        values: _currentData,
        animationValue: _animation.value,
      ),
    );
  }
}

class _DynamicEcgPainter extends CustomPainter {
  final List<double> values;
  final double animationValue;

  _DynamicEcgPainter({required this.values, required this.animationValue});

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;

    // Effet de défilement
    double scrollOffset = size.width * animationValue * 0.2;

    // Créer un gradient pour la ligne ECG
    final gradient = LinearGradient(
      colors: [Colors.green, Colors.lightGreen, Colors.green],
      stops: [0.0, 0.5, 1.0],
    ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    // Peinture pour la ligne principale
    Paint linePaint = Paint()
      ..shader = gradient
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Peinture pour le remplissage
    Paint fillPaint = Paint()
      ..color = Colors.green.withOpacity(0.1)
      ..style = PaintingStyle.fill;

    // Peinture pour les pics R
    Paint peakPaint = Paint()
      ..color = Colors.red
      ..style = PaintingStyle.fill;

    // Calculer l'espacement
    double spacing = size.width / (values.length - 1);

    // Centre pour ajustement
    double centerY = size.height / 2;

    // Normaliser les données pour une meilleure visualisation
    if (values.isNotEmpty) {
      double maxVal = values.reduce(max);
      double minVal = values.reduce(min);
      double range = maxVal - minVal;

      // Éviter division par zéro
      if (range == 0) range = 1;

      // Créer les chemins
      Path linePath = Path();
      Path fillPath = Path();

      List<Offset> peakPositions = [];

      for (int i = 0; i < values.length; i++) {
        double x = i * spacing - scrollOffset;

        // Normaliser la valeur entre -1 et 1 pour un affichage cohérent
        double normalizedValue = (values[i] - minVal) / range * 2 - 1;

        // Appliquer un facteur d'amplitude dynamique
        double amplitude = 25 + 5 * sin(animationValue * 2 * pi);
        double y = centerY - (normalizedValue * amplitude);

        // Ajuster la position x pour qu'elle reste visible
        if (x < -100) continue; // Ignorer les points trop à gauche
        if (x > size.width + 100) break; // Arrêter si trop à droite

        if (i == 0) {
          linePath.moveTo(x, y);
          fillPath.moveTo(x, size.height);
          fillPath.lineTo(x, y);
        } else {
          linePath.lineTo(x, y);
          fillPath.lineTo(x, y);

          // Détecter les pics (ondes R)
          if (i > 1 && i < values.length - 1) {
            if (values[i] > values[i - 1] &&
                values[i] > values[i + 1] &&
                values[i] > (maxVal * 0.7)) {
              peakPositions.add(Offset(x, y));
            }
          }
        }
      }

      // Compléter le chemin de remplissage
      if (values.length > 1) {
        double lastX = (values.length - 1) * spacing - scrollOffset;
        if (lastX < size.width + 100) {
          fillPath.lineTo(lastX, size.height);
          fillPath.close();

          // Dessiner le remplissage d'abord
          canvas.drawPath(fillPath, fillPaint);
        }
      }

      // Dessiner la ligne ECG
      canvas.drawPath(linePath, linePaint);

      // Dessiner les pics R
      for (final peak in peakPositions) {
        // Effet de pulsation sur les pics
        double pulseSize = 3 + sin(animationValue * 4 * pi + peak.dx * 0.1) * 2;

        // Cercle intérieur rouge
        canvas.drawCircle(peak, pulseSize, peakPaint);

        // Anneau externe avec effet de propagation
        Paint ringPaint = Paint()
          ..color = Colors.red.withOpacity(0.3)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1;

        double ringSize = pulseSize + 2 + sin(animationValue * 6 * pi) * 3;
        canvas.drawCircle(peak, ringSize, ringPaint);
      }

      // Ajouter une ligne de base (isoelectrique)
      Paint baselinePaint = Paint()
        ..color = Colors.grey.withOpacity(0.3)
        ..strokeWidth = 0.5;

      canvas.drawLine(
        Offset(0, centerY),
        Offset(size.width, centerY),
        baselinePaint,
      );

      // Ajouter une grille discrète
      Paint gridPaint = Paint()
        ..color = Colors.grey.withOpacity(0.15)
        ..strokeWidth = 0.3;

      // Lignes horizontales
      for (int i = 1; i <= 4; i++) {
        double y = size.height * i / 5;
        canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
      }

      // Lignes verticales (temps)
      for (int i = 1; i <= 10; i++) {
        double x = size.width * i / 11;
        canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
      }

      // Ajouter un indicateur de défilement
      if (scrollOffset > 0) {
        Paint indicatorPaint = Paint()
          ..color = Colors.blue.withOpacity(0.5)
          ..style = PaintingStyle.fill;

        double indicatorWidth = 3;
        double indicatorHeight = size.height * 0.3;
        double indicatorY = centerY - indicatorHeight / 2;

        canvas.drawRect(
          Rect.fromLTWH(
            size.width - indicatorWidth,
            indicatorY,
            indicatorWidth,
            indicatorHeight,
          ),
          indicatorPaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DynamicEcgPainter oldDelegate) {
    return oldDelegate.values != values ||
        oldDelegate.animationValue != animationValue;
  }
}
