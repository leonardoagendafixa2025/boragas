import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../models/tracking_models.dart';

/// Marcador vetorial personalizado de alta definição para a frota BoraGás.
/// Renderiza a motocicleta com suporte a botijões de gás, aura de deslocamento
/// e rotação precisa baseada no azimute (bearing).
class BoraGasVehicleMarker extends StatelessWidget {
  final double bearing;
  final VehicleType vehicleType;
  final double size;
  final bool isMoving;
  final double speedKmh;

  const BoraGasVehicleMarker({
    super.key,
    required this.bearing,
    this.vehicleType = VehicleType.motorcycleWithGasRack,
    this.size = 56.0,
    this.isMoving = false,
    this.speedKmh = 0.0,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Transform.rotate(
        angle: bearing * (math.pi / 180.0),
        child: CustomPaint(
          size: Size(size, size),
          painter: _VehicleCustomPainter(
            vehicleType: vehicleType,
            isMoving: isMoving,
            speedKmh: speedKmh,
          ),
        ),
      ),
    );
  }
}

class _VehicleCustomPainter extends CustomPainter {
  final VehicleType vehicleType;
  final bool isMoving;
  final double speedKmh;

  _VehicleCustomPainter({
    required this.vehicleType,
    required this.isMoving,
    required this.speedKmh,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    switch (vehicleType) {
      case VehicleType.motorcycleWithGasRack:
        _drawMotorcycleWithGasRack(canvas, size, center, radius);
        break;
      case VehicleType.deliveryVan:
        _drawDeliveryVan(canvas, size, center, radius);
        break;
      case VehicleType.pickupTruck:
        _drawPickupTruck(canvas, size, center, radius);
        break;
    }
  }

  void _drawMotorcycleWithGasRack(
    Canvas canvas,
    Size size,
    Offset center,
    double radius,
  ) {
    // 1. Sombra projetada
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.28)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5.0);
    canvas.drawOval(
      Rect.fromCenter(
        center: center.translate(0, 3.5),
        width: size.width * 0.75,
        height: size.height * 0.85,
      ),
      shadowPaint,
    );

    // 2. Feixe de farol dianteiro suave
    final headlightPath = Path()
      ..moveTo(center.dx - 5, center.dy - radius * 0.65)
      ..lineTo(center.dx + 5, center.dy - radius * 0.65)
      ..lineTo(center.dx + 16, center.dy - radius * 0.98)
      ..lineTo(center.dx - 16, center.dy - radius * 0.98)
      ..close();

