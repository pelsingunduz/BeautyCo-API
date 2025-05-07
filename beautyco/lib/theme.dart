import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// Renk paleti
const Color primaryRed = Color(0xFF9B1B30);     // Zengin kırmızı
const Color lightRed = Color(0xFFFEEAED);       // Açık gül
const Color champagneGold = Color(0xFFFDF6E3);  // Krem şampanya
const Color darkRed = Color(0xFF6D1122);        // Koyu kırmızı
const Color roseGold = Color(0xFFE8C5C9);       // Roze altın

ThemeData beautyCoTheme = ThemeData(
  primaryColor: primaryRed,
  scaffoldBackgroundColor: champagneGold,
  fontFamily: GoogleFonts.montserrat().fontFamily,
  textTheme: GoogleFonts.montserratTextTheme(),
  appBarTheme: const AppBarTheme(
    backgroundColor: Colors.white,
    elevation: 0,
    iconTheme: IconThemeData(color: primaryRed),
    titleTextStyle: TextStyle(
      color: primaryRed,
      fontWeight: FontWeight.bold,
      fontSize: 22,
      fontFamily: 'Montserrat',
    ),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: primaryRed,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      textStyle: GoogleFonts.montserrat(
        fontWeight: FontWeight.w600,
        fontSize: 16,
      ),
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(15),
      borderSide: BorderSide(color: roseGold),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(15),
      borderSide: BorderSide(color: primaryRed, width: 2),
    ),
    filled: true,
    fillColor: Colors.white,
    hintStyle: GoogleFonts.poppins(color: Colors.grey[400]),
    labelStyle: GoogleFonts.poppins(color: primaryRed),
  ),
); 