import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Colors
const emPrimaryColor = Color(0xFFFF6666); // Red color
const kStatusBarColor = Colors.white;
const kSystemNavigationBarColor = Colors.white;
const emNotchBackGroundColor = Color(0xFFFFF4EB);
const emInputBackgroundColor = Color(0xFFEEEEEE);

const textColor = Color.fromRGBO(255, 102, 102, 1.0); // Red color
const backgroundColor = Color(0xFFFAFAFA);
const kContentColorLightTheme = Color(0xFF1D1D35); // Dark color
const bottomNavigationColor = Color.fromRGBO(255, 111, 111, 1.0); // Red color
const greyChatColor = Color(0xFFEFF0F6);
const greyBackground = Color(0xFFF1F1F1);

ThemeData lightThemeData() {
  final ThemeData base = ThemeData.light();
  return base.copyWith(
    colorScheme: base.colorScheme.copyWith(
      primary: emPrimaryColor,
      surface: backgroundColor,
      onPrimary: textColor,
      secondary: greyBackground,
    ),
    appBarTheme: appBarTheme,
    scaffoldBackgroundColor: backgroundColor,
    iconTheme: const IconThemeData(color: kContentColorLightTheme),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: Colors.white,
      selectedItemColor: bottomNavigationColor, // Red color
      unselectedItemColor: kContentColorLightTheme.withOpacity(0.6), // Grey color
      selectedIconTheme: IconThemeData(color: bottomNavigationColor), // Red color
      unselectedIconTheme: IconThemeData(color: kContentColorLightTheme.withOpacity(0.6)), // Grey color
      showUnselectedLabels: true,
    ),
    textTheme: textTheme,
  );
}

final TextTheme textTheme = TextTheme(
  bodyLarge: GoogleFonts.poppins(
    fontSize: 18.0,
    color: const Color.fromARGB(255, 255, 255, 255),
    fontWeight: FontWeight.w500,
    wordSpacing: 0.2,
  ), // Previously bodyText1
  bodyMedium: GoogleFonts.poppins(
    fontSize: 15.0,
    color: Colors.black,
  ), // Previously bodyText2
  displayLarge: GoogleFonts.poppins(
    fontSize: 72.0,
    color: Colors.black,
    fontWeight: FontWeight.normal,
  ), // Previously headline1
  displayMedium: GoogleFonts.poppins(
    fontSize: 30.0,
    color: Colors.black,
    fontWeight: FontWeight.bold,
  ), // Previously headline2
  headlineSmall: const TextStyle(
    color: Colors.black,
    fontSize: 20.0,
    fontWeight: FontWeight.bold,
  ), // Previously headline5
  titleLarge: const TextStyle(
    fontSize: 20.0,
    color: textColor,
  ), // Previously headline6
);

const appBarTheme = AppBarTheme(centerTitle: false, elevation: 0);