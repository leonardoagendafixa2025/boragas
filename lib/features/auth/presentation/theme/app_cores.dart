import 'package:flutter/material.dart';

class AppCores {
  // Cores de fundo (gradientes cósmicos)
  static const fundo = Color(0xFF130924);
  static const fundoEscuro = Color(0xFF0C0517);
  static const orbeRosa = Color(0xFFE84393);
  static const orbeMagenta = Color(0xFFD946EF);
  static const orbeAzul = Color(0xFF0984E3);
  static const orbeCiano = Color(0xFF38BDF8);

  // Cores da identidade visual
  static const roxo = Color(0xFF6C5CE7);
  static const roxoEscuro = Color(0xFF4834D4);
  static const roxoClaro = Color(0xFFA29BFE);
  static const rosa = Color(0xFFFD79A8);
  static const azul = Color(0xFF0984E3);
  static const laranja = Color(0xFFFF7675);
  static const chamaLaranja = Color(0xFFF97316);

  // Cores de texto e superfícies
  static const texto = Color(0xFF2D3436);
  static const textoClaro = Color(0xFFFFFFFF);
  static const textoSecundario = Color(0xFFC4B5FD);
  static const cinza = Color(0xFF636E72);
  static const cinzaClaro = Color(0xFFF1F2F6);
  static const campoFundo = Color(0xFFF6F5FB);
  static const campoBorda = Color(0xFFE5E2F4);
  static const branco = Colors.white;

  // Feedback
  static const vermelho = Color(0xFFD63031);
  static const verde = Color(0xFF00B894);
}

bool emailValido(String email) {
  final clean = email.trim();
  return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(clean);
}
