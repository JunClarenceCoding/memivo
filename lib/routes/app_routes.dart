import 'package:flutter/material.dart';
import '../features/home/home_screen.dart';
import '../features/birthday/birthday_screen.dart';
import '../features/todo/todo_screen.dart';
import '../features/cafe/coffee_screen.dart';
import '../features/budget/budget_screen.dart';

class AppRoutes {
  static const home = '/';
  static const birthday = '/birthday';
  static const todo = '/todo';
  static const cafe = '/cafe';
  static const budget = '/budget';

  static Map<String, WidgetBuilder> get routes => {
    home: (_) => const HomeScreen(),
    birthday: (_) => const BirthdayScreen(),
    todo: (_) => const TodoScreen(),
    cafe: (_) => const CoffeeScreen(),
    budget: (_) => const  BudgetScreen(),
  };
}