    final headlightPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.bottomCenter,
        end: Alignment.topCenter,
        colors: [
          Colors.white.withValues(alpha: 0.45),
          Colors.amber.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawPath(headlightPath, headlightPaint);

    // 3. Aura de movimento ativa (pulsante ciano/laranja quando em deslocamento)
    if (isMoving) {
      final auraPaint = Paint()
        ..color = AppColors.primary.withValues(alpha: 0.2)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5;
      canvas.drawCircle(center, radius * 0.9, auraPaint);
    }

    // 4. Rodas da moto (traseira e dianteira)
    final tirePaint = Paint()
      ..color = const Color(0xFF1E293B)
      ..style = PaintingStyle.fill;
    // Roda dianteira (topo)
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(center.dx, center.dy - radius * 0.55), width: 5.5, height: 11),
        const Radius.circular(2.5),
      ),
      tirePaint,
    );
    // Roda traseira (base)
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(center.dx, center.dy + radius * 0.55), width: 6.5, height: 12),
        const Radius.circular(3),
      ),
      tirePaint,
    );

    // 5. Chassi da moto
    final chassisPaint = Paint()
      ..color = const Color(0xFF0F172A)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: center, width: 9, height: radius * 1.3),
        const Radius.circular(4.5),
      ),
      chassisPaint,
    );

    // 6. Guidão e retrovisores
    final handlebarPaint = Paint()
      ..color = const Color(0xFF334155)
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    canvas.drawLine(
      Offset(center.dx - 13, center.dy - radius * 0.35),
      Offset(center.dx + 13, center.dy - radius * 0.35),
      handlebarPaint,
    );

    // 7. Suporte / Gaiola Traseira de Botijões de Gás BoraGás
    final rackPaint = Paint()
      ..color = const Color(0xFF334155)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(center.dx, center.dy + radius * 0.35), width: 28, height: 14),
        const Radius.circular(3),
      ),
      rackPaint,
    );

    // Botijão de gás lateral ESQUERDO (Azul / Ciano BoraGás com tampa dourada)
    _drawGasCylinder(canvas, Offset(center.dx - 8.5, center.dy + radius * 0.35));
    // Botijão de gás lateral DIREITO
    _drawGasCylinder(canvas, Offset(center.dx + 8.5, center.dy + radius * 0.35));

    // 8. Piloto BoraGás (Ombros e Capacete Laranja Neon)
    final riderPaint = Paint()
      ..color = const Color(0xFF1E293B)
      ..style = PaintingStyle.fill;
    canvas.drawOval(
      Rect.fromCenter(center: Offset(center.dx, center.dy - radius * 0.05), width: 18, height: 10),
      riderPaint,
    );

    // Capacete Laranja BoraGás
    final helmetPaint = Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(center.dx, center.dy - radius * 0.08), 6.5, helmetPaint);

    // Viseira do capacete (Preto reflexivo)
    final visorPaint = Paint()
      ..color = Colors.black87
      ..style = PaintingStyle.fill;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(center.dx, center.dy - radius * 0.14), width: 6.5, height: 2.5),
        const Radius.circular(1.5),
      ),
      visorPaint,
    );
  }

  /// Desenha um botijão de gás P13 estilizado com corpo azul e colarinho metálico
  void _drawGasCylinder(Canvas canvas, Offset position) {
    // Corpo do botijão (Ciano / Azul BoraGás)
    final cylinderPaint = Paint()
      ..color = const Color(0xFF0088CC)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(position, 5.0, cylinderPaint);

    // Borda de realce / luz
    final rimPaint = Paint()
      ..color = const Color(0xFF38BDF8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawCircle(position, 5.0, rimPaint);

    // Válvula / Colarinho de manuseio superior (prata/dourado)
    final valvePaint = Paint()
      ..color = const Color(0xFFF1F5F9)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(position, 2.0, valvePaint);
  }

  void _drawDeliveryVan(Canvas canvas, Size size, Offset center, double radius) {
    // Sombra
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: center.translate(0, 2), width: 22, height: 38),
        const Radius.circular(5),
      ),
      shadowPaint,
    );

    // Corpo da Van (Branco/Cinza com faixa BoraGás)
    final bodyPaint = Paint()..color = Colors.white;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: center, width: 20, height: 36),
        const Radius.circular(4),
      ),
      bodyPaint,
    );

    // Faixa Laranja BoraGás
    final stripePaint = Paint()..color = AppColors.primary;
    canvas.drawRect(
      Rect.fromCenter(center: center, width: 20, height: 6),
      stripePaint,
    );

    // Parabrisa dianteiro
    final glassPaint = Paint()..color = const Color(0xFF1E293B);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(center.dx, center.dy - 10), width: 16, height: 5),
        const Radius.circular(2),
      ),
      glassPaint,
    );
  }

  void _drawPickupTruck(Canvas canvas, Size size, Offset center, double radius) {
    // Carroceria e cabine
    final bodyPaint = Paint()..color = AppColors.primary;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: center, width: 22, height: 40),
        const Radius.circular(4),
      ),
      bodyPaint,
    );

    // Caçamba com botijões
    final bedPaint = Paint()..color = const Color(0xFF0F172A);
    canvas.drawRect(
      Rect.fromCenter(center: Offset(center.dx, center.dy + 8), width: 18, height: 16),
      bedPaint,
    );

    // 4 botijões na caçamba
    _drawGasCylinder(canvas, Offset(center.dx - 4, center.dy + 4));
    _drawGasCylinder(canvas, Offset(center.dx + 4, center.dy + 4));
    _drawGasCylinder(canvas, Offset(center.dx - 4, center.dy + 12));
    _drawGasCylinder(canvas, Offset(center.dx + 4, center.dy + 12));
  }

  @override
  bool shouldRepaint(covariant _VehicleCustomPainter oldDelegate) {
    return oldDelegate.vehicleType != vehicleType ||
        oldDelegate.isMoving != isMoving ||
        oldDelegate.speedKmh != speedKmh;
  }
}
