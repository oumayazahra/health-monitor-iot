import 'package:flutter/material.dart';
import 'dart:math';

class HeartRateChart extends StatefulWidget {
  final List<double> initialData;
  
  const HeartRateChart({super.key, required this.initialData});

  @override
  State<HeartRateChart> createState() => _HeartRateChartState();
}

class _HeartRateChartState extends State<HeartRateChart> 
    with SingleTickerProviderStateMixin {
  
  late List<double> _currentData;
  late AnimationController _animationController;
  late Animation<double> _animation;
  
  @override
  void initState() {
    super.initState();
    _currentData = List.from(widget.initialData);
    
    // Animation pour faire défiler le graphique
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
    
    _animation = Tween<double>(begin: 0, end: 1).animate(_animationController)
      ..addListener(() {
        // Mettre à jour l'affichage à chaque frame d'animation
        setState(() {});
      });
  }

  // Méthode pour ajouter de nouvelles données
  void addDataPoint(double newValue) {
    setState(() {
      _currentData.add(newValue);
      
      // Garder seulement les 20 dernières valeurs
      if (_currentData.length > 20) {
        _currentData.removeAt(0);
      }
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
      size: Size(double.infinity, double.infinity),
      painter: _DynamicHeartRateChartPainter(
        data: _currentData,
        animationValue: _animation.value,
      ),
    );
  }
}

class _DynamicHeartRateChartPainter extends CustomPainter {
  final List<double> data;
  final double animationValue;
  
  _DynamicHeartRateChartPainter({
    required this.data,
    required this.animationValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;
    
    // Effet de défilement
    double scrollOffset = size.width * animationValue * 0.1;
    
    // Créer un gradient pour la ligne
    final gradient = LinearGradient(
      colors: [Colors.red, Colors.orange],
    ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    
    Paint linePaint = Paint()
      ..shader = gradient
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    
    Paint dotPaint = Paint()
      ..color = Colors.red
      ..style = PaintingStyle.fill;
    
    Paint fillPaint = Paint()
      ..color = Colors.red.withOpacity(0.15)
      ..style = PaintingStyle.fill;
    
    // Calculer les valeurs min/max avec une marge
    double maxValue = data.reduce(max);
    double minValue = data.reduce(min);
    
    // Ajouter une marge pour la visibilité
    double range = maxValue - minValue;
    maxValue += range * 0.1;
    minValue -= range * 0.1;
    
    // Éviter division par zéro
    if (maxValue == minValue) {
      maxValue += 1;
      minValue -= 1;
    }
    
    // Fonction de normalisation
    double normalize(double value) {
      return size.height - ((value - minValue) / (maxValue - minValue)) * size.height;
    }
    
    // Calculer l'espacement avec défilement
    double spacing = size.width / (data.length - 1);
    
    // Créer le chemin de la ligne
    Path linePath = Path();
    Path fillPath = Path();
    
    for (int i = 0; i < data.length; i++) {
      double x = i * spacing - scrollOffset;
      double y = normalize(data[i]);
      
      // Ajuster la position x pour qu'elle reste visible
      if (x < -50) continue; // Ignorer les points trop à gauche
      if (x > size.width + 50) break; // Arrêter si trop à droite
      
      if (i == 0) {
        linePath.moveTo(x, y);
        fillPath.moveTo(x, size.height);
        fillPath.lineTo(x, y);
      } else {
        linePath.lineTo(x, y);
        fillPath.lineTo(x, y);
      }
      
      // Dessiner les points seulement sur les pics
      if (i == data.length - 1 || i % 3 == 0) {
        canvas.drawCircle(Offset(x, y), 3, dotPaint);
      }
    }
    
    // Compléter le remplissage
    if (data.length > 1) {
      double lastX = (data.length - 1) * spacing - scrollOffset;
      fillPath.lineTo(lastX, size.height);
      fillPath.close();
      
      // Dessiner le remplissage d'abord
      canvas.drawPath(fillPath, fillPaint);
    }
    
    // Dessiner la ligne par-dessus
    canvas.drawPath(linePath, linePaint);
    
    // Dessiner la dernière valeur
    if (data.isNotEmpty) {
      double lastX = (data.length - 1) * spacing - scrollOffset;
      double lastY = normalize(data.last);
      
      // Cercle plus grand sur la dernière valeur
      canvas.drawCircle(
        Offset(lastX, lastY), 
        5, 
        dotPaint..color = Colors.red
      );
      
      // Texte de la dernière valeur
      TextSpan span = TextSpan(
        style: const TextStyle(color: Colors.red, fontSize: 12),
        text: '${data.last.round()}',
      );
      TextPainter tp = TextPainter(
        text: span,
        textDirection: TextDirection.ltr,
      );
      tp.layout();
      tp.paint(canvas, Offset(lastX - 10, lastY - 20));
    }
    
    // Ajouter une grille
    Paint gridPaint = Paint()
      ..color = Colors.grey.withOpacity(0.3)
      ..strokeWidth = 0.5;
    
    // Lignes horizontales
    for (int i = 1; i <= 4; i++) {
      double y = size.height * i / 5;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
    
    // Lignes verticales (temps)
    for (int i = 1; i <= 5; i++) {
      double x = size.width * i / 6;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _DynamicHeartRateChartPainter oldDelegate) {
    return oldDelegate.data != data || 
           oldDelegate.animationValue != animationValue;
  }
}