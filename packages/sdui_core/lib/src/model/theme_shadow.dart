import 'package:equatable/equatable.dart';

class ThemeShadow extends Equatable {
  const ThemeShadow({
    required this.color,
    required this.offsetX,
    required this.offsetY,
    required this.blur,
    required this.spread,
  });

  final String color;
  final double offsetX;
  final double offsetY;
  final double blur;
  final double spread;

  Map<String, dynamic> toJson() => {
    'color': color,
    'offsetX': offsetX,
    'offsetY': offsetY,
    'blur': blur,
    'spread': spread,
  };

  @override
  List<Object?> get props => [color, offsetX, offsetY, blur, spread];
}
